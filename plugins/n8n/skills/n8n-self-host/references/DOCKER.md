# Docker / Docker Compose

Reference Compose files and Docker recipes for self-hosted n8n.

> Authoritative reference: <https://docs.n8n.io/hosting/installation/docker/>
> Official examples: <https://github.com/n8n-io/n8n-hosting>

---

## Single-instance Compose (production-ready)

```yaml
# docker-compose.yml
services:
  n8n:
    image: n8nio/n8n:1.78.0          # PIN the version in production
    restart: unless-stopped
    ports:
      - "5678:5678"                  # behind reverse proxy in production
    environment:
      N8N_ENCRYPTION_KEY: "${N8N_ENCRYPTION_KEY}"
      N8N_HOST: n8n.example.com
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://n8n.example.com/
      GENERIC_TIMEZONE: America/New_York
      TZ: America/New_York

      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n
      DB_POSTGRESDB_PASSWORD: "${POSTGRES_PASSWORD}"

      EXECUTIONS_DATA_PRUNE: "true"
      EXECUTIONS_DATA_MAX_AGE: "336"

      N8N_METRICS: "true"
      N8N_LOG_LEVEL: info
      N8N_DIAGNOSTICS_ENABLED: "false"
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O - http://localhost:5678/healthz || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DB: n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  n8n_data:
  postgres_data:
```

```bash
# .env
N8N_ENCRYPTION_KEY=<openssl rand -hex 32>
POSTGRES_PASSWORD=<long random string>
```

```bash
docker compose up -d
docker compose logs -f n8n
```

---

## Queue mode Compose

See [QUEUE_MODE.md](QUEUE_MODE.md) for the full file. Key differences from
single-instance:

- Add `redis` service.
- Add `EXECUTIONS_MODE=queue` and `QUEUE_BULL_REDIS_*` env vars to all
  n8n services.
- Define separate `n8n` (main) and `n8n-worker` services.
- Optionally a `n8n-webhook` service for dedicated webhook processing.

---

## Building a custom n8n image

When you need:

- External npm packages allowed in Code nodes (`NODE_FUNCTION_ALLOW_EXTERNAL`)
- Community nodes installed without using the UI
- Custom CA certificates
- Custom fonts for PDF generation

```dockerfile
# Dockerfile
FROM n8nio/n8n:1.78.0

USER root

# External packages for Code node
RUN cd /usr/local/lib/node_modules/n8n && \
    npm install lodash uuid date-fns

# Pre-install community nodes (path on the official image)
RUN mkdir -p /home/node/.n8n/nodes && \
    cd /home/node/.n8n/nodes && \
    npm install n8n-nodes-mycompany

# Custom CA certificate
COPY ca.crt /usr/local/share/ca-certificates/internal-ca.crt
RUN update-ca-certificates

RUN chown -R node:node /home/node/.n8n

USER node

# Set NODE_EXTRA_CA_CERTS at runtime via env, not build, so it's overridable
```

Then in compose:

```yaml
services:
  n8n:
    build:
      context: .
      dockerfile: Dockerfile
    # ... rest as before
    environment:
      # ... rest as before
      NODE_FUNCTION_ALLOW_EXTERNAL: "lodash,uuid,date-fns"
      NODE_FUNCTION_ALLOW_BUILTIN: "crypto,url"
      NODE_EXTRA_CA_CERTS: "/etc/ssl/certs/ca-certificates.crt"
```

---

## File permissions on the volume

The official image runs as user `node` (UID 1000). The data volume must be
writable by UID 1000.

When using a bind mount instead of a named volume:

```yaml
volumes:
  - ./n8n_data:/home/node/.n8n
```

```bash
sudo chown -R 1000:1000 ./n8n_data
```

Named volumes (`n8n_data:` in the `volumes:` block) avoid this issue —
Docker manages ownership.

---

## Resource limits

```yaml
services:
  n8n:
    # ...
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2'
        reservations:
          memory: 512M
```

Rule-of-thumb sizing:

- Light usage: 512 MB RAM, 0.5 CPU
- Moderate: 2 GB RAM, 2 CPU
- Heavy: 8+ GB RAM, 4+ CPU + queue mode + multiple workers

Workflows that handle large files in binary mode need more headroom. Switch
to filesystem/S3 binary mode (`N8N_DEFAULT_BINARY_DATA_MODE=filesystem`) to
reduce RAM pressure.

---

## Logs

```bash
docker compose logs -f n8n           # tail
docker compose logs --since 1h n8n   # last hour
docker compose logs --tail=100 n8n   # last 100 lines
```

To persist logs to a file outside the container:

```yaml
services:
  n8n:
    environment:
      N8N_LOG_OUTPUT: console,file
      N8N_LOG_FILE_LOCATION: /home/node/.n8n/logs/
    # logs land in the volume at /home/node/.n8n/logs/
```

---

## Health checks

| Endpoint | Returns |
|---|---|
| `GET /healthz` | 200 if process is up |
| `GET /healthz/readiness` | 200 if DB connected and migrations done |
| `GET /metrics` | Prometheus metrics (when `N8N_METRICS=true`) |

Use `/healthz/readiness` for Kubernetes readiness probes — it prevents
routing traffic before DB migrations finish.

---

## Common Docker pitfalls

### 1. Lost data after `docker compose down -v`

`-v` deletes named volumes. Don't run it on production unless you mean it.

### 2. n8n keeps restarting on first boot

Usually one of:
- `N8N_ENCRYPTION_KEY` has whitespace or quotes
- Postgres not ready when n8n starts (fix with `depends_on.condition: service_healthy` as in the example)
- Port 5678 already bound by something else

### 3. "EACCES: permission denied, open '/home/node/.n8n/...'"

Bind mount with wrong ownership. `sudo chown -R 1000:1000 ./n8n_data`.

### 4. Webhook URL says `http://localhost:5678` in the UI

Missing `WEBHOOK_URL`, or it's set to the internal Docker URL. Set
`WEBHOOK_URL=https://your-public-domain/`.

### 5. Container OOM-killed

n8n itself is light, but Code nodes loading large data and binary in memory
are heavy. Add memory limits OR enable filesystem/S3 binary mode.

### 6. `latest` tag pulled new version that broke a workflow

PIN versions in production. `n8nio/n8n:1.78.0`, not `n8nio/n8n:latest`.
Upgrade deliberately (see [BACKUP_UPGRADE.md](BACKUP_UPGRADE.md)).
