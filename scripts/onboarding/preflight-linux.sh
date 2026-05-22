#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

require_linux
set_context local

log "Detected Linux distribution: ${PRETTY_NAME}"
require_command bash
require_command grep
require_command sed

if ! command -v sudo >/dev/null 2>&1; then
  log "sudo not found; Docker auto-install may be unavailable"
fi

if ! command -v git >/dev/null 2>&1; then
  log "git not found"
fi

if [[ -n "$(repo_origin_url)" ]]; then
  log "Derived repository base URL: $(repo_base_url)"
else
  log "Git origin is missing; set AUTOSHOP_REPO_BASE_URL manually if needed"
fi

workspace_root="$(repo_root_dir)"
[[ -w "$workspace_root" ]] || die "Workspace root is not writable: $workspace_root"

log "Preflight checks completed"
