#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$SCRIPT_DIR/smoke-auth.sh" "${1:-${ENVIRONMENT:-local}}"
"$SCRIPT_DIR/smoke-core.sh" "${1:-${ENVIRONMENT:-local}}"
"$SCRIPT_DIR/smoke-notification.sh" "${1:-${ENVIRONMENT:-local}}"
"$SCRIPT_DIR/smoke-files.sh" "${1:-${ENVIRONMENT:-local}}"
"$SCRIPT_DIR/smoke-admin-login.sh" "${1:-${ENVIRONMENT:-local}}"
"$SCRIPT_DIR/smoke-web.sh" "${1:-${ENVIRONMENT:-local}}"
