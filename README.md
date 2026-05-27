# autoshop-infrastructure

Единый deployment/operations-репозиторий для backend-контура AutoShop. Он поднимает:

- `autoshop-core`
- `autoshop-auth`
- `autoshop-notification`
- `autoshop-files`
- `autoshop-web-spec`
- `autoshop-client-web`
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
- для локальной web-интеграции: доступ к `../autoshop-web-spec` и `../autoshop-client-web/FrontClient`

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

Linux one-click / console onboarding:

```bash
chmod +x ./scripts/onboarding/onboard-local.sh
./scripts/onboarding/onboard-local.sh
```

Локальный прогон через готовые GHCR images:

```bash
cp .env.example .env
sed -i '' 's/^LOCAL_USE_GHCR_IMAGES=.*/LOCAL_USE_GHCR_IMAGES=true/' .env
sed -i '' 's/^LOCAL_BUILD_FROM_SOURCE=.*/LOCAL_BUILD_FROM_SOURCE=false/' .env
make up-local
```

После старта:

- Nginx: `http://localhost:8088`
- CRM web: `http://localhost:5173`
- Client web: `http://localhost:5174`
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
- `make onboard-local`
- `make onboard-server`
- `make onboard-macos`
- `make update-macos`
- `make reload-macos-nginx`
- `make tunnel-macos`
- `make clean-macos`
- `make clean-macos-hard`

## macOS Demo Flow

Первый запуск на macOS:

```bash
make onboard-macos
```

Обычное обновление без удаления данных:

```bash
make update-macos
```

Пересоздать только `nginx` после изменения demo-маршрутов:

```bash
make reload-macos-nginx
```

Поднять один публичный tunnel для демо:

```bash
make tunnel-macos
```

Быстрая локальная проверка после запуска:

```bash
curl -i http://localhost:8088/
curl -i http://localhost:8088/client/
curl -i http://localhost:8088/crm/
```

Полезные URL для macOS demo-flow:

- Gateway / selector: `http://localhost:8088/`
- Client web: `http://localhost:8088/client/`
- CRM web: `http://localhost:8088/crm/`
- Nginx health: `http://localhost:8088/health/nginx`
- Core health: `http://localhost:8088/internal/core/actuator/health`

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
- Для `local` WEB UI поднимаются из каталогов `WEB_SPEC_SOURCE_DIR` и `CLIENT_WEB_SOURCE_DIR`, собираются через `npm ci && npm run build`, а наружу публикуются через общий `nginx` на портах `5173` и `5174`.
- Для локального smoke/deploy-теста можно включить `LOCAL_USE_GHCR_IMAGES=true` и запускать весь стек из готовых образов GHCR, без локальной сборки приложений.
- Для `staging` и `prod` WEB UI должны приходить как готовые Docker images `WEB_SPEC_IMAGE` и `CLIENT_WEB_IMAGE`; сервер больше не обязан хранить исходники web-репозиториев.
- Для Linux есть canonical onboarding entrypoint `scripts/onboarding/onboard-local.sh`; GUI-запуск можно обернуть через `autoshop-onboard.desktop`.
- Автоустановка Docker в v1 ориентирована на Ubuntu/Debian и требует `sudo`.
- Production Nginx-конфиг сейчас рассчитан на внешний TLS termination. Если нужен TLS внутри контейнера, добавьте сертификаты и расширьте `nginx/prod/autoshop.conf`.
