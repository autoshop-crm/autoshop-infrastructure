#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
dump_file="${2:-}"
db_name="${3:-}"

[[ -n "$dump_file" && -n "$db_name" ]] || die "Usage: restore-postgres.sh <env> <dump_file> <db_name>"
[[ -f "$dump_file" ]] || die "Dump file not found: $dump_file"

set_context "$env"

compose_cmd "$env" exec -T postgres sh -c \
  "PGPASSWORD=\"\$POSTGRES_PASSWORD\" psql -U \"\$POSTGRES_USER\" -d \"$db_name\"" <"$dump_file"

log "Database $db_name restored from $dump_file"
