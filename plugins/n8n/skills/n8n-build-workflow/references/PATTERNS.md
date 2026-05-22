# Patterns & Common Mistakes

Recipes that come up over and over, plus a catalog of mistakes to avoid.

---

## Patterns

### 1. Webhook with synchronous response

**Use when:** External caller needs the workflow's output in the HTTP response.

```
[Webhook (Respond: "Using Respond to Webhook Node")]
   → [process...]
   → [Respond to Webhook]
```

- Webhook node `responseMode` MUST be `"responseNode"`.
- Respond to Webhook lets you set status code, headers, and body
  (`={{ JSON.stringify({ ok: true, result: $json.result }) }}`).
- If any node throws before reaching Respond to Webhook AND no error
  workflow runs, the caller sees a generic 500. Wrap critical paths with
  `onError: "continueErrorOutput"` + a second Respond to Webhook on the
  error branch.

### 2. Webhook with async processing

**Use when:** Work takes >30s; caller just needs an ack.

```
[Webhook (Respond: "Immediately", responseData: "noData" or a JSON body)]
   → [background work...]
```

- Webhook acknowledges immediately with the configured response.
- Subsequent nodes run after the response is sent.
- If you need to notify the caller when work completes, build a callback
  URL into the original request body.

### 3. Loop with rate limit

```
[items] → [Loop Over Items (batchSize: 1)]
              → [HTTP Request to rate-limited API]
              → [Wait (1 second)]
              → back to Loop Over Items main output (port 0)
[Loop Over Items "done" output (port 1)] → [downstream]
```

- Split In Batches has two outputs: port 0 = each batch, port 1 = "done".
- Wire the end of the per-batch chain back to Split In Batches's input to
  continue iteration.
- `batchSize: 1` for strict serialization. Larger batches if the API supports
  it.

### 4. Error workflow handoff

**Setup once per instance** (or per workflow):

1. Build a separate workflow whose trigger is **Error Trigger**
   (`n8n-nodes-base.errorTrigger`).
2. In that error workflow, send the failure to Slack/PagerDuty/email using
   data from `$json.execution`:
   - `$json.execution.id`
   - `$json.execution.url`
   - `$json.execution.lastNodeExecuted`
   - `$json.execution.error.message`
   - `$json.execution.error.stack`
   - `$json.workflow.name`
3. Open the production workflow → Settings → "Error workflow" → select the
   error workflow. (Or set instance-wide default via the n8n UI.)

### 5. Idempotency with Remove Duplicates

**Use when:** Upstream feed may replay items.

```
[Source] → [Remove Duplicates (compareBy: "specificField", field: "id", scope: "withinExecution")]
        → [process]
```

For dedup ACROSS executions, use scope `"acrossExecutions"` — n8n persists
seen-IDs in workflow static data. Cap with `maxItems` to avoid unbounded
growth.

### 6. Aggregate then summarize

```
[fetched items] → [Aggregate (groupBy: "category", aggregations: count, sum, avg)]
               → [Summarize (groupBy: "category", fields: ...)]
               → [send report]
```

Aggregate groups into single items per group. Summarize gives you
statistical aggregations. Combine when you need both.

### 7. Pagination — built-in or manual

**Built-in (preferred where supported):** HTTP Request node → Options →
Pagination → select strategy (Response Contains Next URL, Update a Parameter
in Each Request, Receive Response Page Header).

**Manual with static data:**

```js
// Code node
const data = $getWorkflowStaticData('global');
const cursor = data.cursor || null;
return [{ json: { cursor } }];
```

```
[Code: read cursor] → [HTTP Request] → [Code: save new cursor]
```

### 8. Branching to a sub-workflow

```
[main] → [Execute Sub-workflow (workflowId, parameters)]
       → [downstream uses sub-workflow's returned items]
```

Sub-workflow needs **Execute Sub-workflow Trigger** as its starter. The
trigger receives an item whose `json` contains the parameters you passed.

### 9. Fan-out without rate limit (parallel branches)

```
[item] → [HTTP A]
      → [HTTP B]
      → [HTTP C]
      ↓
   [Merge (combineByPosition)]
      → [combined item]
```

Three branches execute in parallel (n8n's modern `executionOrder: "v1"` runs
non-conflicting branches concurrently). Merge with `combineByPosition` so
the outputs land in one item.

### 10. Human-in-the-loop with Wait → Resume Webhook

```
[generate proposal] → [send to reviewer via Slack with approval URL containing $execution.resumeUrl]
                   → [Wait (mode: "Webhook")]
                   → [continue with reviewer's response in $json]
```

`Wait` with `resume: "webhook"` pauses execution and exposes
`$execution.resumeUrl`. Hit it (with a request body) to resume; the body
becomes the next node's input.

---

## Common mistakes

### 1. Manual Trigger in production

**Symptom:** Workflow imported, activated, never fires.
**Cause:** Manual Trigger only runs when a user clicks "Execute Workflow".
**Fix:** Replace with Schedule, Webhook, App trigger, or Form Trigger.

### 2. Wrong typeVersion → import fails or parameters disappear

**Symptom:** "Node type not found" or node loads but parameters are blank.
**Cause:** `typeVersion` doesn't match what's installed on the target
instance.
**Fix:** Set `typeVersion` to the version available on the instance. Drag
the node into a fresh editor to check the current version.

### 3. Connection names don't match node names

**Symptom:** Import succeeds but no wires render between nodes; execution
"completes" instantly.
**Cause:** `connections.<sourceName>` uses a name that doesn't appear in
`nodes`. Often a typo or a renamed node.
**Fix:** Connection keys/values must EXACTLY match node `name` fields.

### 4. UUID collisions or non-UUIDs

**Symptom:** Import accepted but execution history is confused; nodes
appear duplicated.
**Cause:** Two nodes share an `id`, or `id` isn't a valid UUID v4.
**Fix:** Regenerate IDs with a proper UUID v4 generator.

### 5. Pinned data shipped to production

**Symptom:** Workflow always returns the same canned data regardless of
input.
**Cause:** `pinData` was left in the exported JSON.
**Fix:** Strip the `pinData` object before sharing or importing into
production. (Or, in the editor, right-click each pinned node → Unpin.)

### 6. Webhook returns empty body

**Symptom:** Caller gets 200 OK with empty body even though the workflow
processed data.
**Cause:** Webhook `responseMode: "lastNode"` returns the last node's output,
but the last node is a side-effect node (Slack, Postgres write) that
doesn't return user-facing data.
**Fix:** Either add a Set node at the end that shapes the response payload,
or switch to `responseMode: "responseNode"` + Respond to Webhook.

### 7. IF / Switch sends nothing downstream

**Symptom:** True branch fires when you expected false (or nothing fires).
**Cause:** Output ports are index-based — IF: 0 = true, 1 = false. Switch:
order matches rule order. Connecting to the wrong index sends data to the
wrong branch.
**Fix:** Re-verify `connections.<IfNode>.main[0]` vs `[1]`.

### 8. Loop Over Items never completes

**Symptom:** Workflow seems stuck in a loop or processes only some items.
**Cause:** The end of the per-batch chain didn't wire back to Loop Over
Items's input. Each batch runs once and "done" never fires.
**Fix:** Wire the last node in the per-batch chain back to the Loop Over
Items node's main input. The "done" output (port 1) then fires after all
batches.

### 9. Item pairing breaks → `$('Node').item` throws

**Symptom:** "Could not find paired item" error.
**Cause:** A Code node or custom transformation dropped `pairedItem` from
its returned items.
**Fix:** See [DATA_STRUCTURE.md](DATA_STRUCTURE.md) and the
[n8n-code-node](../../n8n-code-node/SKILL.md) skill.

### 10. Credentials missing after import

**Symptom:** Yellow warning triangles on nodes; execution fails immediately
with "Credentials not found".
**Cause:** Workflow JSON references credentials by `id`, but those IDs only
exist on the source instance.
**Fix:** After import, open each warning-flagged node and select the
correct credential from the dropdown. (Or use Source Control / Variables
for credential ID portability across environments — Enterprise only.)

### 11. Wait node forgotten in cron alignment

**Symptom:** A Schedule-triggered workflow runs at slightly different
times each day or skips a day.
**Cause:** Schedule Trigger's "Interval" mode is anchored to instance
boot/restart time. The "Cron Expression" mode is anchored to wall-clock.
**Fix:** Use Cron Expression mode for predictable wall-clock schedules.

### 12. `$json` in HTTP Request body field returns "[object Object]"

**Symptom:** API receives a body of literal text `[object Object]`.
**Cause:** Wrote `={{ $json }}` (no JSON.stringify) in the body field set to
"JSON" type, OR forgot to set the body type to "JSON" / "Form Data".
**Fix:** Either set body parameter type to "JSON" and let n8n stringify
automatically, or expression `={{ JSON.stringify($json) }}` if you must.
