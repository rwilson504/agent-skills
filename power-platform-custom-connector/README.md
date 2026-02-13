# Power Platform Custom Connector Skill

Comprehensive skill for creating Power Platform custom connectors (Independent Publisher & Verified Publisher).

## Activation Keywords

- Power Platform custom connector
- Power Automate connector
- Independent Publisher connector
- Verified Publisher connector
- Swagger connector
- apiDefinition.swagger.json
- apiProperties.json
- paconn
- x-ms-summary
- x-ms-visibility
- x-ms-dynamic-values
- x-ms-trigger
- x-ms-connector-metadata

## Files

| File | Purpose | Lines |
|------|---------|-------|
| SKILL.md | Main skill — structure, patterns, quick reference | ~490 |
| OPENAPI_EXTENSIONS.md | All x-ms-* extensions with JSON examples | ~380 |
| AUTH_PATTERNS.md | API Key, OAuth AAD, OAuth Generic, Basic Auth, Multi-Auth | ~500 |
| POLICY_TEMPLATES.md | All policy template IDs with configs | ~340 |
| CUSTOM_CODE.md | C# script.csx patterns (ScriptBase) | ~250 |
| WEBHOOK_TRIGGERS.md | Webhook registration/deletion patterns | ~260 |
| EXAMPLES.md | Complete working connector examples | ~370 |
| COMMON_MISTAKES.md | 32 common errors with fixes | ~560 |
| README.md | This file | — |

## Coverage

- **OpenAPI 2.0 (Swagger)** definition structure
- **20+ x-ms-* extensions** with usage examples
- **5 authentication types** (API Key, OAuth AAD, OAuth Generic, Basic Auth, Multi-Auth)
- **13 policy templates** with configuration patterns
- **Custom code** (C# script.csx) with 4 code patterns
- **Webhook triggers** with registration/deletion lifecycle
- **Dynamic dropdowns** (x-ms-dynamic-values / x-ms-dynamic-list)
- **Copilot Studio / AI extensions** (x-ms-name-for-model, etc.)
- **Certification checklist** for PR submission
- **paconn CLI** commands

## Evaluations

5 evaluation scenarios in `evaluations/`:
- eval-001: Scaffold a basic API Key connector
- eval-002: Create OAuth AAD connector with Key Vault
- eval-003: Build a webhook trigger connector
- eval-004: Add dynamic dropdown values
- eval-005: Prepare connector for certification PR

## Sources

- [Microsoft: Custom connectors overview](https://learn.microsoft.com/en-us/connectors/custom-connectors/)
- [Microsoft: OpenAPI extensions](https://learn.microsoft.com/en-us/connectors/custom-connectors/openapi-extensions)
- [Microsoft: Create from scratch](https://learn.microsoft.com/en-us/connectors/custom-connectors/define-blank)
- [Microsoft: Webhook triggers](https://learn.microsoft.com/en-us/connectors/custom-connectors/create-webhook-trigger)
- [Microsoft: Custom code](https://learn.microsoft.com/en-us/connectors/custom-connectors/write-code)
- [GitHub: microsoft/PowerPlatformConnectors](https://github.com/microsoft/PowerPlatformConnectors)

## Last Updated

2026-02-13
