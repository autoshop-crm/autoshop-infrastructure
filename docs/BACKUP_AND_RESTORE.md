# Backup And Restore

## PostgreSQL

```bash
./scripts/backup/backup-postgres.sh prod
./scripts/backup/restore-postgres.sh prod /opt/autoshop/backups/postgres/prod/core_db-20260424-120000.sql core_db
```

## MinIO

```bash
./scripts/backup/backup-minio.sh prod
```

MinIO backup сейчас файловый: архивируется каталог `${DATA_ROOT}/minio`.
