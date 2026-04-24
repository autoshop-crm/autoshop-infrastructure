# autoshop-infrastructure

Единый deployment/operations-репозиторий для backend-контура AutoShop. Он поднимает:

- `autoshop-core`
- `autoshop-auth`
- `autoshop-notification`
- `autoshop-files`
- PostgreSQL
- Redis
- Kafka
- MinIO
- Mailhog для `local` и `staging`
- Nginx как reverse proxy

## Requirements

- Docker 24+
- Docker Compose v2
- `curl`
- для локальной сборки из исходников: доступ к соседним репозиториям `../autoshop-core`, `../autoshop-auth`, `../autoshop-notification`, `../autoshop-files`

## Environments

- `local`: значения уже лежат в `env/local/*.env`, данные пишутся в `data/local`
- `staging`: env-файлы создаются из `env/staging/*.env.example`
- `prod`: env-файлы создаются из `env/prod/*.env.example`

Все окружения используют один и тот же compose-стек:

- [compose/compose.base.yml](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/compose/compose.base.yml)
- [compose/compose.local.yml](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/compose/compose.local.yml)
- [compose/compose.staging.yml](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/compose/compose.staging.yml)
- [compose/compose.prod.yml](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/compose/compose.prod.yml)

## Quick Start

Локально:

```bash
cp .env.example .env
make init-local
make up-local
```

После старта:

- Nginx: `http://localhost:8088`
- Core health: `http://localhost:8088/internal/core/actuator/health`
- Files health: `http://localhost:8088/internal/files/actuator/health`
- Notification health: `http://localhost:8088/internal/notification/actuator/health`
- Mailhog UI: `http://localhost:8025`
- MinIO console: `http://localhost:9001`

Staging:

```bash
cp .env.example .env
sed -i '' 's/^ENVIRONMENT=.*/ENVIRONMENT=staging/' .env
make init-staging
make up-staging
```

Production:

```bash
cp .env.example .env
sed -i '' 's/^ENVIRONMENT=.*/ENVIRONMENT=prod/' .env
make init-prod
make up-prod
```

## Main Commands

- `make init-local`
- `make build-local`
- `make up-local`
- `make down-local`
- `make up-staging`
- `make up-prod`
- `make pull`
- `make ps`
- `make logs`
- `make health`
- `make smoke`
- `make backup`
- `make rollback`
- `make config`

## Deploy Flow

`deploy-prod.sh` делает:

1. Проверку `docker` и env-файлов.
2. Валидацию `docker compose config`.
3. `docker compose pull`.
4. `docker compose up -d --remove-orphans`.
5. Инициализацию MinIO buckets.
6. Health checks.
7. Smoke tests.
8. Обновление snapshot `last-known-good.env` для rollback.

## Config Layout

- root variables: [.env.example](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/.env.example)
- local env: [env/local](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/env/local)
- staging examples: [env/staging](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/env/staging)
- prod examples: [env/prod](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/env/prod)
- nginx: [nginx](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/nginx)
- postgres bootstrap: [postgres/init/01-create-databases.sql](/Users/vladislavkovrigin/Projects/IdeaProjects/autoshop-infrastructure/postgres/init/01-create-databases.sql)

## Operations

- логи: `./scripts/ops/logs.sh core`
- статус: `./scripts/ops/status.sh prod`
- рестарт одного сервиса: `./scripts/ops/restart-one.sh prod notification`
- Kafka topics: `./scripts/ops/kafka-topics.sh local --list`
- backup postgres: `./scripts/backup/backup-postgres.sh prod`
- backup minio: `./scripts/backup/backup-minio.sh prod`
- restore postgres: `./scripts/backup/restore-postgres.sh prod /path/to/core.sql core_db`

## Notes

- Для `staging` и `prod` по умолчанию ожидается deploy готовых Docker images из registry.
- Для `local` можно собирать образы из соседних репозиториев через `make build-local`.
- Production Nginx-конфиг сейчас рассчитан на внешний TLS termination. Если нужен TLS внутри контейнера, добавьте сертификаты и расширьте `nginx/prod/autoshop.conf`.
