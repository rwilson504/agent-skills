# Queue Mode

Queue mode separates n8n into a **main** process (UI, API, webhooks,
scheduler) and one or more **worker** processes (actual workflow execution),
coordinated via **Redis**.

When to switch: >50 concurrent executions, long-running workflows
(>5 min), need to scale horizontally, need rolling worker restarts without
downtime.

> Authoritative reference: <https://docs.n8n.io/hosting/scaling/queue-mode/>

---

## Architecture

```
                 ┌──────────────┐
   Browser ─────▶│   n8n MAIN   │──┐ enqueue
   Webhook ─────▶│  (UI/API)    │  │
                 └──────────────┘  │
                                   ▼
                              ┌────────┐
                              │ Redis  │
                              └────────┘
                                   ▲
                                   │ dequeue
                 ┌─────────────────┴──────────────────┐
                 │                                    │
         ┌──────────────┐                  ┌──────────────┐
         │  n8n WORKER  │   ...            │  n8n WORKER  │
         │  (execute)   │                  │  (execute)   │
         └──────────────┘                  └──────────────┘
```

Optionally a third process type — **webhook** workers — handles
high-volume webhook reception so the main process stays responsive.

---

## Compose for queue mode

```yaml
services:
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}"]
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 3s

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

  n8n:                                  # MAIN
    image: n8nio/n8n:1.78.0
    restart: unless-stopped
    command: ["n8n", "start"]
    ports:
      - "5678:5678"
    environment:
      # === Shared env (SAME on every service) ===
      N8N_ENCRYPTION_KEY: "${N8N_ENCRYPTION_KEY}"
      N8N_HOST: n8n.example.com
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://n8n.example.com/
      GENERIC_TIMEZONE: America/New_York
      TZ: America/New_York

      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n
      DB_POSTGRESDB_PASSWORD: "${POSTGRES_PASSWORD}"

      EXECUTIONS_MODE: queue
      QUEUE_BULL_REDIS_HOST: redis
      QUEUE_BULL_REDIS_PORT: 6379
      QUEUE_BULL_REDIS_PASSWORD: "${REDIS_PASSWORD}"

      EXECUTIONS_DATA_PRUNE: "true"
      EXECUTIONS_DATA_MAX_AGE: "336"

      N8N_METRICS: "true"

      # Main-specific: don't execute workflows on main (force to workers)
      N8N_DISABLE_PRODUCTION_MAIN_PROCESS: "true"
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  n8n-worker:                            # WORKER (scale this)
    image: n8nio/n8n:1.78.0
    restart: unless-stopped
    command: ["n8n", "worker", "--concurrency=10"]
    environment:
      # SAME shared env as main, including encryption key
      N8N_ENCRYPTION_KEY: "${N8N_ENCRYPTION_KEY}"
      GENERIC_TIMEZONE: America/New_York
      TZ: America/New_York

      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n
      DB_POSTGRESDB_PASSWORD: "${POSTGRES_PASSWORD}"

      EXECUTIONS_MODE: queue
      QUEUE_BULL_REDIS_HOST: redis
      QUEUE_BULL_REDIS_PORT: 6379
      QUEUE_BULL_REDIS_PASSWORD: "${REDIS_PASSWORD}"
    volumes:
      - n8n_data:/home/node/.n8n      # share for custom nodes, etc.
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  n8n-webhook:                           # WEBHOOK receiver (optional)
    image: n8nio/n8n:1.78.0
    restart: unless-stopped
    command: ["n8n", "webhook"]
    environment:
      # SAME shared env as main
      N8N_ENCRYPTION_KEY: "${N8N_ENCRYPTION_KEY}"
      WEBHOOK_URL: https://n8n.example.com/
      GENERIC_TIMEZONE: America/New_York
      TZ: America/New_York

      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n
      DB_POSTGRESDB_PASSWORD: "${POSTGRES_PASSWORD}"

      EXECUTIONS_MODE: queue
      QUEUE_BULL_REDIS_HOST: redis
      QUEUE_BULL_REDIS_PORT: 6379
      QUEUE_BULL_REDIS_PASSWORD: "${REDIS_PASSWORD}"
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

volumes:
  n8n_data:
  postgres_data:
  redis_data:
```

```bash
# Scale workers
docker compose up -d --scale n8n-worker=3
```

---

## Critical: env var consistency

Every service (main, worker, webhook) MUST share:

- `N8N_ENCRYPTION_KEY` — different keys = workers can't decrypt credentials
- `DB_*` — all services connect to the same DB
- `QUEUE_BULL_REDIS_*` — all services use the same Redis
- `EXECUTIONS_MODE=queue`
- `GENERIC_TIMEZONE` / `TZ`

Mismatch on any of these silently breaks something. **Use YAML anchors or
an env file to keep them in sync.**

```yaml
# Optional: use an anchor to DRY up shared env
x-shared-env: &shared-env
  N8N_ENCRYPTION_KEY: "${N8N_ENCRYPTION_KEY}"
  DB_TYPE: postgresdb
  DB_POSTGRESDB_HOST: postgres
  DB_POSTGRESDB_DATABASE: n8n
  DB_POSTGRESDB_USER: n8n
  DB_POSTGRESDB_PASSWORD: "${POSTGRES_PASSWORD}"
  EXECUTIONS_MODE: queue
  QUEUE_BULL_REDIS_HOST: redis
  QUEUE_BULL_REDIS_PORT: 6379
  QUEUE_BULL_REDIS_PASSWORD: "${REDIS_PASSWORD}"
  GENERIC_TIMEZONE: America/New_York
  TZ: America/New_York

services:
  n8n:
    environment:
      <<: *shared-env
      # main-specific:
      N8N_HOST: n8n.example.com
      WEBHOOK_URL: https://n8n.example.com/
      N8N_DISABLE_PRODUCTION_MAIN_PROCESS: "true"
      EXECUTIONS_DATA_PRUNE: "true"
      EXECUTIONS_DATA_MAX_AGE: "336"
      N8N_METRICS: "true"
    # ...

  n8n-worker:
    command: ["n8n", "worker", "--concurrency=10"]
    environment:
      <<: *shared-env
    # ...
```

---

## Concurrency tuning

Worker concurrency = `--concurrency=N` (default 10). Total concurrent
executions = workers × concurrency.

- Each concurrent execution holds memory proportional to its workload
  (binary data, item count). 10× concurrency × 200 MB = 2 GB per worker
  RAM budget.
- For CPU-bound workflows (Code-node heavy), keep concurrency near CPU
  count.
- For I/O-bound workflows (mostly waiting on HTTP), concurrency can be
  much higher (50+).

`N8N_CONCURRENCY_PRODUCTION_LIMIT` is a per-worker cap that overrides
`--concurrency`. Useful for emergency throttling without redeploying.

---

## Scheduler in queue mode

The Schedule Trigger runs on the **main** process, not workers. If the
main process is down, schedules don't fire. Run only ONE main process
across the cluster — multiple mains all firing schedules causes
double-execution.

For HA, use Kubernetes with a single-replica main StatefulSet + multiple
worker replicas. Or accept brief scheduler downtime during main restarts.

---

## Webhook reception in queue mode

By default, the main process receives webhooks and enqueues the execution.
For high webhook volume, add a dedicated `n8n webhook` service that ONLY
receives webhooks. Route inbound webhook traffic to it via the reverse
proxy (e.g. `/webhook/*` → webhook service, everything else → main).

---

## Health checks for workers

Workers don't expose `/healthz`. Health is observable via:

- `/metrics` (on main) — `n8n_workers_count` and queue depth
- Redis: `LLEN bull:jobs:wait` (number of pending jobs)
- Container exit / restart count

---

## Common queue-mode pitfalls

### 1. "Could not decrypt credentials" on worker

Worker's `N8N_ENCRYPTION_KEY` differs from main's.

### 2. Schedules fire twice

Two main processes running. Reduce to one. (Workers don't fire schedules.)

### 3. Workflow runs but UI shows "queued" forever

No worker available. Check `docker compose ps n8n-worker`. Check worker
logs for crash loops.

### 4. Jobs pile up in Redis

Worker concurrency too low for inbound rate. Scale workers or bump
`--concurrency`.

### 5. Workers restart and drop in-flight jobs

Set `QUEUE_WORKER_TIMEOUT=120` (seconds) to allow graceful shutdown. Bull
will re-queue truly orphaned jobs after the lock TTL.

### 6. Webhook process restarted, in-flight webhooks dropped

Use multiple webhook replicas behind the proxy with proper load balancing.

### 7. Main process executing workflows anyway

Set `N8N_DISABLE_PRODUCTION_MAIN_PROCESS=true` to force all production
executions to workers. The main process still handles manual ("Execute
Workflow" from the editor) executions.
