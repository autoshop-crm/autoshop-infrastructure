#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-prod}"

require_command docker
docker compose version >/dev/null 2>&1 || die "docker compose is required"

"$SCRIPT_DIR/init-env.sh" "$env"
"$SCRIPT_DIR/init-directories.sh" "$env"

set_context "$env"
require_env_files "$env"

[[ -f "$NGINX_CONF" ]] || die "Missing Nginx config: $NGINX_CONF"
[[ -d "$POSTGRES_INIT_DIR" ]] || die "Missing postgres init dir: $POSTGRES_INIT_DIR"

log "Server prerequisites look good for $env"
