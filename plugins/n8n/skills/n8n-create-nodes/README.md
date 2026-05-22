# n8n Community Node Creation

> Build production-ready n8n community nodes as npm packages — declarative (REST API wrapping) or programmatic (custom logic).

This is the human-facing landing page for the skill. The AI agent contract lives in [SKILL.md](SKILL.md).

## Key capabilities

- Creating new n8n community nodes (declarative + programmatic styles)
- Implementing node operations and resources
- Configuring node parameters and credentials
- Building trigger nodes — webhook, polling, and schedule patterns
- Versioned nodes (multiple `INodeType` versions in one package)
- Testing nodes locally
- Preparing nodes for community publication

## Use cases

- Adding support for new services in n8n
- Creating specialized automation nodes
- Contributing to the n8n open-source ecosystem

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Basic TypeScript knowledge
- n8n instance for testing

## Install (this skill only)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add rwilson504/agent-skills
copilot plugin install n8n-create-nodes@agent-skills
```

### Claude Code

```bash
claude install-github-skill rwilson504/agent-skills/src/skills/n8n-create-nodes
```

### ClawHub

```bash
openclaw skills install n8n-create-nodes
```

ClawHub publishing is currently paused — see the [root README](../README.md#installation) for status and alternative install methods (Cursor, Windsurf, VS Code, manual file copy).

## What's in this folder

| Path | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | Main skill instructions (what the agent loads) |
| [`references/CREDENTIAL_PATTERNS.md`](references/CREDENTIAL_PATTERNS.md) | OAuth2, API key, and generic auth recipes |
| [`references/TRIGGER_PATTERNS.md`](references/TRIGGER_PATTERNS.md) | Webhook + polling trigger patterns |
| [`references/EXAMPLES.md`](references/EXAMPLES.md) | Worked examples |
| [`references/COMMON_MISTAKES.md`](references/COMMON_MISTAKES.md) | Pitfalls and fixes |
| [`evaluations/`](evaluations/) | Test scenarios |

## Resources

- [n8n Node Development Documentation](https://docs.n8n.io/integrations/creating-nodes/)
- [n8n Community Nodes](https://docs.n8n.io/integrations/community-nodes/)
- [n8n GitHub Repository](https://github.com/n8n-io/n8n)

## License

[MIT-0](https://opensource.org/license/0bsd) — no attribution required.
