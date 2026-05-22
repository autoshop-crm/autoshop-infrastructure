#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

ensure_onboarding_log_dir
exec > >(tee -a "$ONBOARDING_LOG_FILE") 2>&1

trap 'log "Onboarding failed on line $LINENO"; exit 1' ERR

clone_mode="${CLONE_MODE:-clone-if-missing}"
skip_docker_install="${SKIP_DOCKER_INSTALL:-false}"

require_linux
set_context local

log "Starting AutoShop local onboarding"
"$SCRIPT_DIR/preflight-linux.sh"
"$SCRIPT_DIR/install-deps-linux.sh"

if [[ "$skip_docker_install" != "true" ]]; then
  "$SCRIPT_DIR/install-docker-linux.sh"
fi

"$SCRIPT_DIR/check-docker.sh"
"$SCRIPT_DIR/clone-repos.sh" "$clone_mode"

if [[ ! -f "$ROOT_DIR/.env" ]]; then
  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  log "Created root .env from template"
fi

require_web_source_dirs local

run_logged "$ROOT_DIR/scripts/init/init-env.sh" local
run_logged "$ROOT_DIR/scripts/init/init-directories.sh" local
run_logged "$ROOT_DIR/scripts/deploy/deploy-local.sh"
run_logged "$ROOT_DIR/scripts/smoke/smoke-admin-login.sh" local
run_logged "$ROOT_DIR/scripts/smoke/smoke-web.sh" local

print_onboarding_summary
