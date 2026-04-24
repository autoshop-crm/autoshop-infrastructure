SHELL := /bin/bash
ENV ?= $(shell grep -E '^ENVIRONMENT=' .env 2>/dev/null | cut -d= -f2 || echo local)

.PHONY: init-local init-staging init-prod build-local up-local down-local up-staging up-prod \
	pull logs ps status restart health smoke backup rollback config

init-local:
	./scripts/init/init-env.sh local
	./scripts/init/init-directories.sh local

init-staging:
	./scripts/init/init-server.sh staging

init-prod:
	./scripts/init/init-server.sh prod

build-local:
	./scripts/deploy/build-local-images.sh

up-local:
	./scripts/deploy/deploy-local.sh

down-local:
	./scripts/deploy/down.sh local

up-staging:
	./scripts/deploy/deploy-staging.sh

up-prod:
	./scripts/deploy/deploy-prod.sh

pull:
	./scripts/deploy/pull-images.sh $(ENV)

logs:
	./scripts/ops/logs.sh

ps:
	./scripts/ops/status.sh $(ENV)

status:
	./scripts/ops/status.sh $(ENV)

restart:
	./scripts/deploy/restart-services.sh $(ENV)

health:
	./scripts/ops/healthcheck.sh $(ENV)

smoke:
	./scripts/smoke/smoke-e2e.sh $(ENV)

backup:
	./scripts/backup/backup-postgres.sh $(ENV)
	./scripts/backup/backup-minio.sh $(ENV)

rollback:
	./scripts/ops/rollback.sh $(ENV)

config:
	./scripts/ops/config-check.sh $(ENV)
