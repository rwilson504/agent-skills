# Item-Linking Errors

n8n tracks how output items derive from input items via the `pairedItem`
field. When the chain breaks, expressions like `$('UpstreamNode').item`
throw "Could not find paired item".

> Read [DATA_STRUCTURE.md](../../n8n-build-workflow/references/DATA_STRUCTURE.md)
> first for the conceptual model.

---

## The error message

```
[Workflow data error]: Could not find paired item for the current item.
Make sure to add the "pairedItem" property when returning items in a Code Node,
or include it via the items[].pairedItem property when returning custom data.
```

This always means: somewhere in the chain between the node throwing the
error and the node referenced in `$('Node').item`, an item lost its
pairedItem field.

---

## Common causes

### 1. Code node didn't set `pairedItem`

```js
// ✗ Wrong — downstream $('Webhook').item will throw
const items = $input.all();
return items.map(item => ({ json: { processed: item.json.value * 2 } }));

// ✓ Right
return items.map((item, index) => ({
  json: { processed: item.json.value * 2 },
  pairedItem: { item: index }
}));
```

In "Run Once for Each Item" Code node mode, n8n auto-sets pairedItem from
the current item. The manual handling above is for "Run Once for All Items".

### 2. Community node doesn't set `pairedItem`

Some older community nodes return raw items without pairedItem.

**Detection:** the failing reference works for some items, not others, OR
fails after a specific community node in the chain.

**Workarounds:**

- Use `$('Node').first()` or `$('Node').itemMatching($itemIndex)` instead of
  `$('Node').item`.
- File an issue against the community node.
- Insert a Set node after the community node and use a join key
  (`Item Lists → Split Out` or `Merge → Combine by Key`) to re-establish
  linkage by data instead of pairedItem.

### 3. Aggregate / Summarize collapses pairing into arrays

```json
// After Aggregate, pairedItem looks like:
"pairedItem": [{ "item": 0 }, { "item": 1 }, { "item": 2 }]
```

This is correct — the aggregated item came from items 0, 1, 2. But
`$('Source').item` no longer makes sense (it'd be ambiguous), so it throws.

**Fix:** Use `$('Source').all()` for the full array, or
`$('Source').first()` if you want one representative item.

### 4. Merge with `combineByKey` loses upstream pairing

When merging, the output items reference items from BOTH inputs. n8n handles
this correctly in most cases, but a custom upstream Code node may have already
broken pairing in one branch. The Merge inherits the breakage.

**Fix:** Fix the upstream Code node. Or restructure so the lookup happens
inside the same branch using `$('Node').first()`.

### 5. `executeOnce: true` flattens to a single output

Setting `executeOnce: true` on a node makes it run once even when input has
multiple items. The output is treated as a single item whose pairedItem
references the FIRST input only.

**Fix:** Don't use `executeOnce` if downstream needs per-item pairing.

---

## Forensic procedure

When debugging a "Could not find paired item" error:

1. **Identify the throwing expression.** The error names a node (the throwing
   node) but the problematic expression is in that node's parameters. Open
   the node, find the `$('X').item` reference.

2. **Identify the chain.** Walk from `X` to the throwing node, listing every
   node in between.

3. **Inspect each intermediate node's output `pairedItem`.**
   - Open the execution → click each intermediate node → Output tab → switch
     to JSON view (not Schema).
   - Find an item that DOES make it through. Look at its `pairedItem`.
   - Find the first node where pairing is missing or unexpected.

4. **Apply the fix at that node:**
   - Code node → add `pairedItem: { item: index }` to returned items.
   - Community node → swap to `$('X').first()` or `.itemMatching(idx)`.
   - Aggregate / Merge → restructure the expression to handle the
     N-source case.

---

## Safe alternatives to `$('Node').item`

| Pattern | Behavior |
|---|---|
| `$('Node').item` | Walks pairedItem chain to find THE source item. Throws if broken. |
| `$('Node').first()` | Returns the FIRST item of Node's output. No pairing required. |
| `$('Node').last()` | Returns LAST item. |
| `$('Node').itemMatching($itemIndex)` | Returns item at the same index as current. Useful when both nodes processed in lockstep. |
| `$('Node').all()` | Returns all items. |
| `$('Node').all()[someIndex]` | Direct index. |

**Rule of thumb:** Use `$('Node').item` only when pairing is reliable
(everything in the chain is built-in nodes that preserve pairedItem). For
cross-Code-node or cross-community-node chains, prefer
`.first()` / `.itemMatching()`.

---

## "Item linking broke after I edited the workflow"

This sometimes happens when:

- You inserted a Code node into a chain that previously had only
  pairing-aware nodes. The Code node's default behavior may or may not
  preserve pairing depending on mode and how items are constructed.
- You changed a node's "Run Mode" from "Run Once for Each Item" to "Run
  Once for All Items" without updating the body to preserve pairedItem
  manually.

**Fix:** Audit the Code node's returned items. Confirm each has
`pairedItem` set.

---

## Verifying pairedItem in the editor

In a node's Output pane, switch to **JSON view**. Each item should look
like:

```json
{
  "json": { ... },
  "pairedItem": { "item": 0 }
}
```

If `pairedItem` is absent on items in this node's output, downstream
`$('Node').item` references THROUGH this node will fail. Fix it here.

---

## Bonus: `pairedItem` with multiple sources

After a Merge or aggregation, an item can reference multiple sources:

```json
"pairedItem": [
  { "item": 0 },
  { "item": 1, "sourceOverwrite": { "previousNode": "OtherBranch" } }
]
```

`sourceOverwrite.previousNode` is needed when the item drew from a non-default
upstream branch (typical after Merge with multiple inputs). When writing a
Code node that merges items, build pairedItem as an array with explicit
sourceOverwrite entries to preserve full traceability.
