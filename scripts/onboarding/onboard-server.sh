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

existing_admin_email="$(read_env_value "$ENV_DIR/auth.env" "BOOTSTRAP_EMAIL")"
existing_crm_port="$(read_env_value "$ROOT_DIR/.env" "WEB_SPEC_PUBLIC_PORT")"
existing_client_port="$(read_env_value "$ROOT_DIR/.env" "CLIENT_WEB_PUBLIC_PORT")"
existing_server_access_point="$(read_env_value "$ROOT_DIR/.env" "SERVER_ACCESS_POINT")"
existing_core_image="$(read_env_value "$ROOT_DIR/.env" "CORE_IMAGE")"
existing_core_image_tag="$(read_env_value "$ROOT_DIR/.env" "CORE_IMAGE_TAG")"
existing_auth_image="$(read_env_value "$ROOT_DIR/.env" "AUTH_IMAGE")"
existing_auth_image_tag="$(read_env_value "$ROOT_DIR/.env" "AUTH_IMAGE_TAG")"
existing_notification_image="$(read_env_value "$ROOT_DIR/.env" "NOTIFICATION_IMAGE")"
existing_notification_image_tag="$(read_env_value "$ROOT_DIR/.env" "NOTIFICATION_IMAGE_TAG")"
existing_files_image="$(read_env_value "$ROOT_DIR/.env" "FILES_IMAGE")"
existing_files_image_tag="$(read_env_value "$ROOT_DIR/.env" "FILES_IMAGE_TAG")"
existing_web_spec_image="$(read_env_value "$ROOT_DIR/.env" "WEB_SPEC_IMAGE")"
existing_web_spec_image_tag="$(read_env_value "$ROOT_DIR/.env" "WEB_SPEC_IMAGE_TAG")"
existing_client_web_image="$(read_env_value "$ROOT_DIR/.env" "CLIENT_WEB_IMAGE")"
existing_client_web_image_tag="$(read_env_value "$ROOT_DIR/.env" "CLIENT_WEB_IMAGE_TAG")"
existing_umapi_api_key="$(read_env_value "$ENV_DIR/core.env" "APP_UMAPI_API_KEY")"
existing_carreta_api_key="$(read_env_value "$ENV_DIR/core.env" "APP_CARRETA_API_KEY")"
existing_bootstrap_password="$(read_env_value "$ENV_DIR/auth.env" "BOOTSTRAP_PASSWORD")"
existing_jwt_secret="$(read_env_value "$ENV_DIR/auth.env" "JWT_SECRET")"
existing_auth_db_password="$(read_env_value "$ENV_DIR/auth.env" "DB_PASSWORD")"
existing_core_db_password="$(read_env_value "$ENV_DIR/core.env" "SPRING_DATASOURCE_PASSWORD")"
existing_notification_db_password="$(read_env_value "$ENV_DIR/notification.env" "SPRING_DATASOURCE_PASSWORD")"
existing_files_db_password="$(read_env_value "$ENV_DIR/files.env" "FILES_DB_PASSWORD")"
existing_core_minio_access_key="$(read_env_value "$ENV_DIR/core.env" "APP_MINIO_ACCESS_KEY")"
existing_core_minio_secret_key="$(read_env_value "$ENV_DIR/core.env" "APP_MINIO_SECRET_KEY")"
existing_files_minio_access_key="$(read_env_value "$ENV_DIR/files.env" "MINIO_ACCESS_KEY")"
existing_files_minio_secret_key="$(read_env_value "$ENV_DIR/files.env" "MINIO_SECRET_KEY")"
existing_root_postgres_password="$(read_env_value "$ROOT_DIR/.env" "POSTGRES_PASSWORD")"
existing_root_minio_user="$(read_env_value "$ROOT_DIR/.env" "MINIO_ROOT_USER")"
existing_root_minio_password="$(read_env_value "$ROOT_DIR/.env" "MINIO_ROOT_PASSWORD")"

default_admin_email="admin@autoshop.example"
if [[ "$environment" == "staging" ]]; then
  default_admin_email="admin@staging.autoshop.example"
fi
default_admin_email="${existing_admin_email:-$default_admin_email}"

admin_email="$(prompt_value "Admin email" "$default_admin_email")"
[[ -n "$admin_email" ]] || die "Admin email is required"

if [[ -n "$existing_bootstrap_password" ]]; then
  keep_existing_password="$(prompt_value "Keep existing admin password? (yes/no)" "yes")"
  case "$(lowercase "$keep_existing_password")" in
    yes|y)
      admin_password="$existing_bootstrap_password"
      ;;
    no|n)
      admin_password="$(prompt_secret "Admin password")"
      ;;
    *)
      die "Unsupported answer for existing admin password: $keep_existing_password"
      ;;
  esac
else
  admin_password="$(prompt_secret "Admin password")"
fi
[[ -n "$admin_password" ]] || die "Admin password is required"

crm_port="$(prompt_value "CRM port" "${existing_crm_port:-${WEB_SPEC_PUBLIC_PORT:-5173}}")"
client_port="$(prompt_value "Client WEB port" "${existing_client_port:-${CLIENT_WEB_PUBLIC_PORT:-5174}}")"
server_access_point_default="$(hostname -I 2>/dev/null | awk '{print $1}')"
server_access_point_default="${server_access_point_default:-SERVER_IP}"
server_access_point="$(prompt_value "Server IP / base access point" "${existing_server_access_point:-$server_access_point_default}")"
umapi_api_key="$(prompt_value "UMAPI API key (leave empty if not available)" "${existing_umapi_api_key:-${APP_UMAPI_API_KEY:-}}")"
carreta_api_key="$(prompt_value "Carreta API key (leave empty if not available)" "${existing_carreta_api_key:-${APP_CARRETA_API_KEY:-}}")"

core_image="$(prompt_value "CORE image" "${existing_core_image:-${CORE_IMAGE:-ghcr.io/autoshop-crm/autoshop-core}}")"
core_image_tag="$(prompt_value "CORE image tag" "${existing_core_image_tag:-${CORE_IMAGE_TAG:-latest}}")"
auth_image="$(prompt_value "AUTH image" "${existing_auth_image:-${AUTH_IMAGE:-ghcr.io/autoshop-crm/autoshop-auth}}")"
auth_image_tag="$(prompt_value "AUTH image tag" "${existing_auth_image_tag:-${AUTH_IMAGE_TAG:-latest}}")"
notification_image="$(prompt_value "NOTIFICATION image" "${existing_notification_image:-${NOTIFICATION_IMAGE:-ghcr.io/autoshop-crm/autoshop-notification}}")"
notification_image_tag="$(prompt_value "NOTIFICATION image tag" "${existing_notification_image_tag:-${NOTIFICATION_IMAGE_TAG:-latest}}")"
files_image="$(prompt_value "FILES image" "${existing_files_image:-${FILES_IMAGE:-ghcr.io/autoshop-crm/autoshop-files}}")"
files_image_tag="$(prompt_value "FILES image tag" "${existing_files_image_tag:-${FILES_IMAGE_TAG:-latest}}")"
web_spec_image="$(prompt_value "CRM web image" "${existing_web_spec_image:-${WEB_SPEC_IMAGE:-ghcr.io/autoshop-crm/autoshop-web-spec}}")"
web_spec_image_tag="$(prompt_value "CRM web image tag" "${existing_web_spec_image_tag:-${WEB_SPEC_IMAGE_TAG:-latest}}")"
client_web_image="$(prompt_value "Client WEB image" "${existing_client_web_image:-${CLIENT_WEB_IMAGE:-ghcr.io/autoshop-crm/autoshop-client-web}}")"
client_web_image_tag="$(prompt_value "Client WEB image tag" "${existing_client_web_image_tag:-${CLIENT_WEB_IMAGE_TAG:-latest}}")"

install_docker_choice="$(prompt_value "Install Docker automatically if missing? (yes/no)" "yes")"
case "$(lowercase "$install_docker_choice")" in
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
run_logged "$ROOT_DIR/scripts/ops/disk-preflight.sh" "$environment"

run_logged "$ROOT_DIR/scripts/init/init-env.sh" "$environment"
run_logged "$ROOT_DIR/scripts/init/init-directories.sh" "$environment"

set_context "$environment"

shared_postgres_password="$(prefer_non_placeholder \
  "$existing_root_postgres_password" \
  "$existing_core_db_password" \
  "$existing_auth_db_password" \
  "$existing_notification_db_password" \
  "$existing_files_db_password")"
if is_placeholder_secret "$shared_postgres_password"; then
  shared_postgres_password="$(random_secret)"
fi

shared_minio_access_key="$(prefer_non_placeholder \
  "$existing_root_minio_user" \
  "$existing_core_minio_access_key" \
  "$existing_files_minio_access_key" \
  "${MINIO_ROOT_USER:-}")"
if is_placeholder_secret "$shared_minio_access_key"; then
  shared_minio_access_key="minioadmin"
fi

shared_minio_secret_key="$(prefer_non_placeholder \
  "$existing_root_minio_password" \
  "$existing_core_minio_secret_key" \
  "$existing_files_minio_secret_key" \
  "${MINIO_ROOT_PASSWORD:-}")"
if is_placeholder_secret "$shared_minio_secret_key"; then
  shared_minio_secret_key="$(random_secret)"
fi

write_env_value "$ROOT_DIR/.env" "ENVIRONMENT" "$environment"
write_env_value "$ROOT_DIR/.env" "WEB_SPEC_PUBLIC_PORT" "$crm_port"
write_env_value "$ROOT_DIR/.env" "CLIENT_WEB_PUBLIC_PORT" "$client_port"
write_env_value "$ROOT_DIR/.env" "NGINX_HTTP_PORT" "${NGINX_HTTP_PORT:-80}"
write_env_value "$ROOT_DIR/.env" "POSTGRES_PASSWORD" "$shared_postgres_password"
write_env_value "$ROOT_DIR/.env" "MINIO_ROOT_USER" "$shared_minio_access_key"
write_env_value "$ROOT_DIR/.env" "MINIO_ROOT_PASSWORD" "$shared_minio_secret_key"
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
write_env_value "$ENV_DIR/auth.env" "JWT_SECRET" "${existing_jwt_secret:-$(random_secret)}"
write_env_value "$ENV_DIR/auth.env" "DB_PASSWORD" "$shared_postgres_password"

write_env_value "$ENV_DIR/infrastructure.env" "APP_ENVIRONMENT" "$environment"
write_env_value "$ENV_DIR/core.env" "SPRING_DATASOURCE_PASSWORD" "$shared_postgres_password"
write_env_value "$ENV_DIR/notification.env" "SPRING_DATASOURCE_PASSWORD" "$shared_postgres_password"
write_env_value "$ENV_DIR/files.env" "FILES_DB_PASSWORD" "$shared_postgres_password"
write_env_value "$ENV_DIR/core.env" "APP_MINIO_ACCESS_KEY" "$shared_minio_access_key"
write_env_value "$ENV_DIR/core.env" "APP_MINIO_SECRET_KEY" "$shared_minio_secret_key"
write_env_value "$ENV_DIR/files.env" "MINIO_ACCESS_KEY" "$shared_minio_access_key"
write_env_value "$ENV_DIR/files.env" "MINIO_SECRET_KEY" "$shared_minio_secret_key"
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
