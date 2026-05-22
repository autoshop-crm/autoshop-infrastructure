#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

require_macos

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  log "Docker and Docker Compose are already installed"
  exit 0
fi

if command -v brew >/dev/null 2>&1; then
  log "Install Docker Desktop manually or use Colima. Optional helpers:"
  log "- Docker Desktop: brew install --cask docker"
  log "- Colima stack: brew install docker docker-compose colima"
else
  log "Install Docker Desktop manually or install Homebrew and use Colima"
fi

die "Docker is required before continuing with macOS onboarding"
