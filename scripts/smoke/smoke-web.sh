#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"
require_command curl

check_web() {
  local url="$1"
  local label="$2"
  html="$(curl -fsS "$url" || true)"
  [[ "$html" == *"<html"* || "$html" == *"<!doctype html"* ]] || die "$label did not return HTML: $url"
  log "$label is reachable"
}

check_web "http://127.0.0.1:${WEB_SPEC_PUBLIC_PORT}/" "CRM web"
check_web "http://127.0.0.1:${CLIENT_WEB_PUBLIC_PORT}/" "Client web"
