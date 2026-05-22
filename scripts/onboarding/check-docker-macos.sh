#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

require_macos

command -v docker >/dev/null 2>&1 || die "Docker is not installed. Install Docker Desktop or Colima first"
docker compose version >/dev/null 2>&1 || die "Docker Compose plugin is not installed"
docker info >/dev/null 2>&1 || die "Docker daemon is not reachable. Start Docker Desktop or Colima"

log "Docker is ready"
