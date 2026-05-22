#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

require_macos

missing=()
for cmd in git curl make; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if [[ "${#missing[@]}" -eq 0 ]]; then
  log "Base CLI dependencies are already installed"
  exit 0
fi

command -v brew >/dev/null 2>&1 || die "Missing commands: ${missing[*]}. Install Homebrew or install them manually"

brew install "${missing[@]}"
log "Base CLI dependencies installed"
