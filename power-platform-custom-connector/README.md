# Power Platform Custom Connector Creation

> Build production-ready Power Platform custom connectors (Independent Publisher and Verified Publisher) and submit them to [microsoft/PowerPlatformConnectors](https://github.com/microsoft/PowerPlatformConnectors).

This is the human-facing landing page for the skill. The AI agent contract lives in [SKILL.md](SKILL.md).

## Key capabilities

- Creating independent publisher connectors
- Creating verified publisher connectors
- Configuring authentication (OAuth2, API Key, Basic, Windows, No auth)
- Defining API operations and parameters via Swagger 2.0 / OpenAPI
- Applying any of the 13 built-in policy templates
- Adding custom code via `script.csx` (C# scripting)
- Building webhook trigger connectors
- Wiring up dynamic dropdowns and dynamic schemas
- Configuring Copilot Studio AI extensions
- Testing and validating connector functionality
- Publishing connectors to the Power Platform ecosystem

## Use cases

- Extending Power Platform with custom API integrations
- Building connectors for proprietary or third-party services
- Enabling low-code/no-code integration solutions
- Submitting an Independent Publisher connector to Microsoft for certification
- Authoring a Verified Publisher connector with full-featured policy + custom code

## Prerequisites

- Power Platform account
- Power Platform CLI (for development)
- OpenAPI/Swagger specification knowledge
- Understanding of authentication protocols

## Install (this skill only)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add rwilson504/agent-skills
copilot plugin install power-platform-custom-connector@agent-skills
```

### Claude Code

```bash
claude install-github-skill rwilson504/agent-skills/power-platform-custom-connector
```

### ClawHub

```bash
openclaw skills install power-platform-custom-connector
```

ClawHub publishing is currently paused — see the [root README](../README.md#installation) for status and alternative install methods (Cursor, Windsurf, VS Code, manual file copy).

## What's in this folder

| Path | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | Main skill instructions (what the agent loads) |
| [`references/AUTH_PATTERNS.md`](references/AUTH_PATTERNS.md) | OAuth2, API key, AAD, basic, custom — full patterns |
| [`references/OPENAPI_EXTENSIONS.md`](references/OPENAPI_EXTENSIONS.md) | All `x-ms-*` extensions with examples |
| [`references/POLICY_TEMPLATES.md`](references/POLICY_TEMPLATES.md) | 13 built-in policy templates |
| [`references/CUSTOM_CODE.md`](references/CUSTOM_CODE.md) | `script.csx` patterns |
| [`references/WEBHOOK_TRIGGERS.md`](references/WEBHOOK_TRIGGERS.md) | Webhook trigger setup + lifecycle |
| [`references/CERTIFICATION.md`](references/CERTIFICATION.md) | Certification flow and PR requirements |
| [`references/EXAMPLES.md`](references/EXAMPLES.md) | Worked end-to-end examples |
| [`references/COMMON_MISTAKES.md`](references/COMMON_MISTAKES.md) | Pitfalls and fixes |
| [`evaluations/`](evaluations/) | Test scenarios |

## Resources

- [Power Platform Custom Connectors Documentation](https://learn.microsoft.com/en-us/connectors/custom-connectors/)
- [Power Platform CLI](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction)
- [Connector Certification](https://learn.microsoft.com/en-us/connectors/custom-connectors/submit-certification)

## License

[MIT-0](https://opensource.org/license/0bsd) — no attribution required.
