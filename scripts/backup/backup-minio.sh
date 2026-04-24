#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"

backup_dir="$BACKUP_ROOT/minio/$env"
ensure_directory "$backup_dir"

archive="$backup_dir/minio-$(timestamp).tar.gz"
tar -czf "$archive" -C "$DATA_ROOT" minio

find "$backup_dir" -type f -mtime "+$BACKUP_RETENTION_DAYS" -delete
log "MinIO backup created: $archive"
