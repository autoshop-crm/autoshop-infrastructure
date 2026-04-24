#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${ENVIRONMENT:-local}"
service=""

if [[ "${1:-}" =~ ^(local|staging|prod)$ ]]; then
  env="$1"
  shift || true
fi

if [[ $# -gt 0 ]]; then
  service="$1"
fi

set_context "$env"

if [[ -n "$service" ]]; then
  compose_cmd "$env" logs -f "$service"
else
  compose_cmd "$env" logs -f
fi
