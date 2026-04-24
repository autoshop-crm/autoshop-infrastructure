#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"
require_command curl

curl -fsS "http://127.0.0.1:${NGINX_HTTP_PORT}/internal/core/actuator/health" >/dev/null
log "Core smoke passed"
