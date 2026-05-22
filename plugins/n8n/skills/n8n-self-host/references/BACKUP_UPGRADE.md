# Backup & Upgrade

How to back up an n8n instance, restore from backup, and upgrade safely.

> Authoritative reference:
> <https://docs.n8n.io/hosting/cli-commands/> and
> <https://docs.n8n.io/hosting/installation/updating/>

---

## What to back up

| Artifact | Where (default Docker) | Why |
|---|---|---|
| Database | Postgres / SQLite under `/home/node/.n8n/database.sqlite` | Workflows, credentials (encrypted), execution data, settings |
| `N8N_ENCRYPTION_KEY` | Env var (and fallback `/home/node/.n8n/config`) | Required to decrypt credentials |
| `/home/node/.n8n/` config dir | Volume `n8n_data` | License file, custom nodes installed via UI, the encryption-key fallback |
| Binary data dir (if filesystem mode) | `/home/node/.n8n/binaryData/` | Workflow file attachments |
| S3 bucket (if S3 mode) | Wherever your bucket lives | Same as above |
| Compose / Helm values / .env | Your repo or secrets manager | Reproduce the environment |

**Three things you cannot lose:**

1. The database
2. The encryption key
3. The Compose file / values (so you can stand up the same image version
   with the same env vars)

---

## Backup procedures

### Postgres

Daily dumps via `pg_dump`:

```bash
docker compose exec -T postgres pg_dump -U n8n -d n8n --no-owner --no-privileges \
  | gzip > "n8n-pg-$(date +%F).sql.gz"
```

Ship to S3/Azure Blob/etc. Retain at least 14 days.

Restore:

```bash
gunzip -c n8n-pg-2026-01-15.sql.gz \
  | docker compose exec -T postgres psql -U n8n -d n8n
```

### SQLite (dev or pre-migration)

Stop n8n first to avoid copying a locked / mid-write file:

```bash
docker compose stop n8n
docker compose cp n8n:/home/node/.n8n/database.sqlite ./backup-$(date +%F).sqlite
docker compose start n8n
```

### Config dir + binary data

```bash
# Snapshot the named volume
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/n8n-volume-$(date +%F).tgz -C /data .
```

Restore:

```bash
docker volume create n8n_data
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine \
  tar xzf /backup/n8n-volume-2026-01-15.tgz -C /data
```

### n8n export CLI (workflow/credential level)

For portable, version-independent exports:

```bash
# Workflows
docker compose exec n8n n8n export:workflow --all --output=/home/node/.n8n/wf-backup.json

# Credentials (encrypted with current N8N_ENCRYPTION_KEY)
docker compose exec n8n n8n export:credentials --all --output=/home/node/.n8n/cred-backup.json

# Backup the files out of the container
docker compose cp n8n:/home/node/.n8n/wf-backup.json   ./wf-backup-$(date +%F).json
docker compose cp n8n:/home/node/.n8n/cred-backup.json ./cred-backup-$(date +%F).json
```

Useful for migrating between instances. Credentials remain encrypted —
the target instance needs the same `N8N_ENCRYPTION_KEY` to decrypt.

---

## Migrate SQLite to Postgres

You'll do this exactly once when graduating to production.

**Procedure:**

1. **Take a full backup** of the SQLite file (see above).
2. **Spin up a new instance** with `DB_TYPE=postgresdb` env, but DON'T
   point it at production traffic yet.
3. **Export from old (SQLite) instance:**

   ```bash
   docker compose exec n8n-old n8n export:workflow --all --output=/home/node/.n8n/wf.json
   docker compose exec n8n-old n8n export:credentials --all --output=/home/node/.n8n/cred.json
   docker compose cp n8n-old:/home/node/.n8n/wf.json   ./wf.json
   docker compose cp n8n-old:/home/node/.n8n/cred.json ./cred.json
   ```

4. **Import into new (Postgres) instance — with the SAME `N8N_ENCRYPTION_KEY`:**

   ```bash
   docker compose cp ./wf.json   n8n-new:/home/node/.n8n/wf.json
   docker compose cp ./cred.json n8n-new:/home/node/.n8n/cred.json
   docker compose exec n8n-new n8n import:credentials --input=/home/node/.n8n/cred.json
   docker compose exec n8n-new n8n import:workflow    --input=/home/node/.n8n/wf.json
   ```

5. **Verify** in the new instance: open a few workflows, check
   credentials, run a manual execution.
6. **Switch DNS / proxy** to the new instance.
7. **Decommission** the old instance only after a grace period.

Execution history doesn't migrate cleanly via `n8n export`. If you need it,
write a one-off Postgres copy script. Most teams accept losing historical
executions during this migration.

---

## Upgrade procedure

### Minor / patch upgrades (e.g., 1.78.0 → 1.78.5)

Generally safe. Procedure:

1. Read release notes: <https://github.com/n8n-io/n8n/releases>.
2. Back up DB.
3. Pull new image and restart:

   ```bash
   docker compose pull n8n
   docker compose up -d n8n
   docker compose logs -f n8n
   ```

4. Watch logs for migration errors. n8n auto-applies DB migrations on
   startup.
5. Smoke-test: open editor, run a manual execution.

### Minor upgrades within a major (e.g., 1.50 → 1.78)

Same procedure, but read release notes more carefully. Some minor versions
introduce breaking changes (the n8n team is good about marking them).
Test on staging first.

### Major upgrades (e.g., 0.x → 1.x)

Treat as a migration:

1. Back up everything.
2. Stand up a NEW instance on the target version with the SAME encryption
   key.
3. Export from old, import to new (see migration procedure above).
4. Verify all workflows and credentials behave as expected.
5. Switch traffic over.
6. Keep old instance read-only for a grace period.

### Queue mode upgrades

Upgrade order matters:

1. Stop accepting new workflow executions (briefly drain queue OR scale
   workers to 0 for an hour during off-peak).
2. Stop all workers.
3. Upgrade main process. Migrations run.
4. Upgrade workers and webhook services.
5. Resume.

This avoids version mismatches between main and workers (which can lock
up the queue or corrupt execution state).

---

## Rollback

If an upgrade fails:

1. **Stop** the new version.
2. **Restore** the database from the pre-upgrade backup.
3. **Start** the old image version against the restored DB.
4. **Verify** functionality.

Always pin image versions so rollback is just `image: n8nio/n8n:1.78.0` →
`image: n8nio/n8n:1.77.3` and `docker compose up -d`.

---

## Testing backups (do this!)

A backup you haven't restored is a hypothesis, not a backup. Quarterly:

1. Spin up a sandbox n8n instance with the SAME encryption key.
2. Restore database from your latest backup.
3. Confirm workflows open, credentials decrypt, and a smoke-test execution
   succeeds.
4. Document the procedure and timing.

---

## What survives across versions

| Item | Surviving |
|---|---|
| Workflows | Yes (with minor migrations applied automatically) |
| Credentials | Yes, as long as `N8N_ENCRYPTION_KEY` matches |
| Execution history | Mostly yes within a major version; sometimes pruned across majors |
| Webhook IDs | Yes (so external callers don't need to update URLs) |
| Custom community nodes | Need to be reinstalled (or pre-baked into the image) |
| Pinned data | Yes |

---

## Common upgrade pitfalls

### 1. "Database migration failed"

Usually a schema migration hit unexpected data (often left over from older
versions). Restore from backup, file an issue with n8n, try again.

### 2. Credentials all show "could not decrypt" after upgrade

Encryption key changed. Restore the original key.

### 3. Workflows missing custom community nodes

Custom nodes installed via the UI live in the data volume's
`/home/node/.n8n/nodes/`. They DO persist. But if you didn't reinstall
them in your custom Dockerfile (when using one), they're missing on the
new container.

### 4. Webhook URLs different after upgrade

Did `WEBHOOK_URL` env var change? Did the public domain change? If callers
hardcoded URLs, you may need to keep the old URL alive via the proxy.

### 5. Long-running executions abandoned during upgrade

Drain executions before upgrading. Queue mode: stop new dequeues, let
in-flight finish, then upgrade.
