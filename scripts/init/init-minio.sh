#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"
require_env_files "$env"

require_command docker

compose_cmd "$env" up -d minio

infra_env="$ENV_DIR/infrastructure.env"
if [[ -f "$infra_env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$infra_env"
  set +a
fi

buckets="${MINIO_BUCKETS:-autoshop-files}"
network="$(docker_network_name "$env")"

docker run --rm --network "$network" --entrypoint /bin/sh \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  -e MINIO_BUCKETS="$buckets" \
  "$MC_IMAGE" -ceu '
    until mc alias set autoshop http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; do
      sleep 2
    done
    buckets=$(printf "%s" "$MINIO_BUCKETS" | tr -d "[:space:]")
    old_ifs="$IFS"
    IFS=,
    set -- $buckets
    IFS="$old_ifs"
    for bucket in "$@"; do
      [ -n "$bucket" ] || continue
      if mc ls "autoshop/$bucket" >/dev/null 2>&1; then
        continue
      fi
      mc mb "autoshop/$bucket" >/dev/null 2>&1 || mc ls "autoshop/$bucket" >/dev/null 2>&1
    done
  '

log "MinIO buckets initialized: $buckets"
