#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
shift || true
set_context "$env"

if [[ "$#" -eq 0 ]]; then
  compose_cmd "$env" restart
else
  compose_cmd "$env" restart "$@"
fi
