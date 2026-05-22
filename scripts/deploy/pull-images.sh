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
attempt=1

while (( attempt <= pull_retries )); do
  if compose_cmd "$env" pull; then
    log "Images pulled successfully on attempt ${attempt}/${pull_retries}"
    exit 0
  fi

  if (( attempt == pull_retries )); then
    die "Image pull failed after ${pull_retries} attempts"
  fi

  log "Image pull failed on attempt ${attempt}/${pull_retries}; retrying in ${pull_delay_seconds}s"
  sleep "$pull_delay_seconds"
  attempt=$((attempt + 1))
done
