# Expressions

n8n parameter fields accept either a fixed value or an **expression** that
starts with `=` and contains `{{ ... }}` templates. Templates evaluate as
JavaScript with built-in helpers in scope.

> Authoritative reference: <https://docs.n8n.io/code/expressions/>

---

## Built-in variables

| Variable | Returns | Notes |
|---|---|---|
| `$json` | The current item's `.json` payload | Shorthand for `$input.item.json` |
| `$binary` | The current item's `.binary` map | Each value is `{ data, mimeType, fileName, fileExtension }` |
| `$input.item` | The current item with `.pairedItem` preserved | Use this in Code-node-adjacent contexts |
| `$input.all()` | Array of all incoming items | |
| `$input.first()` | First incoming item | |
| `$input.last()` | Last incoming item | |
| `$input.params` | The node's `parameters` object | |
| `$input.context` | Execution context for this node | Rarely used |
| `$('Node Name').item` | The single item that fed into the current item from that prior node (follows `pairedItem`) | Throws if pairing is broken |
| `$('Node Name').itemMatching(index)` | Item at a specific index of that node's output | |
| `$('Node Name').all()` | All items output by that node | |
| `$('Node Name').first()` / `.last()` | Self-explanatory | |
| `$('Node Name').isExecuted` | `true` if that node ran in this execution | |
| `$('Node Name').params` | That node's `parameters` | |
| `$node["Node Name"]` | Legacy alternative to `$('Node Name')` | Still works |
| `$workflow.id` / `.name` / `.active` | Workflow metadata | |
| `$execution.id` / `.mode` / `.resumeUrl` | Execution metadata | `mode` ∈ `manual`, `trigger`, `webhook`, `cli`, `retry`, `internal`, `integrated` |
| `$execution.customData.get/set` | Per-execution KV store visible in execution detail UI | |
| `$env.<KEY>` | Hosting env var | Disabled if `N8N_BLOCK_ENV_ACCESS_IN_NODE=true` (default: `false`) |
| `$now` | Luxon `DateTime` in workflow timezone | `$now.toISO()`, `$now.minus({ hours: 1 })`, etc. |
| `$today` | `$now.startOf('day')` | |
| `$vars` | Instance/project variables (Enterprise/Cloud) | |
| `$secrets.<vault>.<key>` | External Secrets value (Enterprise) | |
| `$jmespath(obj, expr)` | JMESPath query | <https://jmespath.org/> |
| `$prevNode` | Object `{ name, outputIndex, runIndex }` of the upstream node | |
| `$runIndex` | Iteration index when a node runs multiple times | |
| `$itemIndex` | Index of the current item in the incoming array | |
| `DateTime` / `Duration` / `Interval` | Luxon constructors | Full Luxon API available |

---

## The `=` prefix

```
=Hello {{ $json.name }}, today is {{ $today.toFormat('cccc') }}.
```

- The leading `=` is REQUIRED. Without it, the field is treated as a literal
  string and `{{ ... }}` won't evaluate.
- Multiple `{{ ... }}` templates can appear in one expression and are joined
  as strings.
- Inside `{{ }}`, you can use any JS expression — no statements, no
  `var/let/const`, no `if (...) { }` blocks. Use ternaries, optional
  chaining, and arrow functions.

---

## Common patterns

### Safe access with optional chaining

```
={{ $('HTTP').first()?.json?.data?.id ?? 'unknown' }}
```

### Conditional via ternary

```
={{ $json.amount > 100 ? 'large' : 'small' }}
```

### Date math

```
={{ $now.minus({ days: 7 }).toISO() }}
={{ DateTime.fromISO($json.createdAt).toFormat('yyyy-MM-dd') }}
```

### Array filter / map / join

```
={{ $('Items').all().map(i => i.json.email).filter(e => e).join(', ') }}
```

### JMESPath into deep JSON

```
={{ $jmespath($json, "items[?status=='active'].id") }}
```

### Reference a credential's value (rare — usually n8n injects automatically)

You can't read credentials from expressions in built-in nodes. For Code nodes
or custom HTTP signing, use the credential dropdown on the node itself.

### Reference a static workflow data store

```
={{ $getWorkflowStaticData('global').lastCursor || '' }}
```

`getWorkflowStaticData(scope)` is available in Code nodes; `$getWorkflowStaticData()`
is the expression-context equivalent for reading only.

---

## Pitfalls

### 1. `$json` in a Code node is per-mode

In a Code node set to **Run Once for All Items**, `$json` is the FIRST item's
json. Use `$input.all()` to iterate. In **Run Once for Each Item**, `$json` is
the current item's json. See [n8n-code-node](../../n8n-code-node/SKILL.md).

### 2. `$('Node').item` throws when pairing is broken

If a Code node or community node dropped `pairedItem` from its returned items,
`$('UpstreamNode').item` will throw "Could not find paired item". Use
`$('UpstreamNode').first()` if you only need the first item of the upstream
output, or fix the broken pairing.

### 3. `$('Node').first()` returns `undefined` if Node didn't execute

On a branch where that node was skipped, `$('Node').first()?.json...?` is the
defensive pattern. Or check `$('Node').isExecuted` first.

### 4. Multi-line strings need template literals

```
=`Line 1
Line 2: {{ $json.foo }}`
```

That doesn't work. Use string concatenation or build the multi-line string in
a Code node or a Set node with a `string` value containing literal newlines.

### 5. `$env` blocked in node parameters by default? Check your version

In recent n8n versions, `N8N_BLOCK_ENV_ACCESS_IN_NODE` defaults to `false`
(env vars ARE accessible). On older versions or hardened deployments it may
be `true`. Verify before relying on `$env.<KEY>` in production.

### 6. Boolean coercion gotchas

```
={{ $json.flag === 'true' ? 1 : 0 }}      // ✓ string comparison
={{ $json.flag === true ? 1 : 0 }}        // ✓ boolean comparison
={{ $json.flag ? 1 : 0 }}                 // ⚠ truthy: '' and 0 and false all become 0
```

### 7. `$now` uses the workflow timezone, not server timezone

The workflow's `settings.timezone` (or the instance default `GENERIC_TIMEZONE`)
determines `$now`'s zone. Use `.setZone('UTC')` explicitly when emitting to
external systems.

### 8. JMESPath returns `null` for no match, not `[]`

`$jmespath($json, "items[?id==`999`].name")` returns `null` if no items
matched. Defend with `?? []` before mapping.
