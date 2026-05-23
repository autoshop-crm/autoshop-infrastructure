#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

[[ "$(uname -s)" == "Darwin" ]] || die "update-macos supports macOS only"

export AUTOSHOP_HOME="${AUTOSHOP_HOME:-$ROOT_DIR/.runtime/macos}"
export ENV_DIR="${ENV_DIR:-$AUTOSHOP_HOME/env/staging}"
export DATA_ROOT="${DATA_ROOT:-$AUTOSHOP_HOME/data/staging}"
export BACKUP_ROOT="${BACKUP_ROOT:-$AUTOSHOP_HOME/backups}"
export NGINX_HTTP_PORT="${NGINX_HTTP_PORT:-8088}"
export DOCKER_DEFAULT_PLATFORM="${DOCKER_DEFAULT_PLATFORM:-linux/amd64}"

set_context staging

backup_before_update="${AUTOSHOP_UPDATE_BACKUP:-true}"
run_smoke_after_update="${AUTOSHOP_UPDATE_SMOKE:-true}"
pull_repo_before_update="${AUTOSHOP_UPDATE_GIT_PULL:-false}"

log "Starting AutoShop macOS update"

require_command git
require_command docker

if [[ ! -d "$AUTOSHOP_HOME" ]]; then
  die "Missing macOS runtime at $AUTOSHOP_HOME. Run make onboard-macos first."
fi

require_env_files staging
run_logged "$ROOT_DIR/scripts/ops/disk-preflight.sh" staging

case "$(printf '%s' "$pull_repo_before_update" | tr '[:upper:]' '[:lower:]')" in
  true|yes|y)
    if [[ -n "$(git status --short)" ]]; then
      die "Working tree has local changes. Commit/stash them before AUTOSHOP_UPDATE_GIT_PULL=true."
    fi
    log "Pulling latest infrastructure repo changes"
    git pull --ff-only
    ;;
  false|no|n)
    log "Skipping git pull; assuming repositories are already updated"
    ;;
  *)
    die "Unsupported AUTOSHOP_UPDATE_GIT_PULL value: $pull_repo_before_update"
    ;;
esac

case "$(printf '%s' "$backup_before_update" | tr '[:upper:]' '[:lower:]')" in
  true|yes|y)
    run_logged "$ROOT_DIR/scripts/backup/backup-postgres.sh" staging
    run_logged "$ROOT_DIR/scripts/backup/backup-minio.sh" staging
    ;;
  false|no|n)
    log "Skipping backups by configuration"
    ;;
  *)
    die "Unsupported AUTOSHOP_UPDATE_BACKUP value: $backup_before_update"
    ;;
esac

run_logged "$ROOT_DIR/scripts/init/init-directories.sh" staging
run_logged "$ROOT_DIR/scripts/deploy/pull-images.sh" staging

log "Recreating services without deleting data volumes"
compose_cmd staging up -d --remove-orphans

run_logged "$ROOT_DIR/scripts/init/init-minio.sh" staging
run_logged "$ROOT_DIR/scripts/ops/healthcheck.sh" staging

case "$(printf '%s' "$run_smoke_after_update" | tr '[:upper:]' '[:lower:]')" in
  true|yes|y)
    run_logged "$ROOT_DIR/scripts/smoke/smoke-e2e.sh" staging
    ;;
  false|no|n)
    log "Skipping smoke tests by configuration"
    ;;
  *)
    die "Unsupported AUTOSHOP_UPDATE_SMOKE value: $run_smoke_after_update"
    ;;
esac

log "macOS update completed successfully"
log "Gateway: http://127.0.0.1:${NGINX_HTTP_PORT}"
