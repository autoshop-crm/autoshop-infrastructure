#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-staging}"
mode="${2:-soft}"
set_context "$env"

[[ "$env" != "local" ]] || die "Use existing local cleanup flow for local environment"

case "$mode" in
  soft|hard)
    ;;
  *)
    die "Unsupported cleanup mode: $mode"
    ;;
esac

log "Stopping ${env} stack"
compose_cmd "$env" down -v --remove-orphans || true

log "Removing ${env} data at ${DATA_ROOT}"
rm -rf "$DATA_ROOT"

log "Removing ${env} backups at ${BACKUP_ROOT}/${env}"
rm -rf "${BACKUP_ROOT}/${env}"

if [[ "$mode" == "hard" ]]; then
  log "Pruning Docker images, cache, containers, and volumes"
  docker system prune -a -f --volumes
fi

log "Cleanup completed for ${env} (${mode})"
