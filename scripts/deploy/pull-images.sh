#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"
require_env_files "$env"

pull_retries="${PULL_RETRIES:-5}"
pull_delay_seconds="${PULL_RETRY_DELAY_SECONDS:-8}"

pull_one_image() {
  local image="$1"
  local attempt=1

  while (( attempt <= pull_retries )); do
    if docker pull "$image"; then
      log "Pulled ${image} on attempt ${attempt}/${pull_retries}"
      return 0
    fi

    if (( attempt == pull_retries )); then
      die "Failed to pull ${image} after ${pull_retries} attempts"
    fi

    log "Pull failed for ${image} on attempt ${attempt}/${pull_retries}; retrying in ${pull_delay_seconds}s"
    sleep "$pull_delay_seconds"
    attempt=$((attempt + 1))
  done
}

images=(
  "${POSTGRES_IMAGE}"
  "${REDIS_IMAGE}"
  "${KAFKA_IMAGE}"
  "${MINIO_IMAGE}"
  "${MC_IMAGE}"
  "${NGINX_IMAGE}"
  "${AUTH_IMAGE}:${AUTH_IMAGE_TAG}"
  "${CORE_IMAGE}:${CORE_IMAGE_TAG}"
  "${NOTIFICATION_IMAGE}:${NOTIFICATION_IMAGE_TAG}"
  "${FILES_IMAGE}:${FILES_IMAGE_TAG}"
)

if [[ "$env" != "local" || "${LOCAL_USE_GHCR_IMAGES}" == "true" ]]; then
  images+=(
    "${WEB_SPEC_IMAGE}:${WEB_SPEC_IMAGE_TAG}"
    "${CLIENT_WEB_IMAGE}:${CLIENT_WEB_IMAGE_TAG}"
  )
fi

if [[ "$env" != "prod" ]]; then
  images+=("${MAILHOG_IMAGE}")
fi

for image in "${images[@]}"; do
  pull_one_image "$image"
done

log "All images pulled successfully"
