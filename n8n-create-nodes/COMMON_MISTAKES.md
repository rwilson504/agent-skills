# Common Mistakes

Error catalog for n8n node development. See [SKILL.md](SKILL.md) for main skill.

---

## File Structure Errors

### 1. Class name doesn't match filename

**Wrong:**
```
File: MyService.node.ts
Class: export class MyServiceNode implements INodeType  // ← "Node" suffix doesn't match
```

**Fix:** Class name must exactly match the filename (minus `.node.ts`):
```
File: MyService.node.ts
Class: export class MyService implements INodeType      // ✓
```

### 2. Wrong npm package prefix

**Wrong:** `"name": "myservice-n8n-nodes"` or `"name": "n8n-myservice"`

**Fix:** Package name must start with `n8n-nodes-`:
```json
"name": "n8n-nodes-myservice"
```

### 3. Missing codex file

Every node needs a `.node.json` codex file alongside the `.node.ts` file. Without it, the node won't appear in search or have proper categorization.

### 4. Wrong paths in package.json n8n config

**Wrong:** Pointing to source files:
```json
"nodes": ["nodes/MyService/MyService.node.ts"]
```

**Fix:** Point to compiled output:
```json
"nodes": ["dist/nodes/MyService/MyService.node.js"]
```

---

## Description Errors

### 5. Missing noDataExpression on selectors

**Wrong:**
```typescript
{ displayName: 'Resource', name: 'resource', type: 'options', /* ... */ }
```

**Fix:** Always set `noDataExpression: true` on resource and operation selectors:
```typescript
{ displayName: 'Resource', name: 'resource', type: 'options', noDataExpression: true, /* ... */ }
```

### 6. Missing action field on operations

**Wrong:**
```typescript
options: [
  { name: 'Create', value: 'create' },
]
```

**Fix:** Every operation option needs an `action` field for the node action list:
```typescript
options: [
  { name: 'Create', value: 'create', action: 'Create a contact' },
]
```

### 7. NodeConnectionType.Main — type-only in some versions

In some `n8n-workflow` versions, `NodeConnectionType` is exported **only as a type** (not a runtime value). Using it as a value will cause a TypeScript error: `'NodeConnectionType' cannot be used as a value because it was exported using 'export type'`.

**Preferred (works everywhere):**
```typescript
inputs: [NodeConnectionType.Main],
outputs: [NodeConnectionType.Main],
```

**Fallback (if NodeConnectionType is type-only in your n8n-workflow version):**
```typescript
inputs: ['main'],
outputs: ['main'],
```

Check your installed `n8n-workflow` version. If the import fails at build time, use the string fallback.

### 8. Trigger node with non-empty inputs

**Wrong:**
```typescript
// Trigger node:
inputs: [NodeConnectionType.Main],  // ← Triggers don't have inputs
```

**Fix:**
```typescript
inputs: [],  // Trigger nodes have NO inputs
```

---

## Execute Method Errors

### 9. Missing continueOnFail handling

**Wrong:**
```typescript
for (let i = 0; i < items.length; i++) {
  const data = await apiRequest.call(this, 'GET', '/items');
  returnData.push(...data);  // ← No error handling, no item linking
}
```

**Fix:** Wrap each item in try/catch with `continueOnFail()`:
```typescript
for (let i = 0; i < items.length; i++) {
  try {
    const data = await apiRequest.call(this, 'GET', '/items');
    const executionData = this.helpers.constructExecutionMetaData(
      this.helpers.returnJsonArray(data),
      { itemData: { item: i } },
    );
    returnData.push(...executionData);
  } catch (error) {
    if (this.continueOnFail()) {
      returnData.push(...this.helpers.constructExecutionMetaData(
        this.helpers.returnJsonArray({ error: (error as Error).message }),
        { itemData: { item: i } },
      ));
      continue;
    }
    throw error;
  }
}
```

### 10. Missing constructExecutionMetaData

**Wrong:**
```typescript
returnData.push(...this.helpers.returnJsonArray(responseData));  // ← No item linking
```

**Fix:** Always wrap with `constructExecutionMetaData` for proper item tracking:
```typescript
const executionData = this.helpers.constructExecutionMetaData(
  this.helpers.returnJsonArray(responseData),
  { itemData: { item: i } },
);
returnData.push(...executionData);
```

### 11. Not returning nested array

**Wrong:**
```typescript
return returnData;  // ← Must be INodeExecutionData[][]
```

**Fix:**
```typescript
return [returnData];  // ← Wrap in outer array
```

---

## Credential Errors

### 12. Wrong credential expression syntax

**Wrong:**
```typescript
headers: { Authorization: '={{$credential.apiKey}}' }   // ← singular
```

**Fix:**
```typescript
headers: { Authorization: '={{$credentials.apiKey}}' }   // ← plural: $credentials
```

### 13. Missing password typeOptions on secrets

**Wrong:**
```typescript
{ displayName: 'API Key', name: 'apiKey', type: 'string', default: '' }
```

**Fix:**
```typescript
{ displayName: 'API Key', name: 'apiKey', type: 'string',
  typeOptions: { password: true }, default: '' }
```

### 14. Credential not registered in package.json

Even if the credential file exists, it won't load unless listed:
```json
"n8n": {
  "credentials": ["dist/credentials/MyServiceApi.credentials.js"]
}
```

---

## Declarative Node Errors

### 15. Including execute() in a declarative node

If `requestDefaults` is present, n8n uses the routing engine. An `execute()` method will be ignored. Either use routing OR execute, not both.

### 16. Missing routing on operation options

**Wrong (declarative):**
```typescript
options: [{ name: 'Create', value: 'create', action: 'Create item' }]  // ← No routing
```

**Fix:**
```typescript
options: [{
  name: 'Create', value: 'create', action: 'Create item',
  routing: { request: { method: 'POST', url: '/items' } },
}]
```

---

## Linter Errors (n8n-node lint)

### 17. Using deprecated request APIs

The `@n8n/node-cli` linter flags `IRequestOptions` and `requestWithAuthentication` as deprecated.

**Wrong:**
```typescript
import { IRequestOptions } from 'n8n-workflow';

const options: IRequestOptions = {
  method: 'GET',
  uri: 'https://api.example.com/items',
  json: true,
};
const response = await this.helpers.requestWithAuthentication.call(this, 'myServiceApi', options);
```

**Fix:** Use `IHttpRequestOptions` and `httpRequestWithAuthentication`:
```typescript
import type { IHttpRequestOptions } from 'n8n-workflow';

const options: IHttpRequestOptions = {
  method: 'GET',
  url: 'https://api.example.com/items',  // 'url' not 'uri'
  // No 'json: true' needed — JSON is the default
};
const response = await this.helpers.httpRequestWithAuthentication.call(this, 'myServiceApi', options);
```

### 18. Missing `usableAsTool: true` in description

The linter recommends adding `usableAsTool: true` so the node can be used as an AI agent tool.

**Fix:** Add to your node description:
```typescript
description: INodeTypeDescription = {
  // ...
  usableAsTool: true,
  // ...
};
```

### 19. Wrong description text for list operations

The linter enforces that list/getAll operation descriptions start with **"Get many"**, not "Get all" or "List".

**Wrong:**
```typescript
{ name: 'Get All', value: 'getAll', action: 'Get all contacts', description: 'Get all contacts' }
```

**Fix:**
```typescript
{ name: 'Get Many', value: 'getAll', action: 'Get many contacts', description: 'Get a list of many contacts' }
```

### 20. Missing `import type` for type-only imports

The linter enforces `import type` for symbols used only as types (not as runtime values).

**Wrong:**
```typescript
import { INodeType, INodeTypeDescription, INodeExecutionData } from 'n8n-workflow';
// ↑ INodeExecutionData only used in type annotations, not at runtime
```

**Fix:**
```typescript
import type { INodeExecutionData } from 'n8n-workflow';
import { INodeType, INodeTypeDescription } from 'n8n-workflow';
```

**Rule of thumb:** If a symbol is only used in `: TypeName` annotations, function signatures, or `as TypeName` casts, import it with `import type`. If it's used as a value (e.g., `throw new NodeOperationError(...)`, `NodeConnectionType.Main`), use a regular import.

### 21. Missing icon on credential class

The linter requires credentials to have an `icon` property. Without it, credentials display without a visual identifier.

**Fix:** Add an icon property to your credential class and place the SVG in the credentials folder:
```typescript
import type { Icon } from 'n8n-workflow';

export class MyServiceApi implements ICredentialType {
  name = 'myServiceApi';
  displayName = 'My Service API';
  icon: Icon = 'file:myservice.svg';  // SVG must be in credentials/ folder
  // ...
}
```

### 22. `no-credential-reuse` false positive on Windows drive-root paths

The `@n8n/eslint-plugin-community-nodes` `no-credential-reuse` rule has a bug when the project sits at the first directory level under a Windows drive root (e.g., `D:\my-project`). The `findPackageJson` function's while-loop condition exits before checking the project directory because `path.parse('D:\\my-project').dir === path.parse('D:\\my-project').root` (both are `D:\`).

**Workaround:** Either move the project deeper (e.g., `D:\projects\my-project`) or add an eslint-disable block:
```typescript
/* eslint-disable @n8n/community-nodes/no-credential-reuse */
credentials: [
  { name: 'myServiceApi', required: true },
],
/* eslint-enable @n8n/community-nodes/no-credential-reuse */
```

---

## Publishing Errors

### 23. `prepublishOnly` script blocks `npm publish`

The n8n-nodes-starter includes a `prepublishOnly` script that runs `n8n-node prerelease`, which blocks direct `npm publish` and tells you to use `npm run release` instead.

**Options:**
1. Use `npm run release` (uses release-it for versioning + publish)
2. Remove the `prepublishOnly` script from `package.json` and run `npm publish --access public` directly

---

## Quick Fix Reference

| Error | Fix |
|-------|-----|
| Node not appearing in editor | Check `package.json` n8n.nodes paths, rebuild, restart |
| "Cannot find credential" | Check credential `name` matches between node and credential file |
| Empty response data | Check `postReceive` rootProperty extracts correct JSON path |
| Item linking broken | Add `constructExecutionMetaData` with `{ itemData: { item: i } }` |
| displayOptions not working | Verify resource/operation values match exactly (case-sensitive) |
| Expression not resolving | Use `=` prefix: `'=/path/{{$parameter.id}}'` not `'/path/{{$parameter.id}}'` |
| `requestWithAuthentication` deprecated | Switch to `httpRequestWithAuthentication` with `IHttpRequestOptions` |
| `uri` property error | Use `url` instead of `uri` in `IHttpRequestOptions` |
| Missing `usableAsTool` lint warning | Add `usableAsTool: true` to node description |
| "Get All" lint error | Change to "Get Many" / "Get many" in name, action, description |
| `no-credential-reuse` false positive | Move project deeper than drive root, or eslint-disable |
| `prepublishOnly` blocks publish | Remove the script or use `npm run release` |
| `NodeConnectionType` type-only error | Use string `'main'` as fallback |
