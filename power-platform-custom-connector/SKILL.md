---
name: power-platform-custom-connector
description: Create Power Platform custom connectors for Independent Publisher or Verified Publisher certification. Use when building apiDefinition.swagger.json, apiProperties.json, writing OpenAPI 2.0 definitions with x-ms-* extensions, configuring connection parameters, adding policy templates, writing custom code (script.csx), creating webhook triggers, or preparing connectors for Microsoft certification submission to the PowerPlatformConnectors GitHub repo.
---

# Power Platform Custom Connector Creation

Build production-ready Power Platform custom connectors and submit them to the [microsoft/PowerPlatformConnectors](https://github.com/microsoft/PowerPlatformConnectors) GitHub repo. This skill covers **Independent Publisher** and **Verified Publisher** connector paths.

**References:** [OPENAPI_EXTENSIONS.md](OPENAPI_EXTENSIONS.md) | [AUTH_PATTERNS.md](AUTH_PATTERNS.md) | [POLICY_TEMPLATES.md](POLICY_TEMPLATES.md) | [CUSTOM_CODE.md](CUSTOM_CODE.md) | [WEBHOOK_TRIGGERS.md](WEBHOOK_TRIGGERS.md) | [EXAMPLES.md](EXAMPLES.md) | [COMMON_MISTAKES.md](COMMON_MISTAKES.md)

---

## Quick Reference: Independent Publisher vs Verified Publisher

| Aspect | Independent Publisher | Verified Publisher |
|--------|----------------------|-------------------|
| **Who** | Community member (MVP, developer) — does NOT own the API | Service owner — owns the underlying API |
| **Brand color** | **Must** be `#da3b01` | Custom brand color allowed |
| **PR target** | `independent-publisher-connectors/` on `dev` branch | `certified-connectors/` on `dev` branch |
| **Certification** | Free, reviewed by MS Connector Certification Team | Free, via ISV Studio registration |
| **Connector tier** | Premium (automatic for external APIs) | Premium (automatic for external APIs) |
| **PR requirements** | Screenshots of 3 unique operations working in a Flow | Thorough API testing documentation |
| **OAuth redirect** | Per-connector redirect URI (mandatory since Feb 2024) | Per-connector redirect URI (mandatory since Feb 2024) |

**Decision rule:** If you own the API/service, go **Verified Publisher**. If you're wrapping a third-party API you don't own, go **Independent Publisher**.

---

## Getting Started

### Required Files

Every connector directory must contain:

| File | Required | Purpose |
|------|----------|---------|
| `apiDefinition.swagger.json` | **Yes** | OpenAPI 2.0 (Swagger) definition — operations, parameters, responses, schemas |
| `apiProperties.json` | **Yes** | Connection parameters, brand color, auth config, policy templates |
| `readme.md` | **Yes** | Description, prerequisites, supported operations, credentials guide |
| `icon.png` | Optional | Connector icon displayed in the designer |
| `script.csx` | Optional | C# custom code for request/response transformation |

### Directory Structure

```
PowerPlatformConnectors/
├── independent-publisher-connectors/
│   └── YourConnector/
│       ├── apiDefinition.swagger.json
│       ├── apiProperties.json
│       ├── readme.md
│       ├── icon.png          (optional)
│       └── script.csx        (optional)
├── certified-connectors/       (verified publishers)
├── custom-connectors/          (samples only)
├── schemas/                    (JSON Schema for validation)
│   ├── apiDefinition.swagger.schema.json
│   └── paconn-apiProperties.schema.json
└── templates/                  (starter templates)
```

### Scaffold a New Connector

```bash
# Fork and clone the repo
git clone https://github.com/<your-fork>/PowerPlatformConnectors.git
cd PowerPlatformConnectors
git checkout dev

# Create connector directory
mkdir independent-publisher-connectors/YourConnector
cd independent-publisher-connectors/YourConnector

# Create required files (see EXAMPLES.md for complete templates)
```

---

## Swagger Definition Structure (apiDefinition.swagger.json)

**Critical:** Must be **OpenAPI 2.0** (Swagger). OpenAPI 3.0 is NOT supported.

```json
{
  "swagger": "2.0",
  "info": {
    "version": "1.0.0",
    "title": "My Service",
    "description": "Short description (30-500 chars). No words 'API', 'Connector', or Power Platform product names.",
    "contact": {
      "name": "Your Name",
      "url": "https://github.com/yourusername",
      "email": "you@example.com"
    }
  },
  "host": "api.myservice.com",
  "basePath": "/v1",
  "schemes": ["https"],
  "consumes": ["application/json"],
  "produces": ["application/json"],
  "securityDefinitions": {},
  "security": [],
  "paths": {},
  "definitions": {},
  "x-ms-connector-metadata": [
    { "propertyName": "Website", "propertyValue": "https://myservice.com" },
    { "propertyName": "Privacy policy", "propertyValue": "https://myservice.com/privacy" },
    { "propertyName": "Categories", "propertyValue": "AI;Business Intelligence" }
  ]
}
```

**Key rules:**
- `title` — **Maximum 30 characters**. Cannot include the words "API", "Connector", "Copilot Studio", or any Power Platform product names. Must end with an alphanumeric character (no trailing punctuation, spaces, or special chars). Must be unique and distinguishable from existing connector titles. For Independent Publishers, use the pattern: `Connector Name (Independent Publisher)`
- `description` — Must be **30-500 characters**. Cannot contain "API", "Copilot Studio", or Power Platform product names. Must be free of grammatical and spelling errors. Should concisely describe the main purpose and value of the connector
- `contact` — Include `name`, `url`, and `email` with a valid email address
- `x-ms-connector-metadata` — **Required** array with Website, Privacy policy, and Categories
- `schemes` — Must include `"https"` (HTTP not allowed for production connectors)
- `host` — **Production host URL only**. Staging, dev, and test host URLs are not allowed. Base hostname only, no path segments

**File formatting:**
- Use soft tabs with **4 spaces** for indentation — no hard tabs
- Remove trailing whitespace from all lines
- Structure the file in this order: swagger version → info → host/schemes → consumes/produces → paths → definitions → parameters

---

## Operations (Paths)

Define actions and triggers in the `paths` object:

```json
"paths": {
  "/items": {
    "get": {
      "operationId": "ListItems",
      "summary": "List all items",
      "description": "Retrieves a list of all items from the service.",
      "x-ms-visibility": "important",
      "parameters": [
        {
          "name": "status",
          "in": "query",
          "type": "string",
          "x-ms-summary": "Status",
          "description": "Filter items by their current status.",
          "x-ms-visibility": "advanced"
        }
      ],
      "responses": {
        "200": {
          "description": "Success",
          "schema": { "$ref": "#/definitions/ItemList" }
        },
        "400": {
          "description": "The request was invalid or malformed."
        },
        "404": {
          "description": "The requested resource was not found."
        }
      }
    },
    "post": {
      "operationId": "CreateItem",
      "summary": "Create an item",
      "description": "Creates a new item in the service.",
      "parameters": [
        {
          "name": "body",
          "in": "body",
          "required": true,
          "schema": { "$ref": "#/definitions/CreateItemRequest" }
        }
      ],
      "responses": {
        "201": {
          "description": "Created",
          "schema": { "$ref": "#/definitions/Item" }
        }
      }
    }
  }
}
```

**Key rules:**
- `operationId` — **Must** be PascalCase (capitalize every word), unique across all operations. Remove all non-alpha characters — no hyphens, underscores, or spaces (e.g., `get_user-info` → `GetUserInfo`)
- `summary` — **Required** for every operation. Must be sentence case, **80 characters or fewer**, and must **end with an alphanumeric character** (no trailing punctuation, spaces, or special characters). Must contain only alphanumeric characters or parentheses — **no slashes (`/`)**. As a naming convention: start with **"List"** when the operation returns multiple records, **"Get"** when it returns a single record. For triggers, use the format: **"When a [event]"** (e.g., "When a task is created")
- `summary` and `description` **must not have the same text** — the description should provide additional information beyond the summary
- `description` — **Required** for every operation and parameter. Must be a **full, descriptive sentence ending in punctuation**. Must not contain any URLs. Must be in English and free of grammatical or spelling errors
- `x-ms-summary` — **Required** on every parameter and schema property. Use Title Case, matching the parameter `name` but without hyphens or underscores (e.g., `name: "form_name"` → `x-ms-summary: "Form Name"`)
- `x-ms-visibility` — Controls visibility: `"important"` (always shown), `"advanced"` (hidden under menu), `"internal"` (hidden from user)
- **Response schemas** — Each operation should have only **one response with a schema**, which should be the `2XX` success response (200 or 201). The `default` response should **NOT** have a schema definition — schemas belong on expected success responses only. For error responses (`4xx`, `5xx`), provide meaningful descriptions but **remove the schema property**. Empty response schemas are not allowed (except when dynamic). Empty operations are not allowed — every operation must have at least one response
- **Path parameters** — All path parameters (e.g., `/items/{itemId}`) **must** include `"x-ms-url-encoding": "single"` and **must** be marked `"required": true`
- **Reserved names** — A parameter cannot be named `connectionId` (reserved by the platform)
- **GET operations** — Cannot have body or form data parameters
- **Remove empty properties** from operations and parameters unless they are explicitly required

---

## Definitions (Schemas)

Define reusable data models in the `definitions` object. These are referenced via `$ref` in operation parameters and responses.

**Key rules:**
- All objects under `properties` **must** include both a `description` and `title` property, even when nested — **unless** the object contains a `$ref` property
- `title` — Must be in **Title Case**. Must not contain URLs
- `description` — Must be a **full sentence with proper punctuation**. Must not contain URLs
- Keep all other existing properties of the definition intact
- **Remove `default` values** from objects inside `properties` (defaults belong on operation parameters, not schema definitions)
- If a `number` or `integer` property's description mentions minimum or maximum values, add explicit `minimum` and/or `maximum` properties to the schema

```json
"definitions": {
  "Task": {
    "type": "object",
    "properties": {
      "id": {
        "type": "string",
        "title": "Task ID",
        "description": "The unique identifier for the task.",
        "x-ms-summary": "Task ID"
      },
      "name": {
        "type": "string",
        "title": "Task Name",
        "description": "The display name of the task.",
        "x-ms-summary": "Task Name"
      },
      "priority": {
        "type": "integer",
        "title": "Priority",
        "description": "The priority level of the task, from 1 (highest) to 5 (lowest).",
        "x-ms-summary": "Priority",
        "minimum": 1,
        "maximum": 5
      },
      "project": {
        "$ref": "#/definitions/Project"
      }
    }
  }
}
```

Note: The `project` property uses `$ref`, so it does **not** need its own `title` or `description`.

---

## OpenAPI Extensions Quick Reference

| Extension | Purpose | Applies To |
|-----------|---------|------------|
| `summary` | Action title in designer | Operations |
| `x-ms-summary` | Display name for entity | Parameters, schema properties |
| `description` | Verbose explanation | Operations, parameters, schemas |
| `x-ms-visibility` | `important` / `advanced` / `internal` | Operations, parameters, schemas |
| `x-ms-trigger` | `"single"` or `"batch"` — marks as trigger | Operations |
| `x-ms-trigger-hint` | Hint text for triggers | Operations |
| `x-ms-notification-content` | Webhook payload schema | Resources (path level) |
| `x-ms-notification-url` | Marks field as callback URL | Parameters |
| `x-ms-dynamic-values` | Populate dropdown from API call | Parameters |
| `x-ms-dynamic-list` | Enhanced dynamic dropdown (unambiguous refs) | Parameters |
| `x-ms-dynamic-schema` | Dynamic schema from API call | Parameters, responses |
| `x-ms-dynamic-properties` | Enhanced dynamic schema (unambiguous refs) | Parameters, responses |
| `x-ms-capabilities` | Test connection, chunk transfer | Connectors, operations |
| `x-ms-api-annotation` | Versioning: family, revision, replacement | Operations |
| `x-ms-url-encoding` | `"double"` or `"single"` for path params | Path parameters |
| `x-ms-connector-metadata` | Website, privacy policy, categories | Root level |
| `x-ms-no-generic-test` | Skip generic testing | Operations |
| `x-ms-safe-operation` | Mark POST as non-modifying | Operations |

**Copilot Studio / AI extensions:**

| Extension | Purpose |
|-----------|---------|
| `x-ms-name-for-model` | LLM-friendly operation name (snake_case) |
| `x-ms-description-for-model` | LLM-friendly usage description |
| `x-ms-media-kind` | `"image"` or `"audio"` for media operations |

**Extended format types:** `date-no-tz`, `email`, `html`, `uri`, `uuid`

See [OPENAPI_EXTENSIONS.md](OPENAPI_EXTENSIONS.md) for detailed examples of each extension.

---

## Authentication Quick Reference

Configure auth in `apiProperties.json` under `connectionParameters` (or `connectionParameterSets` for multi-auth):

| Auth Type | `type` value | Identity Provider | Example |
|-----------|-------------|-------------------|---------|
| **API Key** | `securestring` | N/A | Most Independent Publisher connectors |
| **OAuth 2.0 (AAD)** | `oauthSetting` | `aad` | Azure services (Key Vault, Graph) |
| **OAuth 2.0 (Generic)** | `oauthSetting` | `oauth2` / `oauth2generic` | GitHub, Slack, Spotify |
| **Basic Auth** | `securestring` (x2) | N/A | Username + password |
| **Multi-Auth** | `connectionParameterSets` | Mixed | Multiple auth options for one connector |

**Note:** Multi-auth connectors use `connectionParameterSets` instead of `connectionParameters` and are **not supported in the Custom Connector Wizard** — use the paconn CLI.

**API Key example (apiProperties.json):**

```json
{
  "properties": {
    "connectionParameters": {
      "api_key": {
        "type": "securestring",
        "uiDefinition": {
          "constraints": { "clearText": false, "required": "true", "tabIndex": 2 },
          "description": "Your API key from the service dashboard",
          "displayName": "API Key",
          "tooltip": "Provide your API key"
        }
      }
    },
    "iconBrandColor": "#da3b01",
    "capabilities": [],
    "publisher": "Your Name",
    "stackOwner": "Service Company Name"
  }
}
```

**Critical:** Independent Publisher `iconBrandColor` **must** be `"#da3b01"`.

See [AUTH_PATTERNS.md](AUTH_PATTERNS.md) for OAuth 2.0, AAD, and Basic Auth patterns.

---

## Policy Templates

Policy templates transform requests/responses without custom code. Defined in `apiProperties.json`:

| Template ID | Purpose |
|------------|---------|
| `dynamichosturl` | Route to dynamic host URL from connection params |
| `setheader` | Inject request/response headers |
| `setqueryparameter` | Add default query parameters |
| `routerequesttoendpoint` | Redirect request to different path |
| `setproperty` | Set body property values |
| `pollingtrigger` | Configure polling trigger behavior |
| `updatenextlink` | Fix pagination nextLink routing |

```json
"policyTemplateInstances": [
  {
    "templateId": "setheader",
    "title": "Set Content-Type Header",
    "parameters": {
      "x-ms-apimTemplateParameter.name": "Content-Type",
      "x-ms-apimTemplateParameter.value": "application/json",
      "x-ms-apimTemplateParameter.existsAction": "override",
      "x-ms-apimTemplateParameter.newValue": "application/json"
    }
  }
]
```

See [POLICY_TEMPLATES.md](POLICY_TEMPLATES.md) for all templates with examples.

---

## Custom Code (script.csx)

C# code for request/response transformation when policy templates aren't sufficient.

```csharp
public class Script : ScriptBase
{
    public override async Task<HttpResponseMessage> ExecuteAsync()
    {
        if (this.Context.OperationId == "MyOperation")
            return await HandleMyOperation().ConfigureAwait(false);

        // Forward all other requests unchanged
        return await this.Context.SendAsync(
            this.Context.Request, this.CancellationToken
        ).ConfigureAwait(false);
    }
}
```

**Constraints:** .NET Standard 2.0 | 2-minute timeout | 1 MB max file size | One script per connector

See [CUSTOM_CODE.md](CUSTOM_CODE.md) for full reference with examples.

---

## Webhook Triggers

Mark an operation as a webhook trigger with `x-ms-trigger` and define the notification payload:

```json
"/hooks": {
  "x-ms-notification-content": {
    "schema": { "$ref": "#/definitions/WebhookPayload" }
  },
  "post": {
    "operationId": "WebhookTrigger",
    "summary": "When an event occurs",
    "x-ms-trigger": "single",
    "x-ms-trigger-hint": "To see it work, create a new item in the service.",
    "parameters": [
      {
        "name": "body",
        "in": "body",
        "schema": {
          "type": "object",
          "properties": {
            "callbackUrl": {
              "type": "string",
              "x-ms-notification-url": true,
              "x-ms-visibility": "internal"
            }
          }
        }
      }
    ],
    "responses": { "201": { "description": "Created" } }
  }
}
```

**Requirements:** Must also define a DELETE operation so the platform can unregister webhooks. The API must return a `Location` header in the 201 response pointing to the webhook resource.

See [WEBHOOK_TRIGGERS.md](WEBHOOK_TRIGGERS.md) for complete patterns.

---

## Certification & Submission

### PR Checklist

- [ ] All files in correct directory (`independent-publisher-connectors/` or `certified-connectors/`)
- [ ] PR targets `dev` branch (never `master`)
- [ ] `apiDefinition.swagger.json` passes swagger validation (use Solution Checker)
- [ ] `apiProperties.json` matches schema
- [ ] `readme.md` / `intro.md` follows template (Publisher, Prerequisites, Operations, Credentials, Known Issues)
- [ ] No secrets or real API keys in any file
- [ ] Connector title is ≤30 characters, no restricted words ("API", "Connector", "Copilot Studio")
- [ ] Connector description is 30-500 characters
- [ ] Host URL is a **production** URL (no staging/dev/test URLs)
- [ ] Response schemas provided on success responses only (not on `default` response)
- [ ] `x-ms-connector-metadata` array present with Website, Privacy policy, Categories
- [ ] All summaries are ≤80 chars, end with alphanumeric, no slashes
- [ ] All descriptions are full sentences ending in punctuation, no URLs
- [ ] Summary and description text are **not identical** for any operation or parameter
- [ ] All path parameters have `required: true` and `x-ms-url-encoding: "single"`
- [ ] All `operationId` values are PascalCase with no non-alphanumeric characters
- [ ] For OAuth connectors: `"redirectMode": "GlobalPerConnector"` (not `"Global"`)
- [ ] For Independent Publisher: `iconBrandColor` is `"#da3b01"`
- [ ] For Independent Publisher with OAuth: detailed instructions for creating the OAuth app
- [ ] At least **10 successful calls per operation** tested
- [ ] Screenshots of 3+ unique operations working in a Flow (Independent Publisher)
- [ ] All strings are in English, free of spelling/grammar errors
- [ ] JSON uses 4-space indentation, no trailing whitespace
- [ ] Package validated with [ConnectorPackageValidator.ps1](https://github.com/microsoft/PowerPlatformConnectors/blob/dev/scripts/ConnectorPackageValidator.ps1)

### paconn CLI Deployment

```bash
# Install the CLI
pip install paconn

# Create a connector
paconn create --api-def apiDefinition.swagger.json --api-prop apiProperties.json

# With custom code and icon
paconn create --api-def apiDefinition.swagger.json --api-prop apiProperties.json \
  --script script.csx --icon icon.png

# Update an existing connector
paconn update --api-def apiDefinition.swagger.json --api-prop apiProperties.json \
  --connector-id <connector-id>
```

### README Template

```markdown
# Service Name
Short description of the service (2-3 sentences).

## Publisher: Your Name

## Prerequisites
- An account with [Service Name](https://service.com)
- An API key (obtained from Settings > API Keys)

## Supported Operations
### List Items
Retrieves all items from your account.

### Create Item
Creates a new item with the specified properties.

## Obtaining Credentials
Step-by-step instructions for getting API credentials.

## Known Issues and Limitations
- Rate limited to 100 requests per minute
- Maximum 1000 items per response

## Deployment Instructions
Run the following commands:
\`paconn create --api-def apiDefinition.swagger.json --api-prop apiProperties.json\`
```

---

## Best Practices

**Do:**
- Use `x-ms-summary` on every parameter and schema property (controls designer labels)
- Use `x-ms-visibility: "internal"` for parameters with fixed values (e.g., `api-version`)
- Provide default values for all `internal` required parameters
- Include complete response schemas on **success responses only** (enables dynamic content in flows)
- Use `$ref` definitions and `$ref` parameters for reusable schemas and shared parameters
- Test with the custom connector wizard before submitting PR — run **at least 10 successful calls per operation**
- Run **Solution Checker** and **ConnectorPackageValidator.ps1** before submitting
- Use policy templates before reaching for custom code
- Use PascalCase for `operationId` — remove all non-alpha characters
- Keep `summary` to 80 characters or fewer, sentence case, ending with an alphanumeric character
- Ensure summaries contain only **alphanumeric characters or parentheses** — no slashes
- Start summaries with **"List"** (returns many) or **"Get"** (returns one); for triggers: **"When a [event]"**
- Make sure `summary` and `description` have **different text** on every operation/parameter
- Write `description` as full sentences ending in punctuation — no URLs
- Add `title` (Title Case) and `description` (full sentence) to all definition properties (skip for `$ref`)
- Add `"x-ms-url-encoding": "single"` and `"required": true` to all path parameters
- Add `minimum`/`maximum` when number/integer ranges are known
- Ensure all text is in English and free of grammatical/spelling errors
- Capitalize abbreviations to avoid translation issues
- Use `"redirectMode": "GlobalPerConnector"` for all OAuth connectors
- Use **4-space soft tabs** and remove trailing whitespace in JSON files
- Use only **production** host URLs (no staging, dev, or test URLs)

**Don't:**
- Use OpenAPI 3.0 — must be Swagger 2.0
- Include real API keys or secrets in files (use dummy values: `<<Enter your API key>>`)
- Submit PR to `master` branch (always target `dev`)
- Leave `x-ms-connector-metadata` empty or missing
- Use wrong brand color for Independent Publisher (must be `#da3b01`)
- Skip response schemas (breaks dynamic content in Power Automate)
- Put schemas on the `default` response — schemas belong on explicit success responses (200/201) only
- Exceed 1 MB for the OpenAPI definition file
- Put schemas on error responses (4xx/5xx) — descriptions only
- Leave `default` values on definition properties (only on operation parameters)
- Include empty properties unless they are required
- Put URLs in `title` or `description` fields
- Name any parameter `connectionId` (reserved by the platform)
- Include body or form data parameters on GET operations
- Use `"redirectMode": "Global"` — must be `"GlobalPerConnector"` (mandatory since Feb 2024)
- Exceed 30 characters for connector title

See [COMMON_MISTAKES.md](COMMON_MISTAKES.md) for a full error catalog with fixes.

---

## Related Files

- [OPENAPI_EXTENSIONS.md](OPENAPI_EXTENSIONS.md) — Detailed reference for all `x-ms-*` extensions with examples
- [AUTH_PATTERNS.md](AUTH_PATTERNS.md) — API Key, OAuth 2.0 (AAD/Generic), Basic Auth, and Multi-Auth patterns
- [POLICY_TEMPLATES.md](POLICY_TEMPLATES.md) — All policy template IDs with configuration examples
- [CUSTOM_CODE.md](CUSTOM_CODE.md) — C# `script.csx` patterns, ScriptBase class, supported namespaces
- [WEBHOOK_TRIGGERS.md](WEBHOOK_TRIGGERS.md) — Webhook trigger registration, notification, and deletion patterns
- [EXAMPLES.md](EXAMPLES.md) — Complete working connector examples for common scenarios
- [COMMON_MISTAKES.md](COMMON_MISTAKES.md) — Error catalog with fixes and validation tips
