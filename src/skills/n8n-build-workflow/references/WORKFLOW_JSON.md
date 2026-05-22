# n8n Workflow JSON Schema

The canonical shape of an n8n workflow file. n8n exports and imports this
format via the Workflow menu → Download / Import from File / Import from URL.

> Authoritative reference: <https://docs.n8n.io/workflows/export-import/>

---

## Top-level

```json
{
  "name": "string",
  "nodes": [ /* Node[] */ ],
  "connections": { /* Connections */ },
  "active": false,
  "settings": { /* WorkflowSettings */ },
  "pinData": { /* PinData — optional, dev-time pinning */ },
  "staticData": null,
  "tags": [],
  "triggerCount": 0,
  "versionId": "string-uuid",
  "meta": { /* optional metadata */ },
  "id": "workflow-id-when-exported-from-instance"
}
```

| Field | Required for import | Notes |
|---|---|---|
| `name` | yes | Workflow display name |
| `nodes` | yes | Array of node objects (see below) |
| `connections` | yes | Connection map keyed by source node `name` |
| `active` | no | Always `false` on import — toggle in UI |
| `settings` | recommended | Set `executionOrder: "v1"` minimum |
| `pinData` | no | Map of `nodeName → pinned items`. Dev-time only |
| `staticData` | no | Per-workflow persistent storage. Usually `null` |
| `tags` | no | Array of `{ id, name }` or just `[]` |
| `versionId` | no | Auto-managed by instance — safe to omit on import |
| `meta` | no | Sometimes contains `templateCredsSetupCompleted: true` |
| `id` | no | If present, instance MAY honor it for re-import |

---

## Node

```json
{
  "parameters": { /* node-specific */ },
  "id": "uuid-v4",
  "name": "string (must be unique within workflow)",
  "type": "package.nodeName",
  "typeVersion": 1,
  "position": [x, y],
  "credentials": {
    "<credentialTypeName>": {
      "id": "credential-id-in-instance",
      "name": "credential display name"
    }
  },
  "disabled": false,
  "notes": "optional sticky-note-style annotation",
  "notesInFlow": false,
  "continueOnFail": false,
  "alwaysOutputData": false,
  "executeOnce": false,
  "retryOnFail": false,
  "maxTries": 3,
  "waitBetweenTries": 1000,
  "onError": "stopWorkflow",
  "webhookId": "uuid (Webhook/Form/Chat trigger nodes only)"
}
```

### Field rules

- **`id`** — UUID v4. Must be unique. n8n uses it for execution-history
  joins. Don't reuse across nodes.
- **`name`** — Unique within the workflow. Connections key on `name`, not
  `id`. Renaming a node means rewriting every `connections` entry referencing
  it.
- **`type`** — `n8n-nodes-base.<name>` for built-ins,
  `@n8n/n8n-nodes-langchain.<name>` for AI cluster nodes,
  `n8n-nodes-<package>.<name>` for community nodes. Look up exact ids at
  <https://docs.n8n.io/integrations/builtin/node-types/>.
- **`typeVersion`** — Match the latest documented version unless the user
  pinned an older one. Older typeVersions accept different parameter shapes.
- **`position`** — `[x, y]` in canvas pixels. ~220 horizontal spacing,
  ~160 vertical reads well.
- **`credentials`** — Reference by credential **type** (e.g. `slackApi`,
  `httpHeaderAuth`, `openAiApi`) with `id` and `name`. The `id` is the
  credential record id in the target instance — usually unknown until after
  import. The user will need to re-select credentials post-import (yellow
  warning triangle on the node).
- **`onError`** — `"stopWorkflow"` (default), `"continueRegularOutput"`,
  `"continueErrorOutput"`. The last sends failures down the second output
  port (visible as a red dot in the editor).
- **`webhookId`** — UUID auto-generated for Webhook, Form, and Chat Trigger
  nodes. n8n needs this to register the callback URL.

---

## Connections

```json
"connections": {
  "<sourceNodeName>": {
    "<connectionType>": [
      [ /* connections from output port 0 */
        { "node": "<targetNodeName>", "type": "<targetConnectionType>", "index": <targetInputIndex> }
      ],
      [ /* connections from output port 1 (if multi-output) */ ]
    ]
  }
}
```

### Connection types

| Type | Meaning |
|---|---|
| `main` | Standard data flow (almost everything) |
| `ai_languageModel` | Chat Model → Agent/Chain |
| `ai_memory` | Memory → Agent/Chain |
| `ai_tool` | Tool → Agent |
| `ai_outputParser` | Output Parser → Chain |
| `ai_embedding` | Embeddings → Vector Store |
| `ai_vectorStore` | Vector Store → Retriever/QA |
| `ai_document` | Document Loader → Vector Store ingest |
| `ai_textSplitter` | Text Splitter → Document Loader |

### Output-port indexing

- **Linear node:** one output, index 0 — `main: [[ ... ]]`.
- **IF:** two outputs — index 0 = true, index 1 = false.
- **Switch:** N outputs, in the order the rules/cases are defined in
  `parameters`.
- **Loop Over Items (Split In Batches):** two outputs — index 0 = each batch
  during iteration, index 1 = "done" (after the last batch).
- **`onError: "continueErrorOutput"`:** adds a second output containing the
  error item.

---

## Settings

```json
"settings": {
  "executionOrder": "v1",
  "saveDataErrorExecution": "all",
  "saveDataSuccessExecution": "all",
  "saveManualExecutions": true,
  "saveExecutionProgress": true,
  "callerPolicy": "workflowsFromSameOwner",
  "errorWorkflow": "<workflowId>",
  "timezone": "America/New_York",
  "executionTimeout": -1
}
```

| Field | Notes |
|---|---|
| `executionOrder` | Use `"v1"` for all new workflows |
| `saveDataErrorExecution` / `saveDataSuccessExecution` | `"all"` \| `"none"` |
| `errorWorkflow` | ID of a workflow whose Error Trigger fires when this one errors |
| `callerPolicy` | Who can call this workflow via Execute Sub-workflow |
| `timezone` | Overrides instance default for Schedule node |
| `executionTimeout` | Seconds. `-1` = use instance default (`EXECUTIONS_TIMEOUT`) |

---

## Pin Data

```json
"pinData": {
  "Webhook": [
    { "json": { "body": { "user": "alice" } } }
  ]
}
```

- Keys are node `name`s.
- Values are arrays of items in the standard `{ json, binary? }` shape.
- Pinned data is used during manual executions in the editor — n8n returns
  pinned items instead of actually executing the node. Useful for testing
  downstream changes without re-firing a webhook.
- Pinned data persists with the workflow export. Strip it before
  production import if you don't want it there.

---

## Sticky Note

```json
{
  "parameters": {
    "content": "## Markdown\nSticky note body",
    "height": 200,
    "width": 320,
    "color": 5
  },
  "id": "uuid",
  "name": "Sticky Note",
  "type": "n8n-nodes-base.stickyNote",
  "typeVersion": 1,
  "position": [x, y]
}
```

`color` values 1–7 map to the color picker palette.

---

## Validating before delivery

Before handing JSON to the user, mentally check:

1. Every node `id` is a valid UUID v4 and unique within the file.
2. Every node `name` is unique within the file.
3. Every `connections` entry's `source` and `node` references match a name
   in `nodes`.
4. Every multi-output source uses the right array layering — outer array
   length = number of output ports used.
5. No connection references a credential type that wasn't declared on the
   target node.
6. `settings.executionOrder` is set to `"v1"`.
7. If using AI cluster nodes, every Agent/Chain has at minimum a
   `ai_languageModel` sub-node wired in.
