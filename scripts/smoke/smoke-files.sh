#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"
require_command curl

base_url="http://127.0.0.1:${NGINX_HTTP_PORT}"
curl -fsS "$base_url/internal/files/actuator/health" >/dev/null

if [[ "$SMOKE_RUN_FILES_CRUD" != "true" ]]; then
  log "Files CRUD smoke skipped by configuration"
  exit 0
fi

tmp_file="$(mktemp)"
printf 'autoshop smoke test\n' >"$tmp_file"

response="$(
  curl -fsS \
    -F category=ORDER_DOCUMENT \
    -F ownerType=ORDER \
    -F ownerId=smoke-order \
    -F uploadedBy=infra-smoke \
    -F "file=@$tmp_file;type=text/plain" \
    "$base_url/api/files"
)"

rm -f "$tmp_file"

file_id="$(printf '%s' "$response" | grep -oE '"fileId":"[^"]+"' | cut -d: -f2 | tr -d '"')"
[[ -n "$file_id" ]] || die "Files upload smoke failed: fileId not found"

curl -fsS "$base_url/api/files/$file_id" >/dev/null
curl -fsS "$base_url/api/files/$file_id/download" >/dev/null
curl -fsS -X DELETE "$base_url/api/files/$file_id" >/dev/null

log "Files smoke passed"
