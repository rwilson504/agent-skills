# Item Linking in Code Nodes

The single most common Code-node bug: returned items don't carry
`pairedItem`, downstream `$('PriorNode').item` throws "Could not find paired
item". This file is the cheat sheet for every cardinality.

> Conceptual background: [DATA_STRUCTURE.md](../../n8n-build-workflow/references/DATA_STRUCTURE.md)
> and [ITEM_LINKING_ERRORS.md](../../n8n-debug-workflow/references/ITEM_LINKING_ERRORS.md).

---

## Rule

In **`runOnceForEachItem` mode**, n8n auto-sets `pairedItem` from the
current item. You don't need to set it manually unless you're returning
something derived from MULTIPLE source items (which you can't do in
each-item mode anyway — there's only one source item visible).

In **`runOnceForAllItems` mode**, YOU are responsible. Every returned item
must have a `pairedItem` field pointing back at its source input(s).

---

## Pattern catalog (runOnceForAllItems)

### 1-to-1 (transform each item)

```js
const items = $input.all();
return items.map((item, index) => ({
  json: { ...item.json, computed: item.json.value * 2 },
  pairedItem: { item: index }
}));
```

### 1-to-N (fan out each item into multiple)

```js
const items = $input.all();
const out = [];
items.forEach((item, sourceIndex) => {
  for (const tag of item.json.tags) {
    out.push({
      json: { tag, source: item.json.id },
      pairedItem: { item: sourceIndex }
    });
  }
});
return out;
```

### N-to-1 (aggregate all into one)

```js
const items = $input.all();
return [{
  json: {
    count: items.length,
    total: items.reduce((a, i) => a + i.json.amount, 0)
  },
  pairedItem: items.map((_, i) => ({ item: i }))  // array of all sources
}];
```

### N-to-M (filter / dedup / arbitrary)

```js
const items = $input.all();
const seen = new Set();
const out = [];
items.forEach((item, sourceIndex) => {
  if (seen.has(item.json.email)) return;
  seen.add(item.json.email);
  out.push({
    json: item.json,
    pairedItem: { item: sourceIndex }
  });
});
return out;
```

### Splitting one item into multiple with cross-references

```js
// Single source item, fan to multiple children, each remembers the parent.
const item = $input.first();
const children = item.json.children;

return children.map((child, idx) => ({
  json: { ...child, parentId: item.json.id, childIndex: idx },
  pairedItem: { item: 0 }  // all derived from the (only) input item
}));
```

### Merging items from multiple upstream branches

When a Code node sits AFTER a Merge node, every input item already has
pairedItem from the merge. To produce N-to-1 output that traces back through
the merge:

```js
// Items came from a Merge node with two inputs
const items = $input.all();
return [{
  json: { merged: items.map(i => i.json) },
  pairedItem: items.flatMap(i => Array.isArray(i.pairedItem) ? i.pairedItem : [i.pairedItem])
}];
```

This preserves the chain through the merge.

### Cross-source pairing (advanced)

When an item is derived from items in two DIFFERENT upstream nodes (not just
the immediate predecessor), use `sourceOverwrite`:

```js
// Joining items from 'Source A' and 'Source B' (not from the previous node)
const a = $('Source A').all();
const b = $('Source B').all();

const out = [];
a.forEach((aItem, i) => {
  const bItem = b.find(x => x.json.aId === aItem.json.id);
  if (!bItem) return;
  const bIndex = b.indexOf(bItem);

  out.push({
    json: { ...aItem.json, b: bItem.json },
    pairedItem: [
      { item: i, sourceOverwrite: { previousNode: 'Source A' } },
      { item: bIndex, sourceOverwrite: { previousNode: 'Source B' } }
    ]
  });
});

return out;
```

---

## Verifying pairing worked

After running the Code node, click it in the execution view → switch
output panel to **JSON** view → each item should show `pairedItem`. If it's
missing, downstream `$('PriorNode').item` references will fail.

Quick verification expression downstream:

```
={{ $('PriorNode').item.json.someField }}
```

If this evaluates without error, pairing is intact.

---

## What "auto-pairing" actually does

In `runOnceForEachItem` mode, n8n wraps your single-item return as:

```js
{ json: <your returned json>, pairedItem: { item: $itemIndex } }
```

So if your function returned `{ json: { x: 1 } }` and the current
`$itemIndex` is 3, the final item is:

```js
{ json: { x: 1 }, pairedItem: { item: 3 } }
```

You can override by explicitly returning `pairedItem` in the object.

---

## Why pairing matters

Downstream nodes (and expression authors) can write
`$('OriginalSource').item.json.userId` to walk back through the entire chain
and find the source item's fields, no matter how many transformations
happened in between. This is invaluable for:

- Logging context ("this Slack post was triggered by webhook X with body Y")
- Error messages that reference original input
- Audit trails

Breaking pairing breaks all that. Set it.
