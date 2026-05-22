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

response="$(curl -fsS \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$bootstrap_email\",\"password\":\"$bootstrap_password\"}" \
  "http://127.0.0.1:${NGINX_HTTP_PORT}/api/auth/login" || true)"

[[ "$response" == *"accessToken"* ]] || die "Bootstrap admin login failed"
log "Bootstrap admin login passed"
