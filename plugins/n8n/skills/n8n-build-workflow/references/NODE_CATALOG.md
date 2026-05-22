# Node Catalog — Hot List

Quick lookup of `type` strings and current `typeVersion` for the nodes you'll
reach for most. Not exhaustive — for full coverage see
<https://docs.n8n.io/integrations/builtin/node-types/>.

> When in doubt about the current `typeVersion`, drag the node into a fresh
> workflow in the editor, export the workflow, and inspect the JSON.

---

## Triggers (core)

| Display name | `type` | typeVersion (≈) |
|---|---|---|
| Manual Trigger | `n8n-nodes-base.manualTrigger` | 1 |
| Schedule Trigger | `n8n-nodes-base.scheduleTrigger` | 1.2 |
| Webhook | `n8n-nodes-base.webhook` | 2 |
| n8n Form Trigger | `n8n-nodes-base.formTrigger` | 2.2 |
| Chat Trigger | `@n8n/n8n-nodes-langchain.chatTrigger` | 1.1 |
| Error Trigger | `n8n-nodes-base.errorTrigger` | 1 |
| Execute Sub-workflow Trigger | `n8n-nodes-base.executeWorkflowTrigger` | 1.1 |
| Email Trigger (IMAP) | `n8n-nodes-base.emailReadImap` | 2 |
| Local File Trigger | `n8n-nodes-base.localFileTrigger` | 1 |
| RSS Feed Trigger | `n8n-nodes-base.rssFeedReadTrigger` | 1 |

## Flow logic

| Display name | `type` | typeVersion (≈) |
|---|---|---|
| IF | `n8n-nodes-base.if` | 2.2 |
| Switch | `n8n-nodes-base.switch` | 3.2 |
| Filter | `n8n-nodes-base.filter` | 2.2 |
| Merge | `n8n-nodes-base.merge` | 3.2 |
| Loop Over Items (Split In Batches) | `n8n-nodes-base.splitInBatches` | 3 |
| Wait | `n8n-nodes-base.wait` | 1.1 |
| Stop and Error | `n8n-nodes-base.stopAndError` | 1 |
| No Operation, do nothing | `n8n-nodes-base.noOp` | 1 |
| Execute Sub-workflow | `n8n-nodes-base.executeWorkflow` | 1.2 |
| Compare Datasets | `n8n-nodes-base.compareDatasets` | 2.4 |

## Data transformation

| Display name | `type` | typeVersion (≈) |
|---|---|---|
| Edit Fields (Set) | `n8n-nodes-base.set` | 3.4 |
| Code | `n8n-nodes-base.code` | 2 |
| Aggregate | `n8n-nodes-base.aggregate` | 1 |
| Summarize | `n8n-nodes-base.summarize` | 1.1 |
| Remove Duplicates | `n8n-nodes-base.removeDuplicates` | 2 |
| Sort | `n8n-nodes-base.sort` | 1 |
| Limit | `n8n-nodes-base.limit` | 1 |
| Item Lists (Split Out / Item Lists) | `n8n-nodes-base.itemLists` | 3.1 |
| Convert to File | `n8n-nodes-base.convertToFile` | 1.1 |
| Extract from File | `n8n-nodes-base.extractFromFile` | 1 |
| Crypto | `n8n-nodes-base.crypto` | 1 |
| Compression | `n8n-nodes-base.compression` | 1.1 |
| HTML | `n8n-nodes-base.html` | 1.2 |
| Markdown | `n8n-nodes-base.markdown` | 1 |
| XML | `n8n-nodes-base.xml` | 1 |

## I/O & integrations

| Display name | `type` | typeVersion (≈) |
|---|---|---|
| HTTP Request | `n8n-nodes-base.httpRequest` | 4.2 |
| Respond to Webhook | `n8n-nodes-base.respondToWebhook` | 1.2 |
| Send Email (SMTP) | `n8n-nodes-base.emailSend` | 2.1 |
| Read/Write Files from Disk | `n8n-nodes-base.readWriteFile` | 1 |
| FTP | `n8n-nodes-base.ftp` | 1 |
| SSH | `n8n-nodes-base.ssh` | 1 |
| Execute Command | `n8n-nodes-base.executeCommand` | 1 |
| n8n (API) | `n8n-nodes-base.n8n` | 1 |
| Webhook Response (legacy alias) | `n8n-nodes-base.respondToWebhook` | 1.2 |

## App nodes — most-asked

| Service | `type` | typeVersion (≈) |
|---|---|---|
| Slack | `n8n-nodes-base.slack` | 2.3 |
| Gmail | `n8n-nodes-base.gmail` | 2.1 |
| Google Sheets | `n8n-nodes-base.googleSheets` | 4.5 |
| Google Drive | `n8n-nodes-base.googleDrive` | 3 |
| Microsoft Teams | `n8n-nodes-base.microsoftTeams` | 1.1 |
| Microsoft Outlook | `n8n-nodes-base.microsoftOutlook` | 2 |
| Microsoft Excel 365 | `n8n-nodes-base.microsoftExcel` | 2 |
| SharePoint | `n8n-nodes-base.microsoftSharePoint` | 1 |
| GitHub | `n8n-nodes-base.github` | 1 |
| Notion | `n8n-nodes-base.notion` | 2.2 |
| Airtable | `n8n-nodes-base.airtable` | 2.1 |
| HubSpot | `n8n-nodes-base.hubspot` | 2.1 |
| Salesforce | `n8n-nodes-base.salesforce` | 1 |
| Postgres | `n8n-nodes-base.postgres` | 2.5 |
| MySQL | `n8n-nodes-base.mySql` | 2.4 |
| MongoDB | `n8n-nodes-base.mongoDb` | 1.2 |
| Redis | `n8n-nodes-base.redis` | 1.1 |
| AWS S3 | `n8n-nodes-base.awsS3` | 2 |
| Discord | `n8n-nodes-base.discord` | 2 |

## AI cluster (`@n8n/n8n-nodes-langchain.*`)

### Root nodes

| Display name | `type` | typeVersion (≈) |
|---|---|---|
| AI Agent | `@n8n/n8n-nodes-langchain.agent` | 2 |
| Basic LLM Chain | `@n8n/n8n-nodes-langchain.chainLlm` | 1.5 |
| Question and Answer Chain | `@n8n/n8n-nodes-langchain.chainRetrievalQa` | 1.5 |
| Summarization Chain | `@n8n/n8n-nodes-langchain.chainSummarization` | 2.1 |
| Information Extractor | `@n8n/n8n-nodes-langchain.informationExtractor` | 1.1 |
| Text Classifier | `@n8n/n8n-nodes-langchain.textClassifier` | 1.1 |
| Sentiment Analysis | `@n8n/n8n-nodes-langchain.sentimentAnalysis` | 1 |

### Chat Models (sub-nodes)

| Display name | `type` |
|---|---|
| OpenAI Chat Model | `@n8n/n8n-nodes-langchain.lmChatOpenAi` |
| Anthropic Chat Model | `@n8n/n8n-nodes-langchain.lmChatAnthropic` |
| Google Gemini Chat Model | `@n8n/n8n-nodes-langchain.lmChatGoogleGemini` |
| Azure OpenAI Chat Model | `@n8n/n8n-nodes-langchain.lmChatAzureOpenAi` |
| Ollama Chat Model | `@n8n/n8n-nodes-langchain.lmChatOllama` |
| Groq Chat Model | `@n8n/n8n-nodes-langchain.lmChatGroq` |

### Memory

| Display name | `type` |
|---|---|
| Window Buffer Memory | `@n8n/n8n-nodes-langchain.memoryBufferWindow` |
| Postgres Chat Memory | `@n8n/n8n-nodes-langchain.memoryPostgresChat` |
| Redis Chat Memory | `@n8n/n8n-nodes-langchain.memoryRedisChat` |
| Zep Memory | `@n8n/n8n-nodes-langchain.memoryZep` |
| MongoDB Atlas Chat Memory | `@n8n/n8n-nodes-langchain.memoryMongoDbChat` |

### Tools

| Display name | `type` |
|---|---|
| Calculator | `@n8n/n8n-nodes-langchain.toolCalculator` |
| Code Tool | `@n8n/n8n-nodes-langchain.toolCode` |
| HTTP Request Tool | `@n8n/n8n-nodes-langchain.toolHttpRequest` |
| Workflow Tool (call a sub-workflow) | `@n8n/n8n-nodes-langchain.toolWorkflow` |
| Vector Store Tool | `@n8n/n8n-nodes-langchain.toolVectorStore` |
| Wikipedia | `@n8n/n8n-nodes-langchain.toolWikipedia` |
| SerpAPI | `@n8n/n8n-nodes-langchain.toolSerpApi` |
| Wolfram Alpha | `@n8n/n8n-nodes-langchain.toolWolframAlpha` |

### Vector Stores

| Display name | `type` |
|---|---|
| In-Memory Vector Store | `@n8n/n8n-nodes-langchain.vectorStoreInMemory` |
| Pinecone Vector Store | `@n8n/n8n-nodes-langchain.vectorStorePinecone` |
| Qdrant Vector Store | `@n8n/n8n-nodes-langchain.vectorStoreQdrant` |
| Supabase Vector Store | `@n8n/n8n-nodes-langchain.vectorStoreSupabase` |
| PGVector Vector Store | `@n8n/n8n-nodes-langchain.vectorStorePGVector` |
| Milvus Vector Store | `@n8n/n8n-nodes-langchain.vectorStoreMilvus` |

### Embeddings, Loaders, Splitters, Parsers

| Display name | `type` |
|---|---|
| Embeddings OpenAI | `@n8n/n8n-nodes-langchain.embeddingsOpenAi` |
| Embeddings Cohere | `@n8n/n8n-nodes-langchain.embeddingsCohere` |
| Embeddings Google Gemini | `@n8n/n8n-nodes-langchain.embeddingsGoogleGemini` |
| Default Data Loader | `@n8n/n8n-nodes-langchain.documentDefaultDataLoader` |
| Recursive Character Text Splitter | `@n8n/n8n-nodes-langchain.textSplitterRecursiveCharacterTextSplitter` |
| Structured Output Parser | `@n8n/n8n-nodes-langchain.outputParserStructured` |
| Auto-fixing Output Parser | `@n8n/n8n-nodes-langchain.outputParserAutofixing` |

---

## Cosmetic

| Display name | `type` | typeVersion |
|---|---|---|
| Sticky Note | `n8n-nodes-base.stickyNote` | 1 |
