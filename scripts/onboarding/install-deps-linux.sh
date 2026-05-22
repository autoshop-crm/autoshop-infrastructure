#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

require_linux

family="$(linux_family)"
missing=()
for cmd in git curl make; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if [[ "${#missing[@]}" -eq 0 ]]; then
  log "Base CLI dependencies are already installed"
  exit 0
fi

command -v sudo >/dev/null 2>&1 || die "Missing commands: ${missing[*]}. Install them manually or provide sudo"

case "$family" in
  debian)
    sudo apt-get update
    sudo apt-get install -y git curl make ca-certificates gnupg
    ;;
  fedora)
    sudo dnf install -y git curl make ca-certificates gnupg2
    ;;
  arch)
    sudo pacman -Sy --noconfirm git curl make ca-certificates gnupg
    ;;
  *)
    die "Unsupported Linux family for auto-install: $ID"
    ;;
esac

log "Base CLI dependencies installed"
