SHELL := /bin/bash
ENV ?= $(shell grep -E '^ENVIRONMENT=' .env 2>/dev/null | cut -d= -f2 || echo local)

.PHONY: init-local init-staging init-prod build-local up-local down-local up-staging up-prod \
	pull logs ps status restart health smoke backup rollback config onboard-local onboard-server \
	onboard-macos reload-macos-nginx tunnel-macos clean-staging clean-staging-hard clean-prod clean-prod-hard \
	clean-macos clean-macos-hard

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

onboard-local:
	./scripts/onboarding/onboard-local.sh

onboard-server:
	./scripts/onboarding/onboard-server.sh

onboard-macos:
	./scripts/onboarding/onboard-macos.sh

reload-macos-nginx:
	./scripts/ops/reload-nginx.sh staging

tunnel-macos:
	./scripts/ops/tunnel-macos.sh staging

clean-staging:
	./scripts/ops/clean-env.sh staging soft

clean-staging-hard:
	./scripts/ops/clean-env.sh staging hard

clean-prod:
	./scripts/ops/clean-env.sh prod soft

clean-prod-hard:
	./scripts/ops/clean-env.sh prod hard

clean-macos:
	./scripts/ops/clean-env.sh staging soft

clean-macos-hard:
	./scripts/ops/clean-env.sh staging hard
