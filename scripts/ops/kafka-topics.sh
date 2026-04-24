#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"

compose_cmd "$env" exec -T kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 "${@:2}"
