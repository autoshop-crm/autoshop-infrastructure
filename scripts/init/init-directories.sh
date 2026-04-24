#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-local}"
set_context "$env"

ensure_directory "$DATA_ROOT/postgres"
ensure_directory "$DATA_ROOT/redis"
ensure_directory "$DATA_ROOT/kafka"
ensure_directory "$DATA_ROOT/minio"
ensure_directory "$BACKUP_ROOT"
ensure_directory "$ROOT_DIR/.deploy-history/$env"

if [[ "$env" != "local" ]]; then
  ensure_directory "$AUTOSHOP_HOME"
  ensure_directory "$AUTOSHOP_HOME/env/$env"
  ensure_directory "$AUTOSHOP_HOME/data/$env"
  ensure_directory "$AUTOSHOP_HOME/backups"
fi

log "Directories are ready for environment: $env"
