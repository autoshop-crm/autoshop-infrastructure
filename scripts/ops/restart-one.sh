#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${ENVIRONMENT:-local}"
service="${1:-}"

if [[ "$service" =~ ^(local|staging|prod)$ ]]; then
  env="$service"
  service="${2:-}"
fi

[[ -n "$service" ]] || die "Usage: restart-one.sh [local|staging|prod] <service>"

set_context "$env"
compose_cmd "$env" restart "$service"
