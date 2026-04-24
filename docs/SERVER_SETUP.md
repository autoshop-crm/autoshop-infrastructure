# Server Setup

Минимальный bootstrap:

```bash
sudo mkdir -p /opt/autoshop/env/prod /opt/autoshop/data/prod /opt/autoshop/backups
cp .env.example .env
./scripts/init/init-server.sh prod
```

Проверьте:

- `docker --version`
- `docker compose version`
- заполнены `/opt/autoshop/env/prod/*.env`
- `docker login` выполнен для registry с backend images
