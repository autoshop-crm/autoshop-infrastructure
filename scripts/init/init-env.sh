#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-local}"
set_context "$env"

if [[ ! -f "$ROOT_DIR/.env" ]]; then
  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  log "Created $ROOT_DIR/.env from template"
fi

if [[ "$env" == "local" ]]; then
  log "Local env files are versioned in $ENV_DIR"
  exit 0
fi

ensure_directory "$ENV_DIR"

for name in infrastructure core auth notification files; do
  target="$ENV_DIR/$name.env"
  example="$ROOT_DIR/env/$env/$name.env.example"
  if [[ ! -f "$target" ]]; then
    cp "$example" "$target"
    log "Created $target from example"
  fi
done
