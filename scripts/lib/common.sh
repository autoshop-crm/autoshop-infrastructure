#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

die() {
  log "ERROR: $*"
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Command not found: $1"
}

abspath() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s\n' "$ROOT_DIR/${path#./}"
  fi
}

load_root_env() {
  if [[ -f "$ROOT_DIR/.env" ]]; then
    while IFS='=' read -r key value; do
      [[ -n "$key" ]] || continue
      [[ "$key" =~ ^[[:space:]]*# ]] && continue
      [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
      if [[ -z "${!key+x}" ]]; then
        export "$key=${value%$'\r'}"
      fi
    done <"$ROOT_DIR/.env"
  fi
}

set_context() {
  local env="${1:-${ENVIRONMENT:-local}}"
  load_root_env

  export ENVIRONMENT="$env"
  export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-autoshop}"
  export AUTOSHOP_HOME="${AUTOSHOP_HOME:-/opt/autoshop}"
  export BACKUP_ROOT="${BACKUP_ROOT:-$ROOT_DIR/backups}"
  export POSTGRES_INIT_DIR="${POSTGRES_INIT_DIR:-$ROOT_DIR/postgres/init}"

  case "$env" in
    local)
      export ENV_DIR="${ENV_DIR:-$ROOT_DIR/env/local}"
      export DATA_ROOT="${DATA_ROOT:-$ROOT_DIR/data/local}"
      export NGINX_CONF="${NGINX_CONF:-$ROOT_DIR/nginx/local/autoshop.conf}"
      export NGINX_HTTP_PORT="${NGINX_HTTP_PORT:-8088}"
      ;;
    staging)
      export ENV_DIR="${ENV_DIR:-$AUTOSHOP_HOME/env/staging}"
      export DATA_ROOT="${DATA_ROOT:-$AUTOSHOP_HOME/data/staging}"
      export NGINX_CONF="${NGINX_CONF:-$ROOT_DIR/nginx/staging/autoshop.conf}"
      export BACKUP_ROOT="${BACKUP_ROOT:-$AUTOSHOP_HOME/backups}"
      export NGINX_HTTP_PORT="${NGINX_HTTP_PORT:-80}"
      ;;
    prod)
      export ENV_DIR="${ENV_DIR:-$AUTOSHOP_HOME/env/prod}"
      export DATA_ROOT="${DATA_ROOT:-$AUTOSHOP_HOME/data/prod}"
      export NGINX_CONF="${NGINX_CONF:-$ROOT_DIR/nginx/prod/autoshop.conf}"
      export BACKUP_ROOT="${BACKUP_ROOT:-$AUTOSHOP_HOME/backups}"
      export NGINX_HTTP_PORT="${NGINX_HTTP_PORT:-80}"
      ;;
    *)
      die "Unsupported environment: $env"
      ;;
  esac

  export ENV_DIR="$(abspath "$ENV_DIR")"
  export DATA_ROOT="$(abspath "$DATA_ROOT")"
  export BACKUP_ROOT="$(abspath "$BACKUP_ROOT")"
  export NGINX_CONF="$(abspath "$NGINX_CONF")"
  export POSTGRES_INIT_DIR="$(abspath "$POSTGRES_INIT_DIR")"

  export POSTGRES_IMAGE="${POSTGRES_IMAGE:-postgres:16-alpine}"
  export REDIS_IMAGE="${REDIS_IMAGE:-redis:7-alpine}"
  export KAFKA_IMAGE="${KAFKA_IMAGE:-apache/kafka:3.7.1}"
  export MINIO_IMAGE="${MINIO_IMAGE:-minio/minio:latest}"
  export MC_IMAGE="${MC_IMAGE:-minio/mc:latest}"
  export NGINX_IMAGE="${NGINX_IMAGE:-nginx:1.27-alpine}"
  export MAILHOG_IMAGE="${MAILHOG_IMAGE:-mailhog/mailhog:v1.0.1}"

  export CORE_IMAGE="${CORE_IMAGE:-ghcr.io/autoshop/autoshop-core}"
  export AUTH_IMAGE="${AUTH_IMAGE:-ghcr.io/autoshop/autoshop-auth}"
  export NOTIFICATION_IMAGE="${NOTIFICATION_IMAGE:-ghcr.io/autoshop/autoshop-notification}"
  export FILES_IMAGE="${FILES_IMAGE:-ghcr.io/autoshop/autoshop-files}"

  export CORE_IMAGE_TAG="${CORE_IMAGE_TAG:-latest}"
  export AUTH_IMAGE_TAG="${AUTH_IMAGE_TAG:-latest}"
  export NOTIFICATION_IMAGE_TAG="${NOTIFICATION_IMAGE_TAG:-latest}"
  export FILES_IMAGE_TAG="${FILES_IMAGE_TAG:-latest}"

  export POSTGRES_DEFAULT_DB="${POSTGRES_DEFAULT_DB:-postgres}"
  export POSTGRES_USER="${POSTGRES_USER:-autoshop}"
  export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-autoshop}"
  export MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}"
  export MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minioadmin123}"
  export KAFKA_EXTERNAL_PORT="${KAFKA_EXTERNAL_PORT:-29092}"
  export MINIO_API_PUBLIC_PORT="${MINIO_API_PUBLIC_PORT:-9000}"
  export MINIO_CONSOLE_PUBLIC_PORT="${MINIO_CONSOLE_PUBLIC_PORT:-9001}"
  export MAILHOG_SMTP_PORT="${MAILHOG_SMTP_PORT:-1025}"
  export MAILHOG_UI_PORT="${MAILHOG_UI_PORT:-8025}"
  export BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
  export LOCAL_BUILD_FROM_SOURCE="${LOCAL_BUILD_FROM_SOURCE:-true}"
  export SMOKE_RUN_FILES_CRUD="${SMOKE_RUN_FILES_CRUD:-true}"
}

compose_cmd() {
  local env="${1:-${ENVIRONMENT:-local}}"
  shift || true
  (
    cd "$ROOT_DIR"
    set_context "$env"
    docker compose \
      -f "$ROOT_DIR/compose/compose.base.yml" \
      -f "$ROOT_DIR/compose/compose.$env.yml" \
      "$@"
  )
}

require_env_files() {
  local env="${1:-${ENVIRONMENT:-local}}"
  set_context "$env"

  local file
  for file in infrastructure.env core.env auth.env notification.env files.env; do
    [[ -f "$ENV_DIR/$file" ]] || die "Missing env file: $ENV_DIR/$file"
  done
}

ensure_directory() {
  mkdir -p "$1"
}

timestamp() {
  date '+%Y%m%d-%H%M%S'
}

wait_for_http() {
  local url="$1"
  local label="$2"
  local retries="${3:-30}"
  local delay="${4:-2}"
  local attempt

  for attempt in $(seq 1 "$retries"); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      log "$label is reachable: $url"
      return 0
    fi
    sleep "$delay"
  done

  die "$label did not become reachable: $url"
}

docker_network_name() {
  set_context "${1:-${ENVIRONMENT:-local}}"
  printf '%s_autoshop' "$COMPOSE_PROJECT_NAME"
}
