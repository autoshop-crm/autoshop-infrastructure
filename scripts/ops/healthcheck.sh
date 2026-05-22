#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"

require_command curl

compose_cmd "$env" ps >/dev/null

check_http() {
  local url="$1"
  local label="$2"
  local retries="${3:-30}"
  local delay="${4:-2}"
  wait_for_http "$url" "$label" "$retries" "$delay"
  log "$label is healthy"
}

check_compose_exec() {
  local service="$1"
  shift
  compose_cmd "$env" exec -T "$service" "$@" >/dev/null
  log "$service internal check passed"
}

check_http "http://127.0.0.1:${NGINX_HTTP_PORT}/health/nginx" "nginx" 15 2
check_http "http://127.0.0.1:${NGINX_HTTP_PORT}/internal/core/actuator/health" "core" 45 2
check_http "http://127.0.0.1:${NGINX_HTTP_PORT}/internal/files/actuator/health" "files" 30 2
check_http "http://127.0.0.1:${NGINX_HTTP_PORT}/internal/notification/actuator/health" "notification" 30 2
check_http "http://127.0.0.1:${WEB_SPEC_PUBLIC_PORT}/health/nginx" "crm-web nginx" 20 2
check_http "http://127.0.0.1:${CLIENT_WEB_PUBLIC_PORT}/health/nginx" "client-web nginx" 20 2

auth_status="$(curl -s -o /dev/null -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -d '{}' \
  "http://127.0.0.1:${NGINX_HTTP_PORT}/api/auth/login")"
case "$auth_status" in
  200|400|401|403|415|422)
    log "auth is reachable via /api/auth/login (status $auth_status)"
    ;;
  *)
    die "Auth reachability check failed with status $auth_status"
    ;;
esac

check_compose_exec redis redis-cli ping
check_compose_exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --list

network="$(docker_network_name "$env")"
docker run --rm --network "$network" --entrypoint /bin/sh \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  "$MC_IMAGE" -ceu '
    mc alias set autoshop http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null
    mc ls autoshop >/dev/null
  '
log "minio internal check passed"
