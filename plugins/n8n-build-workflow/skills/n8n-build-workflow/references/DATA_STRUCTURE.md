# Data Structure

n8n moves an **array of items** between nodes. Internalize this model — most
"why doesn't this work" questions trace back to misunderstanding it.

> Authoritative reference: <https://docs.n8n.io/data/data-structure/>

---

## The item

```json
{
  "json":   { /* arbitrary JSON payload */ },
  "binary": { /* optional: map of named binary attachments */ },
  "pairedItem": { /* optional: links back to source items */ }
}
```

### `json`

User-visible data. Any JSON value (object, array, primitive — though
top-level is almost always an object). This is what `$json` refers to inside
expressions and Code nodes.

### `binary`

Optional. Keyed map of binary attachments. Each value:

```json
"data0": {
  "data":          "<base64 string>",     // raw bytes
  "mimeType":      "application/pdf",
  "fileName":      "report.pdf",
  "fileExtension": "pdf",
  "directory":     "/tmp/uploads"          // optional, when on disk
}
```

In modern n8n, binary data may also be **filesystem-backed** (configured via
`N8N_DEFAULT_BINARY_DATA_MODE=filesystem` or `s3`) — the in-memory `data`
field becomes a pointer, and you read it via the Binary Data API. Most node
authors should NOT touch raw `data` — use `this.helpers.getBinaryDataBuffer()`
in node code, or just let the next node consume the binary key by name.

### `pairedItem`

Optional but **critical**. Tells n8n which upstream item(s) this item was
derived from. Allows `$('UpstreamNode').item` to walk back through the graph
and find the right source item even after multiple intermediate nodes.

Shapes:

```json
// Single source item from previous node
"pairedItem": { "item": 0 }

// Source from a specific named upstream node (multi-input scenarios)
"pairedItem": { "item": 0, "sourceOverwrite": { "previousNode": "Webhook" } }

// Multiple source items (e.g. after a Merge or aggregation)
"pairedItem": [{ "item": 0 }, { "item": 1 }]
```

If `pairedItem` is missing, downstream `$('Node').item` calls will throw
"Could not find paired item".

---

## Cardinality between nodes

A node receives an array of items and outputs an array of items. The
cardinality relationship varies by node:

| Pattern | Behavior |
|---|---|
| **1 → 1** | One output item per input item (Set, HTTP Request "Each Item", most app nodes by default) |
| **1 → N** | Each input item produces multiple output items (HTTP Request with pagination, Item Lists → Split Out) |
| **N → 1** | All input items collapsed into one (Aggregate, Summarize when grouping) |
| **N → M** | Arbitrary (Code node, Merge with SQL Query) |

When 1 → N, the new items should have `pairedItem: { item: <indexOfSource> }`
pointing back at their source input item. When N → 1, the output item should
have `pairedItem: [{ item: 0 }, { item: 1 }, ...]` pointing at all sources.

Built-in nodes handle this automatically. Code nodes do NOT — see
[n8n-code-node](../../n8n-code-node/SKILL.md) for the canonical pattern.

---

## "Run Once for All Items" vs "Run Once for Each Item"

Most app nodes (HTTP Request, Slack, Postgres, etc.) and the Code node have
a mode selector:

- **Run Once for All Items** (default for many) — the node executes ONCE,
  receives the entire item array, and is responsible for fan-out internally.
- **Run Once for Each Item** — the node executes N times (once per item).
  Slower but simpler when expressions reference `$json`.

For HTTP Request specifically, modern typeVersions execute "Once for Each
Item" by default and parallelize internally with the **Batching** options.

---

## Empty input handling

If a node receives **zero items**, what happens depends on the node:

- Most app nodes: do nothing, output zero items, downstream gets nothing.
- `alwaysOutputData: true` on the node: outputs one item with `{}` even when
  input is empty, so downstream can still run.
- Loop Over Items with zero items: skips iteration entirely; "done" output
  still fires.

Plan for the zero-items case in any production workflow.

---

## Multiple inputs (Merge)

The Merge node has multiple input ports. Its `parameters.mode` controls
combination:

| Mode | What happens |
|---|---|
| `append` | Output = Input1 items, then Input2 items (concatenation) |
| `combineByPosition` | Output[i] = merge(Input1[i], Input2[i]) — like a zip |
| `combineByKey` | SQL-style join on a key field present in both inputs |
| `combineBySql` | Run a SQL query treating inputs as tables `input1` and `input2` |
| `combineAll` | Cartesian product |
| `chooseBranch` | Pick one input or the other based on a condition |

When merging, `pairedItem` of the output items references items from BOTH
inputs — that's correct.

---

## Workflow static data

```js
// In a Code node
const data = $getWorkflowStaticData('global'); // or 'node' for per-node
data.lastCursor = $json.nextCursor;
// (n8n persists this between executions)
```

- Scope `'global'` — shared across all nodes in the workflow.
- Scope `'node'` — only this node sees it.
- Persisted to the database between executions.
- DO NOT use for high-frequency state — it's a JSON column update per
  execution. Use Redis/Postgres for hot state.
- Wiped when the workflow is duplicated or imported fresh (no static-data
  export).

---

## Common item-structure mistakes

### 1. Returning bare objects from a Code node

```js
// ✗ Wrong — items must be wrapped in { json: ... }
return [{ foo: 'bar' }];

// ✓ Right
return [{ json: { foo: 'bar' } }];
```

### 2. Mutating `$json` in place

```js
// ✗ Wrong — mutates the upstream item's data, breaks history view
$json.newField = 'x';
return [{ json: $json }];

// ✓ Right — spread first
return [{ json: { ...$json, newField: 'x' } }];
```

### 3. Forgetting `pairedItem` after fan-out

```js
// ✗ Wrong — downstream $('PriorNode').item will throw
const items = $input.all();
const out = [];
for (const item of items) {
  for (const tag of item.json.tags) {
    out.push({ json: { tag } });
  }
}
return out;

// ✓ Right
const items = $input.all();
const out = [];
items.forEach((item, idx) => {
  for (const tag of item.json.tags) {
    out.push({ json: { tag }, pairedItem: { item: idx } });
  }
});
return out;
```

### 4. Binary keys collide

When merging two items that both have a binary key named `data0`, only one
survives. Rename via the Convert to File / Move Binary Data nodes or
explicitly set the key name on upload nodes.

### 5. Treating `$input.all()[0]` as a constant in Run Once for Each Item

In "Run Once for Each Item" mode, `$input.all()` returns ONE item — the
current one. To reach upstream multi-item context, use `$('Node').all()`.
