# Troubleshooting

## Compose config does not build

```bash
make config
```

Чаще всего причина:

- не создан `.env`
- отсутствует один из `core.env/auth.env/notification.env/files.env/infrastructure.env`
- `NGINX_CONF` или `POSTGRES_INIT_DIR` указывают на несуществующий путь

## Health check fails

```bash
make ps
./scripts/ops/logs.sh core
./scripts/ops/logs.sh auth
./scripts/ops/logs.sh notification
./scripts/ops/logs.sh files
```

Проверьте отдельно:

```bash
curl http://localhost:8088/health/nginx
curl http://localhost:8088/internal/core/actuator/health
curl http://localhost:9000/minio/health/live
```
