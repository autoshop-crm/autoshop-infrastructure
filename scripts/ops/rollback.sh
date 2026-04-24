#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-prod}"
set_context "$env"

snapshot="$ROOT_DIR/.deploy-history/$env/last-known-good.env"
[[ -f "$snapshot" ]] || die "Rollback snapshot not found: $snapshot"

set -a
# shellcheck disable=SC1090
source "$snapshot"
set +a

set_context "$env"
require_env_files "$env"

compose_cmd "$env" pull
compose_cmd "$env" up -d --remove-orphans
log "Rollback completed using $snapshot"
