#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

ensure_onboarding_log_dir
exec > >(tee -a "$ONBOARDING_LOG_FILE") 2>&1

trap 'log "Server onboarding failed on line $LINENO"; exit 1' ERR

require_linux

log "Starting AutoShop server onboarding (V1 skeleton)"

require_command bash
require_command grep
require_command sed

if ! command -v sudo >/dev/null 2>&1; then
  die "sudo is required for server onboarding"
fi

"$SCRIPT_DIR/install-deps-linux.sh"

environment="$(prompt_value "Environment (prod/staging)" "prod")"
case "$environment" in
  prod|staging)
    ;;
  *)
    die "Unsupported environment: $environment"
    ;;
esac

set_context "$environment"

default_admin_email="admin@autoshop.example"
if [[ "$environment" == "staging" ]]; then
  default_admin_email="admin@staging.autoshop.example"
fi

admin_email="$(prompt_value "Admin email" "$default_admin_email")"
[[ -n "$admin_email" ]] || die "Admin email is required"

admin_password="$(prompt_secret "Admin password")"
[[ -n "$admin_password" ]] || die "Admin password is required"

crm_port="$(prompt_value "CRM port" "${WEB_SPEC_PUBLIC_PORT:-5173}")"
client_port="$(prompt_value "Client WEB port" "${CLIENT_WEB_PUBLIC_PORT:-5174}")"
server_access_point_default="$(hostname -I 2>/dev/null | awk '{print $1}')"
server_access_point_default="${server_access_point_default:-SERVER_IP}"
server_access_point="$(prompt_value "Server IP / base access point" "$server_access_point_default")"
umapi_api_key="$(prompt_value "UMAPI API key (leave empty if not available)" "${APP_UMAPI_API_KEY:-}")"
carreta_api_key="$(prompt_value "Carreta API key (leave empty if not available)" "${APP_CARRETA_API_KEY:-}")"

core_image="$(prompt_value "CORE image" "${CORE_IMAGE:-ghcr.io/autoshop-crm/autoshop-core}")"
core_image_tag="$(prompt_value "CORE image tag" "${CORE_IMAGE_TAG:-latest}")"
auth_image="$(prompt_value "AUTH image" "${AUTH_IMAGE:-ghcr.io/autoshop-crm/autoshop-auth}")"
auth_image_tag="$(prompt_value "AUTH image tag" "${AUTH_IMAGE_TAG:-latest}")"
notification_image="$(prompt_value "NOTIFICATION image" "${NOTIFICATION_IMAGE:-ghcr.io/autoshop-crm/autoshop-notification}")"
notification_image_tag="$(prompt_value "NOTIFICATION image tag" "${NOTIFICATION_IMAGE_TAG:-latest}")"
files_image="$(prompt_value "FILES image" "${FILES_IMAGE:-ghcr.io/autoshop-crm/autoshop-files}")"
files_image_tag="$(prompt_value "FILES image tag" "${FILES_IMAGE_TAG:-latest}")"
web_spec_image="$(prompt_value "CRM web image" "${WEB_SPEC_IMAGE:-ghcr.io/autoshop-crm/autoshop-web-spec}")"
web_spec_image_tag="$(prompt_value "CRM web image tag" "${WEB_SPEC_IMAGE_TAG:-latest}")"
client_web_image="$(prompt_value "Client WEB image" "${CLIENT_WEB_IMAGE:-ghcr.io/autoshop-crm/autoshop-client-web}")"
client_web_image_tag="$(prompt_value "Client WEB image tag" "${CLIENT_WEB_IMAGE_TAG:-latest}")"

install_docker_choice="$(prompt_value "Install Docker automatically if missing? (yes/no)" "yes")"
case "${install_docker_choice,,}" in
  yes|y)
    "$SCRIPT_DIR/install-docker-linux.sh"
    ;;
  no|n)
    log "Skipping Docker auto-install by user choice"
    ;;
  *)
    die "Unsupported answer for Docker install: $install_docker_choice"
    ;;
esac

"$SCRIPT_DIR/check-docker.sh"

run_logged "$ROOT_DIR/scripts/init/init-env.sh" "$environment"
run_logged "$ROOT_DIR/scripts/init/init-directories.sh" "$environment"

set_context "$environment"

write_env_value "$ROOT_DIR/.env" "ENVIRONMENT" "$environment"
write_env_value "$ROOT_DIR/.env" "WEB_SPEC_PUBLIC_PORT" "$crm_port"
write_env_value "$ROOT_DIR/.env" "CLIENT_WEB_PUBLIC_PORT" "$client_port"
write_env_value "$ROOT_DIR/.env" "NGINX_HTTP_PORT" "${NGINX_HTTP_PORT:-80}"
write_env_value "$ROOT_DIR/.env" "SERVER_ACCESS_POINT" "$server_access_point"
write_env_value "$ROOT_DIR/.env" "CORE_IMAGE" "$core_image"
write_env_value "$ROOT_DIR/.env" "CORE_IMAGE_TAG" "$core_image_tag"
write_env_value "$ROOT_DIR/.env" "AUTH_IMAGE" "$auth_image"
write_env_value "$ROOT_DIR/.env" "AUTH_IMAGE_TAG" "$auth_image_tag"
write_env_value "$ROOT_DIR/.env" "NOTIFICATION_IMAGE" "$notification_image"
write_env_value "$ROOT_DIR/.env" "NOTIFICATION_IMAGE_TAG" "$notification_image_tag"
write_env_value "$ROOT_DIR/.env" "FILES_IMAGE" "$files_image"
write_env_value "$ROOT_DIR/.env" "FILES_IMAGE_TAG" "$files_image_tag"
write_env_value "$ROOT_DIR/.env" "WEB_SPEC_IMAGE" "$web_spec_image"
write_env_value "$ROOT_DIR/.env" "WEB_SPEC_IMAGE_TAG" "$web_spec_image_tag"
write_env_value "$ROOT_DIR/.env" "CLIENT_WEB_IMAGE" "$client_web_image"
write_env_value "$ROOT_DIR/.env" "CLIENT_WEB_IMAGE_TAG" "$client_web_image_tag"

write_env_value "$ENV_DIR/auth.env" "BOOTSTRAP_EMAIL" "$admin_email"
write_env_value "$ENV_DIR/auth.env" "BOOTSTRAP_PASSWORD" "$admin_password"
write_env_value "$ENV_DIR/auth.env" "BOOTSTRAP_ROLE" "ADMIN"
write_env_value "$ENV_DIR/auth.env" "JWT_SECRET" "$(random_secret)"

write_env_value "$ENV_DIR/infrastructure.env" "APP_ENVIRONMENT" "$environment"
write_env_value "$ENV_DIR/core.env" "APP_UMAPI_API_KEY" "$umapi_api_key"
write_env_value "$ENV_DIR/core.env" "APP_CARRETA_API_KEY" "$carreta_api_key"

require_env_files "$environment"

run_logged "$ROOT_DIR/scripts/deploy/pull-images.sh" "$environment"

case "$environment" in
  staging)
    run_logged "$ROOT_DIR/scripts/deploy/deploy-staging.sh"
    ;;
  prod)
    run_logged "$ROOT_DIR/scripts/deploy/deploy-prod.sh"
    ;;
esac

set_context "$environment"
print_server_onboarding_summary "$server_access_point"
