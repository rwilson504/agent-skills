# Rate Limits

How to recognize, recover from, and prevent rate-limit failures in n8n.

---

## Recognizing a rate limit

| Symptom | Likely meaning |
|---|---|
| HTTP 429 response | Standard "too many requests" |
| HTTP 503 with `Retry-After` header | Service rate-limit (vs. infra outage) |
| HTTP 200 with `{ "error": "rate limit exceeded" }` body | Some APIs (e.g. Notion) return 200 with error in body |
| Random `ECONNRESET` clusters during a burst | Server-side throttling that drops connections |
| Increased latency under load with eventual `ETIMEDOUT` | Throttling via slowdown |

---

## Immediate recovery (1-minute fix)

On the offending HTTP/app node, set:

```
retryOnFail:      true
maxTries:         5
waitBetweenTries: 30000   (30 seconds)
```

n8n will catch the error, wait, retry. For most APIs this is enough to
absorb transient bursts.

---

## Proper fix (architectural)

### Pattern 1 — Loop Over Items with Wait

When you need to make N calls and the API allows R calls per minute:

```
[items] → [Loop Over Items (batchSize: 1)]
              → [HTTP Request]
              → [Wait (60/R seconds)]
              → back to Loop Over Items
[Loop Over Items "done" output] → [downstream]
```

- `batchSize: 1` for strict serialization.
- Wait amount = 60/R seconds for "R per minute" limits.
- For "R per second" limits, use `batchSize: R` and `Wait: 1 second`.

### Pattern 2 — Use built-in HTTP Request batching

HTTP Request → Options → **Batching**:

```
Items per Batch: 5
Batch Interval:  1000   (ms)
```

n8n executes the node in batches, sleeping between batches. Cleaner than
manual Loop Over Items but only works on a single HTTP node.

### Pattern 3 — Honor `Retry-After`

Many APIs return a `Retry-After` header (seconds) on 429. Use a Code node:

```js
// In a Code node placed on the error branch of HTTP Request
const retryAfter = parseInt($input.first().json.error?.headers?.['retry-after'] ?? '60');
await new Promise(r => setTimeout(r, retryAfter * 1000));
return $input.all();
```

Then loop the output back to the HTTP Request node's input.

### Pattern 4 — Queue mode with concurrency control

In queue mode, set `N8N_CONCURRENCY_PRODUCTION_LIMIT=5` (workers) to cap the
number of concurrent executions. Useful when many independent workflows hit
the same rate-limited API and per-workflow Loops aren't enough.

---

## Common rate-limit gotchas

### 1. App nodes have their own internal retry

Some app nodes (Slack, Google services) already have a built-in retry on
429. Stacking `retryOnFail` on top can give you "5 retries × N internal
retries" = exponential delay.

**Detection:** debug log shows the API call retried more than `maxTries`
times.

**Fix:** Pick ONE retry layer. Usually the built-in is better-tuned.

### 2. Test URL vs Production URL for webhooks

If you're using a third-party API's webhook for testing (e.g. Stripe Test
mode), its rate limits may be different (often higher) than production.
Don't generalize from test-mode performance.

### 3. Per-user vs per-app vs per-IP limits

Some APIs (Google Workspace, Microsoft Graph) apply limits per user. If your
workflow rotates through 10 users, you effectively have 10× the per-user
limit but ONE per-app limit. Read the docs.

### 4. Rate limits change with API tier

Free tier: 60 rpm. Paid: 600 rpm. Make sure the credential is for the
expected tier.

### 5. "Burst" vs "sustained" limits

Many APIs allow N rapid calls then enforce M per minute sustained. A
front-loaded loop hits the burst limit then 429s for the rest. Smooth the
rate with `Wait` even if the per-minute average is under quota.

### 6. Workflow concurrency stacks

If a Webhook-triggered workflow can be called concurrently AND each
invocation calls a rate-limited API, you're not limited by your Loop Over
Items — you're limited by the concurrency of callers. Add an instance-wide
queue (queue mode + `N8N_CONCURRENCY_PRODUCTION_LIMIT`) or move the call
to a sub-workflow with `executeOnce` semantics if dedupe is possible.

---

## Detecting silent throttling

Some APIs don't 429; they just slow down. To detect:

- Add a Code node before/after the HTTP Request that logs duration:
  ```js
  console.log(`${$execution.id} ${$now.toISO()} HTTP duration: ${$('HTTP Request').first().json.duration}ms`);
  return $input.all();
  ```
- Compare avg duration during low vs high traffic windows.

If high-traffic duration grows linearly with concurrency, you're being
throttled. Drop to a single-request stream with Wait.

---

## Backoff with jitter (custom)

For "thundering herd" scenarios (workflow restarts after instance reboot,
all retried executions hit the API simultaneously), add jitter:

```js
// Code node in error branch
const baseDelay = 30000;
const jitter = Math.random() * 15000;
await new Promise(r => setTimeout(r, baseDelay + jitter));
return $input.all();
```
