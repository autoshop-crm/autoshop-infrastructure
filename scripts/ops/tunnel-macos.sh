#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-staging}"
set_context "$env"

public_url="${AUTOSHOP_TUNNEL_URL:-http://127.0.0.1:${NGINX_HTTP_PORT}}"

log "Checking demo entrypoint on ${public_url}"
curl -fsS "${public_url}/health/nginx" >/dev/null || die "Nginx is not reachable on ${public_url}"
curl -fsS "${public_url}/" | grep -q 'AutoShop Demo' || die "Unified demo entrypoint is not active on ${public_url}"

log "Demo tunnel target is ready: ${public_url}"
log "Routes: / -> selector, /client/ -> client UI, /crm/ -> CRM UI"

if command -v cloudflared >/dev/null 2>&1; then
  log "Starting Cloudflare quick tunnel"
  exec cloudflared tunnel --url "${public_url}"
fi

if command -v ngrok >/dev/null 2>&1; then
  log "Starting ngrok tunnel"
  exec ngrok http "${public_url}"
fi

cat <<EOF
[ERROR] No supported tunnel client found.

Install one of these and run again:
  brew install cloudflared
  brew install --cask ngrok

Then start the tunnel with:
  make tunnel-macos
EOF

exit 1
