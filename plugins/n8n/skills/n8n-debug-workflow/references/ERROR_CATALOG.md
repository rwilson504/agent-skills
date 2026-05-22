# Error Catalog

Indexed n8n error messages → root cause → fix. Search this file for the
exact message the user pasted.

---

## API & transport

### `ECONNREFUSED` / `ENOTFOUND` / `EAI_AGAIN`

- **Cause:** DNS or network failure reaching the target host.
- **Fix:** Check hostname, VPN/firewall, DNS resolver. From the n8n host:
  `curl -v https://api.example.com`. For self-hosted, verify DNS config in
  the container.

### `ETIMEDOUT` / `ESOCKETTIMEDOUT`

- **Cause:** API took longer than the HTTP timeout.
- **Fix:** Increase HTTP Request → Options → Timeout (default 300000ms).
  Consider async pattern: kick off, return a job ID, poll separately.

### `Request failed with status code 401`

- **Cause:** Auth failed. Token expired, wrong scope, wrong credential
  selected.
- **Fix:** Re-authenticate the OAuth credential (Credentials → open →
  Reconnect). For API keys, verify the key hasn't been rotated. For OAuth2,
  check `Refresh token` is still valid.

### `Request failed with status code 403`

- **Cause:** Auth succeeded but caller lacks permission.
- **Fix:** Check scopes granted at OAuth consent. For service accounts,
  verify the principal has the required role on the target resource.

### `Request failed with status code 404`

- **Cause:** URL wrong, resource doesn't exist, OR API base URL changed.
- **Fix:** Verify URL in expression evaluates correctly (use Execute Node
  → output panel to see resolved URL). Some app nodes pin a base URL that
  may have been deprecated by the vendor.

### `Request failed with status code 429`

- **Cause:** Rate limited.
- **Fix:** See [RATE_LIMITS.md](RATE_LIMITS.md). Quick fix: enable
  `retryOnFail`, `maxTries: 5`, `waitBetweenTries: 30000`.

### `Request failed with status code 500` / `502` / `503` / `504`

- **Cause:** Upstream server problem — transient (502/503/504) or persistent
  (500).
- **Fix:** Enable `retryOnFail` for transient codes. For 500s, capture the
  response body (HTTP Request → Options → Response → Include Full Response)
  and inspect what the server said.

### `unable to verify the first certificate` / `self signed certificate`

- **Cause:** Target uses a private CA or self-signed cert.
- **Fix:** For self-hosted, set env `NODE_TLS_REJECT_UNAUTHORIZED=0` (NOT
  for production!) or mount the CA cert and set
  `NODE_EXTRA_CA_CERTS=/path/to/ca.crt`. In HTTP Request, the per-node
  "SSL/TLS → Ignore SSL Issues" toggle exists but is also unsafe for
  production.

---

## Expression errors

### `Cannot read properties of undefined (reading 'X')`

- **Cause:** An expression like `$json.foo.bar` ran when `$json.foo` was
  undefined.
- **Fix:** Use optional chaining: `={{ $json.foo?.bar ?? 'fallback' }}`.

### `Cannot read properties of null (reading 'X')`

- **Cause:** Field exists but is `null`.
- **Fix:** `={{ ($json.foo ?? {}).bar }}` or `={{ $json.foo?.bar }}`.

### `ReferenceError: X is not defined`

- **Cause:** Used an unknown variable name. Common: `item` instead of `$json`,
  `node` instead of `$node`, or a typo.
- **Fix:** Verify built-in name. See [EXPRESSIONS.md](../../n8n-build-workflow/references/EXPRESSIONS.md).

### `Could not find paired item`

- **Cause:** Tried `$('UpstreamNode').item` and pairing was broken.
- **Fix:** See [ITEM_LINKING_ERRORS.md](ITEM_LINKING_ERRORS.md).

### `[Workflow data error]: No data attached to node ...`

- **Cause:** Referenced a node that hasn't executed yet on this branch.
- **Fix:** Restructure so the referenced node runs first, OR use
  `$('Node').isExecuted` to guard.

### `Expression resolves to nothing`

- **Cause:** Expression returned `undefined` and the parameter requires a
  value.
- **Fix:** Add a `?? 'default'` fallback or use a Set node to provide a
  guaranteed value upstream.

### `JSON parameter must be valid JSON`

- **Cause:** A JSON parameter (e.g. HTTP Request body in JSON mode)
  evaluated to a non-JSON string.
- **Fix:** If you intend an object, set the parameter type to "JSON" and
  pass `={{ { foo: $json.x } }}` (no quotes — n8n stringifies). If passing
  a pre-formatted string, ensure it's valid JSON.

---

## Workflow / execution errors

### `Workflow has no trigger`

- **Cause:** No trigger node in the workflow.
- **Fix:** Add a trigger (Manual, Schedule, Webhook, App, Form, Chat, Error
  Trigger, or Execute Sub-workflow Trigger).

### `Workflow timed out after X seconds`

- **Cause:** Workflow ran longer than `executionTimeout` (workflow setting)
  or `EXECUTIONS_TIMEOUT` (instance env, default 3600 seconds).
- **Fix:** Either optimize the workflow or bump the timeout. For very
  long-running work, refactor to async pattern with a Wait node or
  sub-workflow chain.

### `Cannot read properties of undefined (reading 'main')`

- **Cause:** Connection references a node `name` that doesn't exist (often
  after a rename or partial export).
- **Fix:** Audit `connections` keys/values against `nodes[].name`. Every
  reference must match exactly (case-sensitive).

### `Execution stopped because the workflow has been deactivated`

- **Cause:** Workflow was deactivated mid-execution.
- **Fix:** Reactivate. Active executions DO complete; only NEW triggers are
  blocked while inactive.

### `Out of memory` / process killed

- **Cause:** Node loaded too much data into memory at once. Common with
  large file binary, large JSON arrays from a DB query, or unbounded
  pagination.
- **Fix:** Use Loop Over Items (Split In Batches) to stream. For binary,
  switch to filesystem-backed mode
  (`N8N_DEFAULT_BINARY_DATA_MODE=filesystem`).

### `Database is locked` (SQLite)

- **Cause:** Default SQLite database can't handle concurrent writes.
- **Fix:** Migrate to Postgres. See [n8n-self-host](../../n8n-self-host/SKILL.md).

---

## Webhook errors

### `Webhook not registered`

- **Cause:** Workflow not active, OR webhook path conflicts with another
  active workflow.
- **Fix:** Activate the workflow. If "webhook path already exists" appears
  on activation, change the path or deactivate the other workflow.

### Webhook returns 404 on Production URL

- **Cause:** Workflow inactive, or `WEBHOOK_URL` env var misconfigured on
  self-hosted (n8n returns URLs based on this env var; if it doesn't match
  what callers hit, registration is offset).
- **Fix:** Activate the workflow. For self-hosted, ensure `WEBHOOK_URL`
  matches the public URL (including trailing slash).

### Webhook hangs and times out caller

- **Cause:** `responseMode: "lastNode"` is waiting for the workflow to
  finish, but the workflow runs longer than the caller's HTTP timeout.
- **Fix:** Either switch to `responseMode: "onReceived"` (respond
  immediately, do work in background) or `responseMode: "responseNode"`
  (use Respond to Webhook explicitly mid-flow).

---

## Schedule / cron errors

### Schedule fires at wrong wall-clock time

- **Cause:** Timezone mismatch between workflow `settings.timezone`,
  instance `GENERIC_TIMEZONE`, and the OS.
- **Fix:** Set workflow `settings.timezone` explicitly. Verify instance env
  `GENERIC_TIMEZONE=America/New_York` (or your zone).

### Schedule skips runs

- **Cause:** Instance restart or worker downtime in queue mode misses the
  scheduled tick. n8n doesn't catch up missed runs.
- **Fix:** Ensure scheduler runs continuously. For zero-tolerance jobs, add
  a "missed run detector" — a separate Schedule Trigger that checks "did
  the last run land within tolerance" and alerts if not.

---

## Credentials

### "Credentials not found"

- **Cause:** Workflow JSON references a credential ID that doesn't exist on
  this instance.
- **Fix:** Open the node, pick the correct credential from the dropdown.
  For team workflows, use Source Control + Variables (Enterprise) for
  portable credential IDs.

### OAuth token expired

- **Cause:** Refresh token revoked or stale.
- **Fix:** Credentials → open the credential → Reconnect.
