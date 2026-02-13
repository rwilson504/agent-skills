# n8n-create-nodes

**Purpose:** Guide AI agents in creating production-ready n8n community nodes as npm packages, covering both declarative (REST API wrapping) and programmatic (custom logic) styles.

**Activates on:** create n8n node, build n8n integration, n8n community node, declarative node, programmatic node, trigger node, credential type, INodeType, n8n-nodes-starter, publish n8n node, webhook trigger, poll trigger, node properties, n8n node package

**File Count:** 6 files, ~1,800 lines total

**Dependencies:**
- n8n-nodes-starter repository template
- n8n-workflow SDK (INodeType, INodeTypeDescription, etc.)
- npm for publishing

**Coverage:**
- Declarative vs programmatic node styles
- Node class structure (INodeType, INodeTypeDescription)
- Resource/operation pattern with displayOptions
- All UI property types (string, options, collection, resourceLocator, etc.)
- Credential patterns (API key, OAuth2, Basic Auth)
- Trigger patterns (webhook, poll, event/stream)
- GenericFunctions helpers (apiRequest, pagination)
- Error handling (NodeApiError, continueOnFail)
- Versioned nodes (VersionedNodeType)
- Codex file and package.json configuration
- Testing and publishing workflow
- Common mistakes catalog (16 errors with fixes)

**Evaluations:** 5 scenarios
- eval-001: Create simple declarative node
- eval-002: Create programmatic node with pagination
- eval-003: Create webhook trigger node
- eval-004: Create credential type
- eval-005: Create versioned node

**Last Updated:** 2026-02-13
