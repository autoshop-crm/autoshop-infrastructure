#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"

backup_dir="$BACKUP_ROOT/postgres/$env"
ensure_directory "$backup_dir"

stamp="$(timestamp)"

for db in core_db auth_db notifications_db files_db; do
  out="$backup_dir/${db}-${stamp}.sql"
  log "Backing up database $db to $out"
  compose_cmd "$env" exec -T postgres sh -c \
    "PGPASSWORD=\"\$POSTGRES_PASSWORD\" pg_dump -U \"\$POSTGRES_USER\" -d \"$db\"" >"$out"
done

find "$backup_dir" -type f -mtime "+$BACKUP_RETENTION_DAYS" -delete
log "PostgreSQL backups completed for $env"
