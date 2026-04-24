# Deployment

## Local

```bash
cp .env.example .env
make init-local
make build-local
make up-local
```

## Staging

```bash
cp .env.example .env
make init-staging
make up-staging
```

По умолчанию staging deploy ожидает env-файлы в `/opt/autoshop/env/staging`. Если хотите другой путь, задайте `ENV_DIR` в `.env`.

## Production

```bash
cp .env.example .env
make init-prod
make up-prod
```

Рекомендуемый flow на сервере:

1. Склонировать `autoshop-infrastructure`.
2. Подготовить `.env`.
3. Заполнить `/opt/autoshop/env/prod/*.env`.
4. Залогиниться в Docker registry.
5. Выполнить `make up-prod`.
