# Security

Hardening checklist for self-hosted n8n. Not a comprehensive security
audit — covers the items every production deployment should address.

> Authoritative reference:
> <https://docs.n8n.io/hosting/securing/security-baseline/>

---

## Encryption key

`N8N_ENCRYPTION_KEY` encrypts stored credentials. Lose it → lose all
credentials irrecoverably.

**Day-0:**

- Generate with `openssl rand -hex 32`.
- Set as env var. Don't rely on the auto-generated file under
  `/home/node/.n8n/config`.
- Store in a secrets manager (HashiCorp Vault, AWS Secrets Manager,
  1Password, etc.).
- Back it up SEPARATELY from the database — losing both at once is the
  unrecoverable scenario.

**Rotating the key (deliberate, not casual):**

n8n provides a CLI to re-encrypt all credentials with a new key:

```bash
# 1. Back up the database AND the current key.
# 2. With OLD key still set:
docker compose exec n8n n8n export:credentials --backup --output=/home/node/.n8n/cred-backup.json

# 3. Stop n8n, change N8N_ENCRYPTION_KEY env to new value.
# 4. Start n8n with the new key.
# 5. Re-import credentials (n8n re-encrypts on import).
docker compose exec n8n n8n import:credentials --input=/home/node/.n8n/cred-backup.json
```

For queue mode, you must update the key on EVERY service (main, workers,
webhook) before any of them restart.

---

## Database credentials

- Use a non-superuser Postgres role scoped to the `n8n` database only.
- Rotate the password on a schedule via your secrets manager — n8n picks
  it up on restart.
- Enable TLS to the database: `DB_POSTGRESDB_SSL_ENABLED=true`. For
  managed Postgres, you usually also need to provide the CA bundle via
  `NODE_EXTRA_CA_CERTS`.

---

## Network exposure

- **NEVER** expose port 5678 to the internet directly. Always behind a
  reverse proxy.
- Redis (queue mode) — bind to internal network only. Set a strong
  password via `requirepass`. Never expose Redis to the public internet
  unauthenticated.
- Postgres — bind to internal network. Never publicly exposed.
- If using Docker Compose, omit `ports:` from internal services (Redis,
  Postgres) — they're reachable on the Compose network by service name.

---

## Authentication

n8n supports several auth modes:

| Mode | Plan | Notes |
|---|---|---|
| Email/password (built-in) | All | Default. Set up via `Owner setup` on first boot |
| SAML SSO | Enterprise | Configure via UI or `N8N_SSO_*` env vars |
| LDAP | Enterprise | `N8N_LDAP_*` env vars |
| OIDC | Enterprise | UI configuration |
| Workforce identity (Cloud) | Cloud Enterprise | Auto |

**Best practices:**

- Disable email/password auth once SSO is configured (Enterprise).
- Enforce MFA for the owner account.
- Treat the n8n owner role as a tenant-admin — anyone with it can read
  any credential, see all execution data.
- Use **Projects** (Enterprise) to scope access between teams.

---

## Code node sandboxing

Code nodes execute JavaScript/Python with extensive helpers. Treat anyone
who can edit a workflow as someone who can run code on the n8n host.

**Mitigations:**

- `N8N_BLOCK_ENV_ACCESS_IN_NODE=true` — disables `$env.X` in expressions
  and Code nodes. Important for multi-tenant.
- Keep `NODE_FUNCTION_ALLOW_EXTERNAL` and `NODE_FUNCTION_ALLOW_BUILTIN`
  empty unless you specifically need them.
- Set `N8N_RUNNERS_ENABLED=true` (where supported) to run Code nodes in
  isolated sandboxes (task runners).
- For multi-tenant, only trusted users get edit/create permissions on
  workflows (Enterprise RBAC).

---

## Binary data storage

Default mode (`N8N_DEFAULT_BINARY_DATA_MODE=default`) stores binaries
base64-encoded in the database / in-memory. Large attachments balloon
DB size and RAM.

**Production options:**

- `filesystem` mode: stores under `/n8n-binary-data/`. Use a separate disk
  and set `N8N_BINARY_DATA_TTL=60` (minutes) for auto-cleanup of orphans.
- `s3` mode (Enterprise): `N8N_EXTERNAL_STORAGE_S3_*` env vars. Survives
  container restarts cleanly, scales without disk constraints.

**Important:** When you switch modes on a live instance, old binaries in
the old mode remain accessible until they expire. New binaries go to the
new mode. Don't expect instant migration.

---

## Webhook payload limits

`N8N_PAYLOAD_SIZE_MAX=16` (MB) — bump if you accept larger webhooks, but
balance against memory pressure. Combine with `N8N_DEFAULT_BINARY_DATA_MODE=filesystem`
so large bodies don't sit in RAM.

---

## TLS

- TLS termination at the proxy is standard.
- For end-to-end TLS to n8n (defense-in-depth), use `N8N_SSL_KEY` and
  `N8N_SSL_CERT` env vars. Rare in practice — most teams trust the
  internal network between proxy and n8n.
- For Postgres-with-TLS, set `DB_POSTGRESDB_SSL_ENABLED=true` and provide
  the CA via `NODE_EXTRA_CA_CERTS=/path/to/ca.crt`.

---

## Logging considerations

- Avoid logging credentials. n8n itself doesn't log credential values, but
  Code nodes that `console.log($json)` may leak them if the workflow
  passes credentials through.
- `DB_LOGGING_ENABLED=true` logs full SQL — useful for debugging but very
  verbose and may include data values. Don't leave on in production.
- Ship logs to a SIEM (Splunk, Datadog, ELK). Set `N8N_LOG_OUTPUT=console,file`
  or use container log drivers.

---

## External Secrets (Enterprise)

Instead of storing credential values in n8n's encrypted DB, point them at
an external vault:

| Backend | Env vars |
|---|---|
| HashiCorp Vault | `N8N_EXTERNAL_SECRETS_HASHICORP_VAULT_*` |
| AWS Secrets Manager | `N8N_EXTERNAL_SECRETS_AWS_SECRETS_MANAGER_*` |
| Azure Key Vault | `N8N_EXTERNAL_SECRETS_AZURE_KEY_VAULT_*` |
| Google Secret Manager | `N8N_EXTERNAL_SECRETS_GOOGLE_SECRET_MANAGER_*` |
| Infisical | `N8N_EXTERNAL_SECRETS_INFISICAL_*` |
| CyberArk Conjur | `N8N_EXTERNAL_SECRETS_CYBERARK_CONJUR_*` |

Reference in expressions: `={{ $secrets.vaultName.path.to.secret }}`.

Secrets never persist in n8n; n8n fetches them at execution time and caches
briefly. Source-of-truth lives in the vault, where access can be audited
and rotated.

---

## Audit log (Enterprise)

`N8N_AUDIT_LOG_ENABLED=true` writes an append-only log of significant
events (auth, workflow CRUD, credential CRUD). Ship to SIEM.

---

## Quick security checklist

- [ ] `N8N_ENCRYPTION_KEY` set explicitly and backed up in a secrets
      manager
- [ ] Behind reverse proxy with TLS; port 5678 not publicly exposed
- [ ] Postgres (not SQLite), TLS to DB enabled if remote
- [ ] Redis (queue mode) password-protected and internal-only
- [ ] `WEBHOOK_URL` matches public URL
- [ ] Owner has MFA enabled
- [ ] SSO configured if multi-user (Enterprise)
- [ ] `N8N_BLOCK_ENV_ACCESS_IN_NODE=true` if untrusted workflow authors
- [ ] `NODE_FUNCTION_ALLOW_*` minimized
- [ ] `EXECUTIONS_DATA_PRUNE=true`
- [ ] Binary mode = `filesystem` or `s3` if any large attachments
- [ ] Backups running and tested (DB + `/home/node/.n8n` + binary dir)
- [ ] Logs shipped off-host
- [ ] Image version pinned (not `latest`)
- [ ] Health probes configured
- [ ] Monitoring on `/metrics`
