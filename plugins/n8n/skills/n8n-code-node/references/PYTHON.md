# Python in the Code Node

n8n's Python runtime is **Pyodide** — CPython compiled to WebAssembly,
running inside a Node.js sandbox. Many things work; a few categorically
don't.

> Authoritative reference: <https://docs.n8n.io/code/code-node/#javascript-or-python>

---

## Skeleton

```python
# runOnceForAllItems
items = _input.all()

out = []
for index, item in enumerate(items):
    out.append({
        "json": { **item["json"], "computed": item["json"]["value"] * 2 },
        "pairedItem": { "item": index }
    })

return out
```

```python
# runOnceForEachItem
return {
    "json": {
        "upper": _json["name"].upper()
    }
}
```

### Variable names

JS uses `$` prefix (`$json`, `$input`); Python uses `_` prefix (`_json`,
`_input`, `_workflow`, `_execution`, `_env`, `_node`, `_jmespath`). Same
semantics, different sigil.

---

## What's available

- **CPython stdlib** — `json`, `re`, `datetime`, `collections`, `itertools`,
  `functools`, `math`, `random`, `hashlib`, `base64`, `urllib.parse`,
  `csv`, `io`, etc.
- **Pyodide built-ins** — `pyodide.ffi`, `js` (interop with JS — see below).
- **Curated science packages** — `numpy`, `pandas`, `scipy`, `scikit-learn`,
  `matplotlib`, `sympy`, and a couple hundred more, loaded on demand:

```python
import micropip
await micropip.install("requests-wasm")
```

The set of installable packages is the Pyodide-supported set, not full
PyPI. Packages with C extensions usually don't work unless they have a
WASM build.

---

## What does NOT work

- **`requests`, `urllib.request`** — Pyodide's network layer is browser
  XHR/fetch, not Berkeley sockets. Pure-stdlib `requests` raises socket
  errors. Either use `pyodide.http.pyfetch()` (returns Pyodide-style
  response) or, better, do the HTTP from the surrounding HTTP Request node
  and pass results into the Code node.
- **Native compiled packages without WASM build** — `psycopg2`, `lxml`,
  `Pillow` (sometimes), most ML wheels.
- **Multiprocessing / threading** — single-threaded WASM.
- **Filesystem access** — limited Pyodide virtual FS; no host disk.
- **Subprocess** — no `subprocess.run()`, no shell.

---

## JS interop via `js`

```python
import js

# Call a JS function
result = js.JSON.stringify(_json)

# Use JS console
js.console.log("hello from python")
```

For most n8n tasks you don't need `js` — use the n8n helpers (`_json`,
`_input`, etc.) instead.

---

## Common snippets

### Date math with stdlib

```python
from datetime import datetime, timezone, timedelta

now = datetime.now(timezone.utc)
yesterday = now - timedelta(days=1)

return {
    "json": {
        "now": now.isoformat(),
        "yesterday": yesterday.isoformat()
    }
}
```

### Parse and filter with pandas

```python
import pandas as pd

items = _input.all()
df = pd.DataFrame([i["json"] for i in items])

# Filter and project
filtered = df[df["amount"] > 100][["id", "amount", "category"]]

out = []
for index, row in filtered.iterrows():
    out.append({
        "json": row.to_dict(),
        "pairedItem": { "item": int(index) }
    })
return out
```

### Group and aggregate

```python
from collections import defaultdict

items = _input.all()
groups = defaultdict(list)
indexes = defaultdict(list)

for i, item in enumerate(items):
    key = item["json"]["category"]
    groups[key].append(item["json"]["amount"])
    indexes[key].append(i)

return [
    {
        "json": { "category": k, "total": sum(v), "count": len(v) },
        "pairedItem": [{ "item": i } for i in indexes[k]]
    }
    for k, v in groups.items()
]
```

### Hash a field for idempotency

```python
import hashlib

key = f"{_json['email']}|{_json['order_id']}"
fp = hashlib.sha256(key.encode("utf-8")).hexdigest()

return { "json": { **_json, "fingerprint": fp } }
```

### Static data (cursor / counter)

```python
data = _getWorkflowStaticData("global")
data["counter"] = data.get("counter", 0) + 1

return { "json": { **_json, "n": data["counter"] } }
```

---

## Pyodide install costs

`micropip.install()` downloads the package from the Pyodide CDN on first
use within a fresh Pyodide instance. n8n caches the Pyodide instance per
node, so subsequent executions of THE SAME Code node skip the install,
but a different Code node pays the cost again.

For small workflows this is fine. For high-frequency jobs, prefer doing the
work in JavaScript or in a built-in node — the JS runtime has no comparable
warm-up cost.

---

## When to NOT use Python

- For HTTP, use the HTTP Request node (Python's HTTP story in Pyodide is
  rough).
- For data transformations that fit n8n's built-in nodes (Set, Aggregate,
  Item Lists), use them.
- For per-item work where JavaScript would do, use JS (faster, no Pyodide
  warmup).
- For ML inference, run it in a separate service (FastAPI container) and
  call it via HTTP Request.

Python's sweet spot in n8n: pandas-style aggregation, complex math, regex
tricks that are easier to express in Python, and migrating existing Python
scripts.
