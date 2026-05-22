# AI Workflows (LangChain cluster)

n8n's `@n8n/n8n-nodes-langchain.*` bundle provides **root nodes** (Agent,
Chains, Information Extractor, Classifier, Sentiment Analysis) and
**sub-nodes** (Chat Models, Memory, Tools, Output Parsers, Embeddings,
Document Loaders, Text Splitters, Vector Stores, Retrievers).

Sub-nodes attach to root nodes via **non-`main` connection types**. They
don't appear in the data flow — they configure the root node.

> Authoritative reference: <https://docs.n8n.io/advanced-ai/>

---

## Connection types (recap)

| Type | Direction |
|---|---|
| `ai_languageModel` | Chat Model → Agent / Chain |
| `ai_memory` | Memory → Agent / Chain |
| `ai_tool` | Tool → Agent |
| `ai_outputParser` | Output Parser → Chain / Information Extractor |
| `ai_embedding` | Embeddings → Vector Store / Retriever |
| `ai_vectorStore` | Vector Store → QA Chain / Vector Store Tool / Vector Store Retriever |
| `ai_document` | Document Loader → Vector Store (ingest mode) |
| `ai_textSplitter` | Text Splitter → Document Loader |

In `connections` JSON these are top-level keys under the source node, in
parallel to `main`:

```json
"connections": {
  "OpenAI Chat Model": {
    "ai_languageModel": [[{ "node": "AI Agent", "type": "ai_languageModel", "index": 0 }]]
  }
}
```

---

## Topology: Chat Agent with tools and memory

```
[Chat Trigger] ──main──▶ [AI Agent] ──main──▶ [downstream...]
                              ▲
              ai_languageModel│
                              │
                  [OpenAI Chat Model]

                              ▲
                       ai_memory│
                              │
                  [Window Buffer Memory]

                              ▲
                         ai_tool│
                              │
                  [HTTP Request Tool]
                  [Calculator]
                  [Workflow Tool: lookup-user]
```

Minimum JSON skeleton:

```json
{
  "nodes": [
    { "id": "<uuid>", "name": "Chat Trigger",
      "type": "@n8n/n8n-nodes-langchain.chatTrigger", "typeVersion": 1.1,
      "position": [240, 300], "parameters": {} },

    { "id": "<uuid>", "name": "AI Agent",
      "type": "@n8n/n8n-nodes-langchain.agent", "typeVersion": 2,
      "position": [460, 300],
      "parameters": {
        "promptType": "auto",
        "options": { "systemMessage": "You are a helpful assistant." }
      } },

    { "id": "<uuid>", "name": "OpenAI Chat Model",
      "type": "@n8n/n8n-nodes-langchain.lmChatOpenAi", "typeVersion": 1.2,
      "position": [340, 500],
      "parameters": { "model": "gpt-4o-mini", "options": { "temperature": 0.2 } } },

    { "id": "<uuid>", "name": "Window Buffer Memory",
      "type": "@n8n/n8n-nodes-langchain.memoryBufferWindow", "typeVersion": 1.3,
      "position": [460, 500], "parameters": { "contextWindowLength": 20 } },

    { "id": "<uuid>", "name": "Calculator",
      "type": "@n8n/n8n-nodes-langchain.toolCalculator", "typeVersion": 1,
      "position": [580, 500], "parameters": {} }
  ],
  "connections": {
    "Chat Trigger": {
      "main": [[{ "node": "AI Agent", "type": "main", "index": 0 }]]
    },
    "OpenAI Chat Model": {
      "ai_languageModel": [[{ "node": "AI Agent", "type": "ai_languageModel", "index": 0 }]]
    },
    "Window Buffer Memory": {
      "ai_memory": [[{ "node": "AI Agent", "type": "ai_memory", "index": 0 }]]
    },
    "Calculator": {
      "ai_tool": [[{ "node": "AI Agent", "type": "ai_tool", "index": 0 }]]
    }
  }
}
```

The Agent's `promptType: "auto"` reads `$json.chatInput` from the Chat
Trigger or upstream node. Set `promptType: "define"` and provide
`text: "={{ ... }}"` to use a custom prompt expression.

---

## Topology: RAG QA

```
[Trigger] ──main──▶ [Question and Answer Chain] ──main──▶ [downstream]
                              ▲
              ai_languageModel│
                  [Chat Model]
                              ▲
              ai_vectorStore  │
                  [Vector Store (retrieve mode)]
                                  ▲
                  ai_embedding    │
                       [Embeddings]
```

For **ingesting** documents into the vector store, you build a separate
workflow:

```
[File source] ──main──▶ [Vector Store (insert mode)]
                              ▲
                  ai_document │
                       [Default Data Loader]
                                  ▲
                  ai_textSplitter │
                       [Recursive Character Text Splitter]
                              ▲
                  ai_embedding│
                       [Embeddings]
```

Vector Store nodes have an "Operation Mode" parameter: **Insert** (writes),
**Retrieve** (reads, used as `ai_vectorStore` sub-node), **Retrieve As Tool**
(makes it appear as an `ai_tool` sub-node so an Agent can search it).

---

## Tools — make any sub-workflow callable

The **Workflow Tool** (`@n8n/n8n-nodes-langchain.toolWorkflow`) lets an Agent
call a separate n8n workflow as a tool. Useful for:

- Encapsulating multi-step actions the model should treat as one verb
- Sharing tool implementations across multiple Agents
- Adding pre/post-processing the model shouldn't see

Configuration:

```json
{
  "name": "Lookup User Tool",
  "type": "@n8n/n8n-nodes-langchain.toolWorkflow",
  "typeVersion": 2,
  "parameters": {
    "name": "lookup_user",
    "description": "Look up a user by their email address. Returns name, role, last login.",
    "workflowId": { "value": "<sub-workflow-id>" },
    "fields": {
      "values": [
        { "name": "email", "type": "string", "description": "The user's email address",
          "stringValue": "={{ $fromAI('email') }}" }
      ]
    }
  }
}
```

The sub-workflow must start with `Execute Sub-workflow Trigger` and return
items with a `json` payload. The Agent will see the returned items as the
tool's output.

### `$fromAI()` for tool parameters

`$fromAI('field_name', 'optional description', 'optional default')` exposes
a parameter to the model as part of the tool's input schema. The model fills
it in when calling the tool.

```
=={{ $fromAI('city', 'City to look up weather for', 'San Francisco') }}
```

---

## Output parsers — structured outputs

Attach a **Structured Output Parser** as `ai_outputParser` to a Chain or
Information Extractor to force the model into a JSON schema:

```json
{
  "name": "Structured Output Parser",
  "type": "@n8n/n8n-nodes-langchain.outputParserStructured",
  "typeVersion": 1.2,
  "parameters": {
    "schemaType": "manual",
    "inputSchema": "{ \"type\": \"object\", \"properties\": { \"sentiment\": { \"type\": \"string\", \"enum\": [\"positive\", \"neutral\", \"negative\"] }, \"confidence\": { \"type\": \"number\" } }, \"required\": [\"sentiment\", \"confidence\"] }"
  }
}
```

Wrap it in an **Auto-fixing Output Parser** to recover from invalid JSON
returned by the model (a second LLM call repairs the output).

---

## Common AI workflow mistakes

### 1. Missing Chat Model

An Agent with no `ai_languageModel` sub-node won't execute and surfaces an
unhelpful error. Always wire one.

### 2. Memory not session-scoped

Default Window Buffer Memory uses `sessionId: '={{ $json.sessionId || "default" }}'`
— if you're calling the Agent from a webhook, derive `sessionId` from the
user/conversation. Otherwise all callers share one memory.

### 3. Tool description too vague

The Agent decides whether to call a tool based on its **description**. "Tool
for users" won't get called when the model needs to look up a user. Be
specific: "Look up a user by their email address. Returns name, role, last
login. Use when the user mentions someone by email."

### 4. Workflow Tool's sub-workflow expects items in `$input.first().json`

The sub-workflow's Execute Sub-workflow Trigger receives ONE item whose
`json` contains the `fields` you defined on the Workflow Tool. Don't expect
the entire conversation context.

### 5. Vector Store dimension mismatch

If you re-index with a different embeddings model (different dimension), the
vector store will throw on every search. Drop and re-create the index, or
provision a separate one.

### 6. Streaming response from Chat Trigger requires Respond to Webhook

To stream the Agent's response back to a chat UI, use Chat Trigger →
`responseMode: "responseNode"` and end with a Respond to Webhook node
configured for streaming. Default response mode returns the final answer
only after the entire chain completes.

### 7. Token limits silently truncate

Most Chat Model sub-nodes have a `maxTokens` (output) and an effective input
context budget. When a long retrieved context + history overflows, the model
silently truncates. Use the Summarization Chain for long histories or set
Window Buffer Memory's `contextWindowLength` to a sane value (10–20).
