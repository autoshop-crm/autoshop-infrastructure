#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

set_context local

declare -A services=(
  [core]="../autoshop-core"
  [auth]="../autoshop-auth"
  [notification]="../autoshop-notification"
  [files]="../autoshop-files"
)

for service in "${!services[@]}"; do
  repo_path="$ROOT_DIR/${services[$service]}"
  [[ -d "$repo_path" ]] || die "Missing source repo for $service: $repo_path"

  case "$service" in
    core) image="${CORE_IMAGE}:${CORE_IMAGE_TAG}" ;;
    auth) image="${AUTH_IMAGE}:${AUTH_IMAGE_TAG}" ;;
    notification) image="${NOTIFICATION_IMAGE}:${NOTIFICATION_IMAGE_TAG}" ;;
    files) image="${FILES_IMAGE}:${FILES_IMAGE_TAG}" ;;
  esac

  log "Building local image for $service from $repo_path"
  docker build -t "$image" -f "$ROOT_DIR/docker/java-service.Dockerfile" "$repo_path"
done
