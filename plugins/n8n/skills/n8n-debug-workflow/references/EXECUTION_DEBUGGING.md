# Execution Debugging

How to read an n8n execution log, understand run modes, and chase stalls
and resource issues.

---

## Reading an execution

In the Editor → **Executions** tab → click an execution.

| UI element | What it tells you |
|---|---|
| Status badge | `Success` / `Error` / `Running` / `Crashed` / `Canceled` |
| Mode | `manual` (you clicked Execute), `trigger`, `webhook`, `cli`, `retry`, `integrated`, `internal` |
| Duration | Wall-clock time. Long durations are often a Wait node, a long-running HTTP call, or a Loop Over Items |
| Red node | The first failing node. Click to see input data, output data, and the error |
| Yellow node | Skipped (branch wasn't taken) |
| Gray node | Not executed (branch never reached) |
| Green node | Succeeded |
| Item count badge | Number of items the node output |

**Always click both the failing node AND the immediately-upstream node.**
The error message names the failing node but the bad data often originated
upstream.

### Input vs Output panes

- **Input** — what came IN to this node from upstream. Empty input is a
  common cause of "nothing happens" — verify upstream actually produced
  data on this branch.
- **Output** — what this node produced. For a failed node, this is empty.
  For a succeeded node, this is what downstream sees.
- **Toggle** between **Schema** view (shapes the data structure for
  expression-writing) and **JSON/Table** view (raw).

---

## Run modes

Most app nodes and the Code node have a "Run Mode" selector. Misunderstanding
this is a top-5 source of "data wrong" bugs.

### "Run Once for All Items"

- Node executes ONCE.
- Receives the full array of input items.
- Inside expressions, `$json` refers to the FIRST item only.
- Use `$input.all()` to access all items.
- Faster for batch-friendly APIs.

### "Run Once for Each Item"

- Node executes N times (once per input item).
- Each execution sees its own item; `$json` is the current item.
- Slower (N HTTP calls instead of 1) but simpler when expressions reference
  `$json`.
- Default for many modern app nodes.

### "Run Item Only Once" (subtle)

A few nodes have a third option that prevents re-execution within a single
run even if upstream sends the same item multiple times. Useful for
idempotency on side-effect nodes.

---

## Stalled executions

### Symptom: workflow shows "Running" indefinitely

**Common causes:**

1. **A Wait node** is waiting for a webhook resume that never comes. Check
   the Wait node's `resumeUrl` — if no one hits it, the execution waits
   forever (or until `executionTimeout`).
2. **Long HTTP call** with no timeout configured. The default is 300s but
   some node versions inherit no timeout. Set HTTP Request → Options →
   Timeout explicitly.
3. **Infinite loop** in a Loop Over Items chain that never reaches the
   "done" output. Verify the loop wires back to the Split In Batches input.
4. **Queue mode worker died** mid-execution. The main process shows
   "Running" but no worker is actually processing. Check worker logs.
5. **Database deadlock** writing execution state. Symptoms in n8n logs:
   "deadlock detected" (Postgres) or "database is locked" (SQLite). Switch
   to Postgres if you're on SQLite.

**Fixes:**

- Set workflow-level `executionTimeout` to a sane ceiling (e.g. 1800s).
- Set instance-level `EXECUTIONS_TIMEOUT_MAX=3600` to cap.
- Cancel the stuck execution from the Executions tab (red X icon).

---

## Resource issues

### Memory spikes

**Common causes:**

- Loading a large file in binary mode without filesystem backing.
- A node returns 100k+ items from a DB query.
- A Code node accumulates state across items.

**Fixes:**

- Set `N8N_DEFAULT_BINARY_DATA_MODE=filesystem` (or `s3`) so large binaries
  spill to disk.
- Use Loop Over Items (Split In Batches) with a small batch size to stream
  through large datasets.
- Inspect the Code node — replace per-item array push with streaming
  emit (return per-iteration items in a Run Once for Each Item Code node
  instead of buffering in a Run Once for All Items one).

### CPU pegged

- Usually a Code node with an O(n²) loop over a large input.
- Or a JS regex with catastrophic backtracking.
- Profile: cut the input to one item and time the Code node; cut to 10 and
  see if time scales linearly or super-linearly.

### Disk fills up

- Execution data is persisted by default (`EXECUTIONS_DATA_SAVE_*` env
  vars). With long retention and busy workflows, this grows fast.
- Set `EXECUTIONS_DATA_PRUNE=true` and `EXECUTIONS_DATA_MAX_AGE=336` (hours,
  i.e. 14 days) to auto-prune.
- For binary data on filesystem mode, also set
  `N8N_BINARY_DATA_TTL=1440` (minutes) to expire orphaned binaries.

---

## Useful instance env vars for debugging

| Env var | Effect |
|---|---|
| `N8N_LOG_LEVEL=debug` | Verbose logs (use temporarily) |
| `N8N_LOG_OUTPUT=console,file` | Log to file too |
| `N8N_LOG_FILE_LOCATION=/path/to/logs` | Where to write log files |
| `DB_LOGGING_ENABLED=true` | Log SQL queries (very verbose) |
| `N8N_METRICS=true` | Expose Prometheus metrics on `/metrics` |
| `EXECUTIONS_TIMEOUT=3600` | Default per-execution timeout (seconds) |
| `EXECUTIONS_TIMEOUT_MAX=7200` | Hard ceiling users can set |
| `EXECUTIONS_DATA_SAVE_ON_ERROR=all` | Always keep error execution data |
| `EXECUTIONS_DATA_SAVE_ON_SUCCESS=all` | Keep success too (heavy) |

---

## Pin Data — the debugger's best friend

Pin Data captures a node's output and replays it on future manual
executions, so you can iterate on downstream nodes without re-firing the
trigger or re-calling an external API.

### Pin from the editor

Right-click on a node's output panel → **Pin Data**. The node now shows a
small pin icon. Subsequent manual executions use the pinned data instead
of re-executing the node.

### Pin in workflow JSON

```json
"pinData": {
  "Webhook": [
    { "json": { "body": { "user": "alice" }, "headers": {}, "query": {} } }
  ]
}
```

### Strip before production

Pinned data ships with workflow exports. Always strip `pinData` before
production import or you'll get canned responses forever. (Or right-click
→ Unpin in the editor.)

---

## "Run from this Node"

Right-click any node → **Execute Node** runs ONLY that node using current
upstream data. Right-click → **Run from this Node** starts a fresh
execution from that node onward, using whatever's pinned or what previous
nodes already produced.

Use case: debugging a chain of transformations after pinning the trigger's
output.

---

## Replaying executions

Editor → Executions tab → open a failed execution → **Retry execution**
button (top right). Two options:

- **Original Workflow** — replays with the workflow as it was when the
  execution originally ran (good for "is this still broken" sanity checks).
- **Current Workflow** — replays with the latest saved workflow (good for
  testing your fix on the original input data).
