#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"
require_command curl

base_url="http://127.0.0.1:${NGINX_HTTP_PORT}"
email="smoke+$(date +%s)@autoshop.local"
password="SmokePass123!"

register_status="$(curl -s -o /dev/null -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$email\",\"password\":\"$password\",\"firstName\":\"Smoke\",\"lastName\":\"User\"}" \
  "$base_url/api/auth/register")"

case "$register_status" in
  200|201|409)
    log "Auth register endpoint is reachable (status $register_status)"
    ;;
  *)
    die "Auth register smoke failed with status $register_status"
    ;;
esac

login_response="$(curl -fsS \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$email\",\"password\":\"$password\"}" \
  "$base_url/api/auth/login" || true)"

if [[ "$register_status" == "409" ]]; then
  log "Auth user already exists, skipping login assertion"
  exit 0
fi

[[ "$login_response" == *"accessToken"* ]] || die "Auth login smoke failed"
log "Auth smoke passed"
