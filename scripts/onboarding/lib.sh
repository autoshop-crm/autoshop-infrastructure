#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

ONBOARDING_LOG_FILE="${ONBOARDING_LOG_FILE:-$ROOT_DIR/.deploy-history/local/onboarding-$(date '+%Y%m%d-%H%M%S').log}"

is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

load_os_release() {
  [[ -f /etc/os-release ]] || die "Missing /etc/os-release; unsupported Linux distribution"
  # shellcheck disable=SC1091
  source /etc/os-release
  export ID="${ID:-unknown}"
  export VERSION_ID="${VERSION_ID:-unknown}"
  export PRETTY_NAME="${PRETTY_NAME:-$ID}"
}

require_linux() {
  is_linux || die "Linux onboarding supports Linux only"
  load_os_release
}

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "macOS onboarding supports macOS only"
}

linux_family() {
  load_os_release
  case "$ID" in
    ubuntu|debian|linuxmint|pop) printf 'debian\n' ;;
    fedora) printf 'fedora\n' ;;
    arch) printf 'arch\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

repo_root_dir() {
  dirname "$ROOT_DIR"
}

repo_origin_url() {
  git -C "$ROOT_DIR" remote get-url origin 2>/dev/null || true
}

repo_base_url() {
  local origin
  origin="${AUTOSHOP_REPO_BASE_URL:-}"
  if [[ -n "$origin" ]]; then
    printf '%s\n' "${origin%/}"
    return 0
  fi

  origin="$(repo_origin_url)"
  [[ -n "$origin" ]] || die "Cannot infer git base URL from current repo. Set AUTOSHOP_REPO_BASE_URL in .env"

  origin="${origin%.git}"
  origin="${origin%/autoshop-infrastructure}"
  printf '%s\n' "$origin"
}

repo_clone_url() {
  local repo="$1"
  printf '%s/%s.git\n' "$(repo_base_url)" "$repo"
}

repo_target_dir() {
  local repo="$1"
  printf '%s/%s\n' "$(repo_root_dir)" "$repo"
}

manifest_repos() {
  grep -E '^[A-Za-z0-9._-]+$' "$SCRIPT_DIR/repos.manifest"
}

run_logged() {
  log "$*"
  "$@"
}

ensure_onboarding_log_dir() {
  mkdir -p "$(dirname "$ONBOARDING_LOG_FILE")"
}

print_onboarding_summary() {
  local auth_env_file bootstrap_email bootstrap_password
  auth_env_file="$ENV_DIR/auth.env"
  bootstrap_email="admin@autoshop.local"
  bootstrap_password="Admin123!"
  if [[ -f "$auth_env_file" ]]; then
    bootstrap_email="$(grep -E '^BOOTSTRAP_EMAIL=' "$auth_env_file" | cut -d= -f2- || true)"
    bootstrap_password="$(grep -E '^BOOTSTRAP_PASSWORD=' "$auth_env_file" | cut -d= -f2- || true)"
    bootstrap_email="${bootstrap_email:-admin@autoshop.local}"
    bootstrap_password="${bootstrap_password:-Admin123!}"
  fi

  cat <<EOF

Onboarding summary
- Gateway: http://localhost:${NGINX_HTTP_PORT:-8088}
- CRM web: http://localhost:${WEB_SPEC_PUBLIC_PORT:-5173}
- Client web: http://localhost:${CLIENT_WEB_PUBLIC_PORT:-5174}
- Admin email: ${bootstrap_email}
- Admin password: ${bootstrap_password}
- Log file: ${ONBOARDING_LOG_FILE}
EOF
}

print_server_onboarding_summary() {
  local access_point="$1"
  local auth_env_file bootstrap_email bootstrap_password
  auth_env_file="$ENV_DIR/auth.env"
  bootstrap_email="admin@autoshop.local"
  bootstrap_password="Admin123!"
  if [[ -f "$auth_env_file" ]]; then
    bootstrap_email="$(grep -E '^BOOTSTRAP_EMAIL=' "$auth_env_file" | cut -d= -f2- || true)"
    bootstrap_password="$(grep -E '^BOOTSTRAP_PASSWORD=' "$auth_env_file" | cut -d= -f2- || true)"
    bootstrap_email="${bootstrap_email:-admin@autoshop.local}"
    bootstrap_password="${bootstrap_password:-Admin123!}"
  fi

  cat <<EOF

Server onboarding summary
- Gateway: http://${access_point}:${NGINX_HTTP_PORT:-80}
- CRM web: http://${access_point}:${WEB_SPEC_PUBLIC_PORT:-5173}
- Client web: http://${access_point}:${CLIENT_WEB_PUBLIC_PORT:-5174}
- Admin email: ${bootstrap_email}
- Admin password: ${bootstrap_password}
- Environment: ${ENVIRONMENT}
- Log file: ${ONBOARDING_LOG_FILE}
EOF
}

prompt_value() {
  local label="$1"
  local default_value="${2:-}"
  local input

  if [[ -n "$default_value" ]]; then
    read -r -p "$label [$default_value]: " input
    printf '%s\n' "${input:-$default_value}"
  else
    read -r -p "$label: " input
    printf '%s\n' "$input"
  fi
}

prompt_secret() {
  local label="$1"
  local input

  read -r -s -p "$label: " input
  printf '\n' >&2
  printf '%s\n' "$input"
}

write_env_value() {
  local file="$1"
  local key="$2"
  local value="$3"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if grep -qE "^${key}=" "$file"; then
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$file"
    rm -f "${file}.bak"
  else
    printf '%s=%s\n' "$key" "$value" >>"$file"
  fi
}

random_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 24
    return 0
  fi

  date +%s | sha256sum | cut -d' ' -f1
}

read_env_value() {
  local file="$1"
  local key="$2"

  [[ -f "$file" ]] || return 0

  grep -E "^${key}=" "$file" | head -n 1 | cut -d= -f2- | sed 's/^"//; s/"$//' || true
}

is_placeholder_secret() {
  local value="${1:-}"
  [[ -z "$value" ]] && return 0
  [[ "$value" == "change-me" ]] && return 0
  [[ "$value" == change-me-* ]] && return 0
  [[ "$value" == *-change-me-* ]] && return 0
  return 1
}

prefer_non_placeholder() {
  local value
  for value in "$@"; do
    if ! is_placeholder_secret "$value"; then
      printf '%s\n' "$value"
      return 0
    fi
  done
  printf '\n'
}
