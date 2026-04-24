# Environment Variables

## Root `.env`

- `ENVIRONMENT`
- `COMPOSE_PROJECT_NAME`
- `ENV_DIR`
- `DATA_ROOT`
- `BACKUP_ROOT`
- `NGINX_CONF`
- `POSTGRES_INIT_DIR`
- image variables `CORE_IMAGE`, `AUTH_IMAGE`, `NOTIFICATION_IMAGE`, `FILES_IMAGE`
- image tags `CORE_IMAGE_TAG`, `AUTH_IMAGE_TAG`, `NOTIFICATION_IMAGE_TAG`, `FILES_IMAGE_TAG`

## Service env files

- `core.env`: datasource, Redis, Kafka, MinIO, Mail, `APP_AUTH_BASE_URL`
- `auth.env`: datasource, Redis, `JWT_SECRET`
- `notification.env`: datasource, Kafka, SMTP or Mailjet
- `files.env`: datasource, MinIO, `SERVER_PORT=8084`
- `infrastructure.env`: shared values like `MINIO_BUCKETS`, mail sender identity
