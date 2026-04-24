#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

set_context prod
"$SCRIPT_DIR/../init/init-server.sh" prod
require_env_files prod

snapshot_dir="$ROOT_DIR/.deploy-history/prod"
ensure_directory "$snapshot_dir"

if [[ -f "$ROOT_DIR/.env" ]]; then
  cp "$ROOT_DIR/.env" "$snapshot_dir/pre-deploy-$(timestamp).env"
fi

compose_cmd prod config >/dev/null
"$SCRIPT_DIR/pull-images.sh" prod

if compose_cmd prod up -d --remove-orphans; then
  "$SCRIPT_DIR/../init/init-minio.sh" prod
  "$SCRIPT_DIR/../ops/healthcheck.sh" prod
  "$SCRIPT_DIR/../smoke/smoke-e2e.sh" prod
  if [[ -f "$ROOT_DIR/.env" ]]; then
    cp "$ROOT_DIR/.env" "$snapshot_dir/last-known-good.env"
  fi
  log "Production deploy completed successfully"
else
  log "Production deploy failed, attempting rollback"
  "$SCRIPT_DIR/../ops/rollback.sh" prod || true
  die "Production deploy failed"
fi
