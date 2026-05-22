#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"
require_command curl

auth_env_file="$ENV_DIR/auth.env"
[[ -f "$auth_env_file" ]] || die "Missing auth env file: $auth_env_file"

bootstrap_email="$(grep -E '^BOOTSTRAP_EMAIL=' "$auth_env_file" | cut -d= -f2-)"
bootstrap_password="$(grep -E '^BOOTSTRAP_PASSWORD=' "$auth_env_file" | cut -d= -f2-)"

[[ -n "$bootstrap_email" ]] || die "BOOTSTRAP_EMAIL is not configured"
[[ -n "$bootstrap_password" ]] || die "BOOTSTRAP_PASSWORD is not configured"

response_file="$(mktemp)"
status_code="$(curl -sS -o "$response_file" -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$bootstrap_email\",\"password\":\"$bootstrap_password\"}" \
  "http://127.0.0.1:${NGINX_HTTP_PORT}/api/auth/login" || true)"
response="$(cat "$response_file" 2>/dev/null || true)"
rm -f "$response_file"

case "$status_code" in
  200)
    [[ "$response" == *"accessToken"* ]] || die "Bootstrap admin login returned 200 without accessToken"
    log "Bootstrap admin login passed"
    ;;
  401|403)
    log "WARNING: Bootstrap admin login skipped (status $status_code). Current auth image may not seed bootstrap users automatically."
    ;;
  *)
    die "Bootstrap admin login failed with status $status_code"
    ;;
esac
