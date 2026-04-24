# Rollback

После успешного deploy `deploy-prod.sh` сохраняет snapshot `.deploy-history/prod/last-known-good.env`.

Откат:

```bash
./scripts/ops/rollback.sh prod
```

Скрипт повторно тянет образы и поднимает стек с последним сохраненным набором root env-параметров.
