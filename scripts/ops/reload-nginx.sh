#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-staging}"
set_context "$env"

log "Recreating nginx for ${env}"
compose_cmd "$env" up -d --force-recreate nginx

log "Verifying demo routes in nginx config"
compose_cmd "$env" exec -T nginx sh -c "grep -n 'AutoShop Demo\\|location /client/\\|location /crm/' /etc/nginx/conf.d/default.conf"

log "Probing public demo entrypoint on http://127.0.0.1:${NGINX_HTTP_PORT}"
curl -fsS "http://127.0.0.1:${NGINX_HTTP_PORT}/health/nginx" >/dev/null
curl -fsS "http://127.0.0.1:${NGINX_HTTP_PORT}/" | grep -q 'AutoShop Demo'

log "Unified demo entrypoint is active"
