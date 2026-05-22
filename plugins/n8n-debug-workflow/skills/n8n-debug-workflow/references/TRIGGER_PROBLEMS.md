# Trigger Problems

Triggers that never fire, fire twice, fire late, or fire but with wrong
data.

---

## Webhook problems

### Webhook never fires

- **Workflow inactive.** Toggle active.
- **Wrong URL.** Two URLs per Webhook node:
  - **Test URL** (`/webhook-test/<path>`) — works only while editor open
    AND "Listen for Test Event" is running.
  - **Production URL** (`/webhook/<path>`) — works when workflow is active.
- **`WEBHOOK_URL` env mismatch.** On self-hosted, n8n reports webhook URLs
  based on `WEBHOOK_URL` env. If callers hit a different URL (different
  domain, port, path), the request goes nowhere.
- **Path collision.** If two active workflows have webhooks with the same
  path AND method, activation of the second fails. Check editor warnings.
- **Reverse proxy strips path.** If n8n sits behind nginx/Traefik that
  rewrites `/n8n/*` → `/*`, the webhook path n8n registers won't match what
  callers hit. Configure the proxy to preserve the path or set
  `N8N_PATH=/n8n/` on n8n.

### Webhook fires twice

- **Caller retries.** Most webhooks (Stripe, GitHub) retry on non-2xx
  responses. Make sure the workflow returns 2xx fast (use
  `responseMode: "onReceived"` for slow workflows).
- **Two active workflows on the same path with different HTTP methods.**
  POST and GET don't collide; verify the caller's method matches what you
  configured.
- **Loadbalancer in front of n8n** routing to multiple instances that ALL
  process the same callback (queue mode misconfiguration). Configure
  `EXECUTIONS_MODE=queue` and use a single workflow-runner pool.

### Webhook returns wrong response

| Issue | Fix |
|---|---|
| 200 OK with empty body | Check `responseMode` and Respond to Webhook config |
| 200 OK with `[object Object]` body | `={{ $json }}` without `JSON.stringify` — set body type to JSON |
| 500 to caller | Workflow threw before reaching Respond to Webhook. Add error branch |
| Times out caller | Workflow took >caller's timeout. Use `responseMode: "onReceived"` |
| Wrong Content-Type | Set Respond to Webhook → Headers → `Content-Type` explicitly |

### Webhook receives different data than expected

- **Webhook node parses body based on `Content-Type`.** If caller sends
  `application/x-www-form-urlencoded` but you expected JSON, the parser
  shape differs. Webhook node has a "Binary Property" option for raw bodies.
- **Multipart uploads** land in `$json.body` for fields and `$binary.<key>`
  for files.
- **Query string** is at `$json.query`, not `$json.body`.
- **Headers** at `$json.headers` (lowercase keys).

---

## Schedule Trigger problems

### Doesn't fire

- **Workflow inactive.** Toggle.
- **Trigger node was deleted then re-added without re-activating.** The
  workflow can be in a half-state where the trigger isn't registered.
  Deactivate → activate.
- **Queue mode with no worker.** Main process doesn't execute by itself
  in queue mode. Make sure at least one worker is up.

### Fires at wrong time

- **Timezone.** Schedule respects `settings.timezone` on the workflow,
  falling back to instance env `GENERIC_TIMEZONE`. Both default to UTC if
  unset.
- **Interval mode vs Cron mode.**
  - **Interval** (e.g. "every 1 hour") anchors to the time the workflow was
    last activated/instance restarted.
  - **Cron** (e.g. `0 9 * * *`) anchors to wall-clock in the workflow
    timezone. Use Cron for predictable schedules.

### Skips runs

- **Instance/worker downtime.** n8n doesn't backfill missed runs.
- **Two instances running with the same DB but no queue mode.** Both try
  to fire the schedule; one wins, but if neither is healthy at fire time,
  the run is missed.
- **Schedule frequency below n8n's tick rate.** Sub-second schedules
  aren't supported.

---

## App trigger problems (Slack, Gmail, GitHub, etc.)

### Trigger never fires

- **OAuth token expired.** Re-authenticate in Credentials.
- **Webhook URL not registered with the upstream app.** Most app triggers
  auto-register via OAuth, but some (legacy Slack Events, custom GitHub
  webhooks) need manual setup. Check the node's "Activate" output.
- **Workflow inactive.** App triggers register their webhooks with the
  upstream service only when activated. Inactive = no webhook = no events.

### Fires for wrong events

- **Subscribed to too broad a filter.** Most app triggers have filter
  parameters (channel, label, repository). Tighten.
- **Multiple workflows subscribed to the same event source.** Each fires
  independently. Consider funneling into one workflow that branches.

---

## Form Trigger problems

### Form 404s

- Workflow inactive, OR the Form Trigger path conflicts with another. Same
  rules as Webhook.

### Form submission lost

- The Form Trigger has a "Respond" mode (return a thank-you page) and a
  "Respond to Form" mode (you return a response from elsewhere). Confusing
  the two leaves submissions in limbo.

---

## Chat Trigger problems

### Chat widget says "could not connect"

- Self-hosted: ensure CORS allows the embedding domain. Set
  `N8N_PUSH_BACKEND=websocket` and verify the chat URL is reachable from
  the browser.
- Cloud: ensure the workflow is active and the Chat Trigger is configured
  to allow public/embedded access (vs authenticated-only).

### Chat doesn't remember context

- Memory sub-node missing from the AI Agent.
- Memory's `sessionId` not derived from the chat session (defaults to
  "default", so all users share one memory).

---

## Execute Sub-workflow Trigger problems

### "Workflow not found" when calling

- Sub-workflow not saved, or `callerPolicy` blocks the caller. Check the
  sub-workflow's Settings → "Who can call this workflow" → make sure caller
  is allowed.

### Sub-workflow returns wrong data

- Execute Sub-workflow Trigger receives ONE item whose `json` contains
  the fields passed by the parent. To return multiple items, return an
  array from the last node of the sub-workflow.
- The parent's Execute Sub-workflow node returns the LAST node's output of
  the sub-workflow.
