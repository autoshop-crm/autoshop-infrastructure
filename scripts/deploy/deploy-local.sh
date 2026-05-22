#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

set_context local
"$SCRIPT_DIR/../init/init-env.sh" local
"$SCRIPT_DIR/../init/init-directories.sh" local
require_env_files local
require_web_source_dirs local

if [[ "$LOCAL_USE_GHCR_IMAGES" != "true" && "$LOCAL_BUILD_FROM_SOURCE" == "true" ]]; then
  "$SCRIPT_DIR/build-local-images.sh"
fi

compose_cmd local config >/dev/null
compose_cmd local up -d --remove-orphans
minio_init_marker="$DATA_ROOT/.minio-buckets-initialized"
if [[ ! -f "$minio_init_marker" ]]; then
  "$SCRIPT_DIR/../init/init-minio.sh" local
  touch "$minio_init_marker"
fi
"$SCRIPT_DIR/../ops/healthcheck.sh" local
"$SCRIPT_DIR/../smoke/smoke-e2e.sh" local
