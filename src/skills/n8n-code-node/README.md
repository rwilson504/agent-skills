# n8n Code Node

> Write correct JavaScript or Python in the n8n Code node — pairedItem
> preserved, run modes understood, helpers used properly.

This is the human-facing landing page. The AI agent contract lives in
[SKILL.md](SKILL.md).

## Key capabilities

- Choosing between `runOnceForAllItems` and `runOnceForEachItem`
- Returning items in the correct `{ json, binary?, pairedItem? }` shape
- Preserving item linking with the canonical `pairedItem` pattern
- Reading and writing binary data via `this.helpers.*`
- Using built-in JS libraries (Luxon, JMESPath) and external packages
  (`NODE_FUNCTION_ALLOW_EXTERNAL`)
- Persistent state via `$getWorkflowStaticData()`
- Writing AI Agent Code Tools

## Use cases

- Custom data transformations that don't fit Edit Fields (Set)
- Cross-item aggregation, joining, batching, splitting
- Per-item enrichment with calculations
- Tool implementations for AI Agents
- Glue code between integrations

## Prerequisites

- Basic JavaScript or Python knowledge
- Understanding of n8n's array-of-items data model (see
  [DATA_STRUCTURE.md](../n8n-build-workflow/references/DATA_STRUCTURE.md))

## Install (this skill only)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add rwilson504/agent-skills
copilot plugin install n8n@agent-skills
```

(Bundled in the `n8n` plugin.)

### Claude Code

```bash
claude install-github-skill rwilson504/agent-skills/src/skills/n8n-code-node
```

## What's in this folder

| Path | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | Main skill instructions |
| [`LESSONS_LEARNED.md`](LESSONS_LEARNED.md) | Continuous-learning log |
| [`references/JAVASCRIPT.md`](references/JAVASCRIPT.md) | JS runtime, helpers, allowlists, snippets |
| [`references/PYTHON.md`](references/PYTHON.md) | Pyodide runtime, package install, JS interop |
| [`references/BUILTIN_HELPERS.md`](references/BUILTIN_HELPERS.md) | `$json`/`$input`/`$node`/Luxon/JMESPath/$execution |
| [`references/ITEM_LINKING_CODE.md`](references/ITEM_LINKING_CODE.md) | Canonical pairedItem patterns for every cardinality |
| [`references/BINARY_DATA.md`](references/BINARY_DATA.md) | Reading and writing binary via helpers |

## Resources

- [n8n Code Node Docs](https://docs.n8n.io/code/code-node/)
- [n8n Code Node JavaScript Built-in Methods](https://docs.n8n.io/code/builtin/code-node-methods/)
- [Luxon Docs](https://moment.github.io/luxon/)
- [JMESPath](https://jmespath.org/)
- [Pyodide Docs](https://pyodide.org/)

## License

[MIT-0](https://opensource.org/license/0bsd) — no attribution required.
