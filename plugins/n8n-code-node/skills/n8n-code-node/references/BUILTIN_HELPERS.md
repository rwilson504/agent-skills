# Built-in Helpers (Code Node)

Quick reference for the variables, functions, and helpers available inside
the Code node. JavaScript-focused (Python uses `_`-prefixed equivalents).

> Authoritative reference: <https://docs.n8n.io/code/builtin/code-node-methods/>

---

## Data access

| Symbol | Returns |
|---|---|
| `$json` | Current item's `.json` (per-item mode) or first item's `.json` (all-items mode) |
| `$binary` | Current item's `.binary` map (per-item mode) |
| `$input.all()` | Array of incoming items |
| `$input.first()` | First incoming item |
| `$input.last()` | Last incoming item |
| `$input.item` | Current item (per-item mode) with pairedItem preserved |
| `$input.params` | This node's `parameters` |
| `$input.context` | Execution context — runIndex, etc. |

## Node access

| Symbol | Returns |
|---|---|
| `$('Node Name').first()` | First item from that node's output |
| `$('Node Name').last()` | Last item |
| `$('Node Name').all()` | All items |
| `$('Node Name').item` | Single item that paired-back to current item (throws if pairing broken) |
| `$('Node Name').itemMatching(idx)` | Item at index `idx` of that node's output |
| `$('Node Name').params` | That node's `parameters` |
| `$('Node Name').isExecuted` | `true` if that node ran on this execution |

`$node["Node Name"]` is a legacy alternative to `$('Node Name')`. Both work.

## Workflow / execution metadata

| Symbol | Returns |
|---|---|
| `$workflow.id` | Workflow id |
| `$workflow.name` | Workflow name |
| `$workflow.active` | `true` if active |
| `$execution.id` | Execution id |
| `$execution.mode` | `'manual'`, `'trigger'`, `'webhook'`, `'cli'`, `'retry'`, `'integrated'`, `'internal'` |
| `$execution.resumeUrl` | URL for Wait node's webhook-resume mode |
| `$execution.customData.get('key')` | Read per-execution custom data (visible in execution detail) |
| `$execution.customData.set('key', value)` | Write per-execution custom data |
| `$execution.customData.setAll({ ... })` | Bulk set |
| `$prevNode.name` | Upstream node name |
| `$prevNode.outputIndex` | Which output port we came from |
| `$prevNode.runIndex` | Iteration index |
| `$runIndex` | Current run iteration of this node |
| `$itemIndex` | Index of current item in input array |
| `$env.X` | Host env var (if `N8N_BLOCK_ENV_ACCESS_IN_NODE=false`) |
| `$vars` | Instance/project vars (Enterprise/Cloud) |
| `$secrets.<vault>.<key>` | External Secret (Enterprise) |

## Static data

| Symbol | Returns |
|---|---|
| `$getWorkflowStaticData('global')` | Mutable object persisted to DB per-workflow |
| `$getWorkflowStaticData('node')` | Same, scoped to this node |

Treat returned object as a mutable POJO. Set keys and let n8n save.

## Date / time (JS)

`DateTime`, `Duration`, `Interval` from Luxon are pre-imported.

```js
const dt = DateTime.fromISO('2026-01-01T00:00:00Z');
dt.toFormat('yyyy-MM-dd');                // '2026-01-01'
dt.plus({ days: 7 }).toISO();              // 7 days later in ISO
dt.diff(DateTime.now(), 'hours').hours;    // hours from now

DateTime.now();                            // current DateTime (server timezone)
DateTime.utc();                            // current DateTime in UTC
DateTime.fromMillis(1700000000000);

Duration.fromObject({ hours: 1, minutes: 30 }).toMillis();
Interval.fromDateTimes(a, b).length('days');
```

`$now` and `$today` are shorthand:
- `$now` = `DateTime.now()` in workflow timezone.
- `$today` = `$now.startOf('day')`.

Python equivalent: `from datetime import datetime, timezone, timedelta`
(no Luxon).

## JMESPath (JS)

```js
$jmespath($json, "items[?status=='active'].id")
$jmespath($json, "users[?age > `18`].name")
$jmespath($json, "{ names: users[*].name }")
```

JMESPath docs: <https://jmespath.org/>. Returns `null` for no match (not `[]`).

Python: use native dict/list comprehensions or install `jmespath` via
`micropip.install("jmespath")` and import normally.

## HTTP helpers (`this.helpers.*`)

```js
// Simple request
const data = await this.helpers.httpRequest({
  method: 'GET',
  url: 'https://api.example.com/v1/items',
  qs: { page: 1, limit: 100 },
  headers: { 'Accept': 'application/json' },
  json: true,                          // parse response as JSON
});

// With credential
const data = await this.helpers.httpRequestWithAuthentication.call(
  this,
  'httpHeaderAuth',                    // credential type id
  { method: 'GET', url: 'https://api.example.com/me', json: true }
);
```

Full options: <https://docs.n8n.io/code/builtin/code-node-methods/#httprequest>

## Binary helpers

```js
// Read
const buf = await this.helpers.getBinaryDataBuffer(itemIndex, binaryKey);

// Read as stream (for large files)
const stream = await this.helpers.getBinaryStream(itemIndex, binaryKey);

// Write
const binaryData = await this.helpers.prepareBinaryData(
  buffer,            // Buffer or string
  'filename.pdf',    // optional
  'application/pdf'  // optional MIME
);

return [{ json: {}, binary: { data: binaryData } }];
```

See [BINARY_DATA.md](BINARY_DATA.md) for streaming and conversions.

## Workflow control

```js
// Throw to halt execution with a clear message
throw new NodeOperationError(this.getNode(), 'Validation failed: missing email', { itemIndex: 0 });
```

`NodeOperationError` is globally available in Code nodes. The `itemIndex`
makes the error appear on the specific failing item in execution UI.

## Logging

```js
console.log('debug:', $json);   // Server-side log only
this.logger.info('msg', data);  // Same, with structured fields
```

Neither shows up in execution UI. To surface values in UI, return them in
output `json` or call `$execution.customData.set('key', value)`.
