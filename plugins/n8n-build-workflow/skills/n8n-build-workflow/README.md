# n8n Build Workflow

> Design and author n8n workflow JSON files that import cleanly and run
> reliably.

This is the human-facing landing page. The AI agent contract lives in
[SKILL.md](SKILL.md).

## Key capabilities

- Authoring workflow JSON the user can import directly
- Wiring triggers (Manual, Schedule, Webhook, Form, App, Chat, Error)
- Flow logic (IF, Switch, Filter, Merge, Loop Over Items, Wait, Stop and
  Error, Sub-workflows)
- Expressions (`={{ }}`, `$json`, `$node`, `$input`, `$execution`, `$now`,
  JMESPath, Luxon)
- AI workflows using the LangChain cluster nodes (Agent + Chat Model + Memory
  + Tools + Vector Store + Embeddings)
- Error-workflow handoff and idempotency patterns
- Webhook synchronous responses with Respond to Webhook

## Use cases

- Greenfield workflow design from requirements
- Refactoring existing workflows (extract sub-workflows, add error handling)
- Building chat/RAG/agent AI workflows
- Adding integrations between SaaS apps

## Prerequisites

- An n8n instance (Cloud or self-hosted) to import the generated JSON into
- Knowledge of which credentials need to exist in the instance for the apps
  involved

## Install (this skill only)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add rwilson504/agent-skills
copilot plugin install n8n@agent-skills
```

(The `n8n` plugin bundles this skill plus the rest of the n8n agent bundle.)

### Claude Code

```bash
claude install-github-skill rwilson504/agent-skills/src/skills/n8n-build-workflow
```

## What's in this folder

| Path | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | Main skill instructions (what the agent loads) |
| [`LESSONS_LEARNED.md`](LESSONS_LEARNED.md) | Continuous-learning log — read before non-trivial work |
| [`references/WORKFLOW_JSON.md`](references/WORKFLOW_JSON.md) | Full workflow JSON schema |
| [`references/NODE_CATALOG.md`](references/NODE_CATALOG.md) | Hot-list of core/flow/AI node IDs with current typeVersions |
| [`references/EXPRESSIONS.md`](references/EXPRESSIONS.md) | Expression reference and gotchas |
| [`references/DATA_STRUCTURE.md`](references/DATA_STRUCTURE.md) | n8n's array-of-items data model and `pairedItem` |
| [`references/AI_WORKFLOWS.md`](references/AI_WORKFLOWS.md) | LangChain cluster topologies and the `fromAI()` function |
| [`references/PATTERNS.md`](references/PATTERNS.md) | Proven recipes and a common-mistakes catalog |

## Resources

- [n8n Workflow Docs](https://docs.n8n.io/workflows/)
- [n8n Node Types](https://docs.n8n.io/integrations/builtin/node-types/)
- [n8n Expression Reference](https://docs.n8n.io/data/expression-reference/)
- [n8n Advanced AI](https://docs.n8n.io/advanced-ai/)

## License

[MIT-0](https://opensource.org/license/0bsd) — no attribution required.
