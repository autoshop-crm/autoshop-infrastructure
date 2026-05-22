#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

env="${1:-${ENVIRONMENT:-local}}"
set_context "$env"

require_command curl

compose_cmd "$env" ps >/dev/null

print_diagnostics() {
  log "Healthcheck diagnostics for ${env}:"
  compose_cmd "$env" ps || true
  log "Recent nginx logs:"
  compose_cmd "$env" logs --tail=80 nginx || true
}

trap 'print_diagnostics' ERR

check_http() {
  local url="$1"
  local label="$2"
  local retries="${3:-30}"
  local delay="${4:-2}"
  wait_for_http "$url" "$label" "$retries" "$delay"
  log "$label is healthy"
}

check_nginx_internal() {
  local path="$1"
  local label="$2"
  local retries="${3:-30}"
  local delay="${4:-2}"
  local attempt

  for attempt in $(seq 1 "$retries"); do
    if compose_cmd "$env" exec -T nginx sh -ceu \
      "wget -qO- 'http://127.0.0.1${path}' >/dev/null || curl -fsS 'http://127.0.0.1${path}' >/dev/null"; then
      log "$label is reachable via nginx internal route: http://127.0.0.1${path}"
      log "$label is healthy"
      return 0
    fi
    sleep "$delay"
  done

  die "$label did not become reachable via nginx internal route: http://127.0.0.1${path}"
}

check_compose_exec() {
  local service="$1"
  shift
  compose_cmd "$env" exec -T "$service" "$@" >/dev/null
  log "$service internal check passed"
}

check_nginx_internal "/health/nginx" "nginx" 15 2
check_nginx_internal "/internal/core/actuator/health" "core" 90 2
check_nginx_internal "/internal/files/actuator/health" "files" 30 2
check_nginx_internal "/internal/notification/actuator/health" "notification" 30 2
check_nginx_internal ":81/health/nginx" "crm-web nginx" 20 2
check_nginx_internal ":82/health/nginx" "client-web nginx" 20 2

check_http "http://127.0.0.1:${NGINX_HTTP_PORT}/health/nginx" "nginx public port" 10 2

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
