# JavaScript in the Code Node

n8n's Code node runs JS in a sandboxed VM. Async/await works at the top
level. Same engine as the n8n Node.js runtime (V8 via Node 20+).

> Authoritative reference: <https://docs.n8n.io/code/code-node/>

---

## Skeleton

```js
// runOnceForAllItems
const items = $input.all();

const out = items.map((item, index) => {
  // ... per-item logic
  return {
    json: { /* ... */ },
    pairedItem: { item: index }
  };
});

return out;
```

```js
// runOnceForEachItem
return {
  json: {
    upper: $json.name.toUpperCase()
  }
};
```

---

## What's available globally

| Symbol | Notes |
|---|---|
| All ECMAScript globals | `Object`, `Array`, `JSON`, `Math`, `Date`, `Map`, `Set`, `Promise`, etc. |
| `console` | Writes to n8n server log; NOT visible in execution data |
| `Buffer` | Node.js Buffer (always available) |
| `URL` / `URLSearchParams` | Always available |
| `crypto` | NOT available by default — set `NODE_FUNCTION_ALLOW_BUILTIN=crypto` |
| `fetch` | Available in n8n ≥ 1.10 (Node 18+) |
| `setTimeout` / `setInterval` | Available; clean up intervals to avoid leaks |
| `require()` | Restricted — see allowlist below |
| `import` | NOT available — Code node is CommonJS-style |

---

## Allowlists (self-hosted only)

n8n blocks arbitrary external/built-in module imports by default. To
allowlist:

```bash
# .env or docker-compose
NODE_FUNCTION_ALLOW_BUILTIN=crypto,url,querystring
NODE_FUNCTION_ALLOW_EXTERNAL=lodash,uuid,jsonwebtoken,date-fns
```

After restart, you can `require()` those packages:

```js
const _ = require('lodash');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');

return [{ json: { id: uuidv4() } }];
```

External packages must be installed in the n8n image. For the official
Docker image, build your own image:

```dockerfile
FROM n8nio/n8n:latest
USER root
RUN cd /usr/local/lib/node_modules/n8n && npm install lodash uuid jsonwebtoken
USER node
```

Cloud n8n doesn't allow external packages — use built-ins or build a
community node (see [n8n-create-nodes](../../n8n-create-nodes/SKILL.md)).

---

## `this.helpers` API

Available only in the Code node (and community nodes).

```js
// HTTP request from inside Code node
const data = await this.helpers.httpRequest({
  method: 'GET',
  url: 'https://api.example.com/items',
  headers: { 'Accept': 'application/json' },
  json: true,
});

// HTTP request with credential reuse (use the credential picker on the node)
const data2 = await this.helpers.httpRequestWithAuthentication.call(
  this,
  'httpHeaderAuth',         // credential type
  { method: 'GET', url: 'https://...', json: true }
);

// Binary data
const buffer = await this.helpers.getBinaryDataBuffer(0, 'data');
const binaryData = await this.helpers.prepareBinaryData(
  Buffer.from('hello'),
  'greeting.txt',
  'text/plain'
);
```

> The full `this.helpers.*` API is documented at
> <https://docs.n8n.io/code/builtin/code-node-methods/>.

---

## Common snippets

### Generate a UUID without external packages

```js
return [{ json: { id: crypto.randomUUID() } }];
```

(Requires `NODE_FUNCTION_ALLOW_BUILTIN=crypto`. Or use `Date.now() + Math.random()` for non-cryptographic IDs.)

### Parse a date safely

```js
const dt = DateTime.fromISO($json.createdAt);
if (!dt.isValid) {
  return [{ json: { ...$json, parseError: dt.invalidReason } }];
}
return [{ json: { ...$json, day: dt.toFormat('yyyy-MM-dd') } }];
```

### Group items by a field

```js
const items = $input.all();
const groups = {};
items.forEach((item, i) => {
  const key = item.json.category;
  if (!groups[key]) groups[key] = { items: [], sourceIndexes: [] };
  groups[key].items.push(item.json);
  groups[key].sourceIndexes.push(i);
});

return Object.entries(groups).map(([key, g]) => ({
  json: { category: key, count: g.items.length, items: g.items },
  pairedItem: g.sourceIndexes.map(i => ({ item: i }))
}));
```

### Deduplicate by a key

```js
const items = $input.all();
const seen = new Set();
const out = [];
items.forEach((item, i) => {
  const key = item.json.email;
  if (seen.has(key)) return;
  seen.add(key);
  out.push({ json: item.json, pairedItem: { item: i } });
});
return out;
```

### Call an HTTP API and merge response into items (1-to-1)

```js
const items = $input.all();
const out = [];
for (let i = 0; i < items.length; i++) {
  const detail = await this.helpers.httpRequest({
    url: `https://api.example.com/users/${items[i].json.id}`,
    json: true,
  });
  out.push({
    json: { ...items[i].json, ...detail },
    pairedItem: { item: i }
  });
}
return out;
```

(For bigger batches, do this in the HTTP Request node with Batching options
instead.)

### Use static data for a cursor

```js
const data = $getWorkflowStaticData('global');
data.cursor = data.cursor || null;

const url = data.cursor
  ? `https://api.example.com/items?cursor=${encodeURIComponent(data.cursor)}`
  : 'https://api.example.com/items';

const resp = await this.helpers.httpRequest({ url, json: true });
data.cursor = resp.nextCursor || null;

return resp.items.map((it, i) => ({
  json: it,
  pairedItem: data.cursor ? { item: 0 } : { item: 0 } // single source for fetch-style
}));
```

---

## Sandbox gotchas

- **No filesystem access by default** — `require('fs')` blocked unless
  `NODE_FUNCTION_ALLOW_BUILTIN=fs` set, which is a security risk.
- **No process.exit / process.env** — `process.env.X` returns undefined; use
  `$env.X` instead.
- **`require()` is module-scoped** — repeated `require()` of the same
  package is cached, so this is cheap.
- **VM context is shared per execution** — top-level state in one Code
  node IS NOT shared with another Code node. To share, use
  `$getWorkflowStaticData()` or pass via items.
- **Memory leaks survive workflow execution** — long-running `setInterval`
  inside a Code node keeps the VM alive. Always clear intervals.

---

## When to NOT use the Code node

- For simple field mapping/renaming, the **Edit Fields (Set)** node is
  clearer and survives copy/paste better.
- For HTTP requests, the **HTTP Request** node has retries, batching, and
  pagination built in — don't reinvent it in Code.
- For loops over items with rate limiting, the **Loop Over Items
  (Split In Batches) + Wait** pattern is idiomatic.
- For complex per-API logic that's shared across workflows, build a
  **community node** instead (see [n8n-create-nodes](../../n8n-create-nodes/SKILL.md)).
