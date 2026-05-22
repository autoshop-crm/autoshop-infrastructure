#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

require_linux

command -v docker >/dev/null 2>&1 || die "Docker is not installed"
docker compose version >/dev/null 2>&1 || die "Docker Compose plugin is not installed"

if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    sudo systemctl start docker >/dev/null 2>&1 || true
  fi
fi

docker info >/dev/null 2>&1 || die "Docker daemon is not reachable. Start Docker or re-login after group changes"
log "Docker is ready"
