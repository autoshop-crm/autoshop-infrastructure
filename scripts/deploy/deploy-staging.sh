#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

set_context staging
"$SCRIPT_DIR/../init/init-server.sh" staging
require_env_files staging

compose_cmd staging config >/dev/null
"$SCRIPT_DIR/pull-images.sh" staging
compose_cmd staging up -d --remove-orphans
"$SCRIPT_DIR/../init/init-minio.sh" staging
"$SCRIPT_DIR/../ops/healthcheck.sh" staging
"$SCRIPT_DIR/../smoke/smoke-e2e.sh" staging
