#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-staging}}"
set_context "$env"

require_command df

target_dir="${AUTOSHOP_HOME}"
if [[ "$env" == "local" ]]; then
  target_dir="$ROOT_DIR"
fi

available_kb="$(df -Pk "$target_dir" | awk 'NR==2 {print $4}')"
available_gb="$((available_kb / 1024 / 1024))"
recommended_gb="${DISK_REQUIRED_GB:-12}"

log "Disk preflight for ${env}: ${available_gb} GiB available at ${target_dir}"

if (( available_gb < recommended_gb )); then
  die "Insufficient disk space for ${env}: ${available_gb} GiB available, ${recommended_gb} GiB recommended"
fi
