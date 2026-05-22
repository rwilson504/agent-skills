# Environment Variables — Annotated

Curated reference for the n8n env vars that matter in production. Full
catalog at
<https://docs.n8n.io/hosting/configuration/environment-variables/>.

---

## Identity / encryption

| Var | Default | Notes |
|---|---|---|
| `N8N_ENCRYPTION_KEY` | auto-generated on first boot | **SET EXPLICITLY**. 32+ chars. NEVER change after first boot without rotating credentials. |
| `N8N_USER_FOLDER` | `/home/node/.n8n` | Where the config dir lives (encryption key fallback, SQLite DB, etc.) |

## Public URL

| Var | Default | Notes |
|---|---|---|
| `N8N_HOST` | `localhost` | Host part of URLs n8n constructs |
| `N8N_PORT` | `5678` | Internal port |
| `N8N_PROTOCOL` | `http` | `http` or `https` |
| `WEBHOOK_URL` | `http://localhost:5678/` | Public URL prefix for webhook URLs reported in the UI. **Must match what callers hit** |
| `N8N_PATH` | `/` | Set if hosting at a subpath (e.g. `/n8n/`) |
| `N8N_LISTEN_ADDRESS` | `0.0.0.0` | Interface to bind |

## Timezone

| Var | Default | Notes |
|---|---|---|
| `GENERIC_TIMEZONE` | `America/New_York` (n8n) | Default for Schedule Trigger when workflow `settings.timezone` not set |
| `TZ` | system default | Container's OS timezone — match `GENERIC_TIMEZONE` |

## Database

| Var | Default | Notes |
|---|---|---|
| `DB_TYPE` | `sqlite` | **Set to `postgresdb`** in production |
| `DB_POSTGRESDB_HOST` | `localhost` | |
| `DB_POSTGRESDB_PORT` | `5432` | |
| `DB_POSTGRESDB_DATABASE` | `n8n` | |
| `DB_POSTGRESDB_USER` | `postgres` | |
| `DB_POSTGRESDB_PASSWORD` | | |
| `DB_POSTGRESDB_SCHEMA` | `public` | |
| `DB_POSTGRESDB_SSL_ENABLED` | `false` | `true` for managed Postgres |
| `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED` | `true` | `false` to accept self-signed |
| `DB_POSTGRESDB_POOL_SIZE` | `2` | Bump to `10`+ under load |
| `DB_LOGGING_ENABLED` | `false` | Log all SQL (very verbose) |
| `DB_SQLITE_VACUUM_ON_STARTUP` | `false` | Compact SQLite (irrelevant in prod) |

## Executions

| Var | Default | Notes |
|---|---|---|
| `EXECUTIONS_MODE` | `regular` | `queue` for queue mode |
| `EXECUTIONS_TIMEOUT` | `-1` | Default per-execution timeout in seconds (`-1` = no timeout) |
| `EXECUTIONS_TIMEOUT_MAX` | `3600` | Hard ceiling users can set per-workflow |
| `EXECUTIONS_DATA_PRUNE` | `false` | **Set `true`** in production |
| `EXECUTIONS_DATA_MAX_AGE` | `336` | Hours to keep execution data (`336` = 14 days) |
| `EXECUTIONS_DATA_PRUNE_MAX_COUNT` | `10000` | Cap of executions retained (whichever hits first) |
| `EXECUTIONS_DATA_SAVE_ON_ERROR` | `all` | `all` \| `none` |
| `EXECUTIONS_DATA_SAVE_ON_SUCCESS` | `all` | `all` \| `none`. Set `none` to skip success data (saves disk) |
| `EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS` | `true` | Pre-1.0 default was `false` |
| `EXECUTIONS_DATA_SAVE_ON_PROGRESS` | `false` | Saves intermediate state (expensive) |

## Queue mode (when `EXECUTIONS_MODE=queue`)

| Var | Default | Notes |
|---|---|---|
| `QUEUE_BULL_REDIS_HOST` | `localhost` | |
| `QUEUE_BULL_REDIS_PORT` | `6379` | |
| `QUEUE_BULL_REDIS_USERNAME` | | For Redis ACLs |
| `QUEUE_BULL_REDIS_PASSWORD` | | |
| `QUEUE_BULL_REDIS_DB` | `0` | |
| `QUEUE_BULL_REDIS_TLS` | `false` | `true` for managed Redis with TLS |
| `QUEUE_WORKER_TIMEOUT` | `30` | Seconds to wait for graceful worker shutdown |
| `N8N_CONCURRENCY_PRODUCTION_LIMIT` | `-1` | Max concurrent executions per worker. `-1` = unlimited. Set to cap rate-limited API exposure |
| `N8N_DISABLE_PRODUCTION_MAIN_PROCESS` | `false` | `true` to forbid the main process from executing workflows (force them to workers) |

## Webhooks

| Var | Default | Notes |
|---|---|---|
| `N8N_PAYLOAD_SIZE_MAX` | `16` | Max webhook body size in MB |
| `WEBHOOK_TUNNEL_URL` | | Set when using a tunnel (ngrok, etc.) |

## Binary data

| Var | Default | Notes |
|---|---|---|
| `N8N_DEFAULT_BINARY_DATA_MODE` | `default` | `default` (in-memory base64), `filesystem`, `s3` |
| `N8N_BINARY_DATA_TTL` | `60` | Minutes before orphan binary cleanup |
| `N8N_EXTERNAL_STORAGE_S3_*` | | S3 bucket config when mode = `s3` |
| `N8N_AVAILABLE_BINARY_DATA_MODES` | `filesystem,default,s3` | Modes allowed at runtime |

## Security

| Var | Default | Notes |
|---|---|---|
| `N8N_BLOCK_ENV_ACCESS_IN_NODE` | `false` | `true` to disallow `$env.X` in expressions/Code nodes (recommended for multi-tenant) |
| `N8N_BLOCK_FILE_ACCESS_TO_N8N_FILES` | `true` | Restricts file ops to safe paths |
| `N8N_SECURE_COOKIE` | `true` | Cookies require HTTPS (set `false` for HTTP dev) |
| `N8N_RUNNERS_ENABLED` | varies | Enables task runner sandbox (newer architecture; check current default) |
| `N8N_DIAGNOSTICS_ENABLED` | `true` | `false` to disable anonymous telemetry to n8n.io |

## Code node allowlists

| Var | Default | Notes |
|---|---|---|
| `NODE_FUNCTION_ALLOW_BUILTIN` | (blocked) | CSV of allowed Node built-ins, e.g. `crypto,url,fs` |
| `NODE_FUNCTION_ALLOW_EXTERNAL` | (blocked) | CSV of allowed npm packages, e.g. `lodash,uuid` |

## Logging

| Var | Default | Notes |
|---|---|---|
| `N8N_LOG_LEVEL` | `info` | `error`, `warn`, `info`, `debug`, `silent` |
| `N8N_LOG_OUTPUT` | `console` | `console`, `file`, or `console,file` |
| `N8N_LOG_FILE_LOCATION` | `/home/node/.n8n/logs/` | Where to write log files |
| `N8N_LOG_FILE_MAXSIZE` | `16` | MB per file before rotation |
| `N8N_LOG_FILE_MAXCOUNT` | `100` | Number of rotated files to keep |

## Metrics

| Var | Default | Notes |
|---|---|---|
| `N8N_METRICS` | `false` | `true` to expose Prometheus on `/metrics` |
| `N8N_METRICS_INCLUDE_DEFAULT_METRICS` | `true` | Process metrics |
| `N8N_METRICS_INCLUDE_API_ENDPOINTS` | `false` | Per-endpoint counters |

## Enterprise / Cloud only (subset)

| Var | Notes |
|---|---|
| `N8N_LICENSE_ACTIVATION_KEY` | Enterprise license activation |
| `N8N_SSO_*` | SAML/OIDC SSO |
| `N8N_LDAP_*` | LDAP integration |
| `N8N_EXTERNAL_SECRETS_*` | External Secrets backends |
| `N8N_SOURCECONTROL_*` | Git source control |
| `N8N_LOG_STREAMING_*` | Log streaming to external destinations |

---

## Execution data retention

The default retention can grow the database large fast. For most teams:

```bash
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=336              # 14 days
EXECUTIONS_DATA_PRUNE_MAX_COUNT=50000    # safety cap
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all      # set to 'none' if you only debug errors
```

Trigger an immediate prune via the n8n CLI:

```bash
docker compose exec n8n n8n executionData --action prune --maxAge 336
```

---

## Quick sanity check

After deployment, verify the most important env vars are actually in
effect:

```bash
# Inside the container
docker compose exec n8n env | grep -E '^(N8N_|WEBHOOK_|EXECUTIONS_|DB_|QUEUE_)'
```

Compare against your intended config. Easy to typo a variable name and have
it silently ignored.
