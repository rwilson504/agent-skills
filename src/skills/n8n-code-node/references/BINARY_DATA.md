# Binary Data in the Code Node

n8n stores binary attachments on items via a named `binary` map. The
in-memory representation may be base64 (default) OR a filesystem/S3 pointer
(when `N8N_DEFAULT_BINARY_DATA_MODE=filesystem` or `s3`). **Always use the
helpers** — never hand-construct or hand-decode the `data` field.

> Authoritative reference:
> <https://docs.n8n.io/code/builtin/code-node-methods/#binary-helpers>

---

## Binary structure

```json
{
  "json": { /* ... */ },
  "binary": {
    "data": {
      "data": "<base64 or pointer>",
      "mimeType": "application/pdf",
      "fileName": "report.pdf",
      "fileExtension": "pdf",
      "directory": "/path/on/disk"        // populated in filesystem mode
    },
    "thumbnail": { /* second binary key */ }
  }
}
```

The keys (`data`, `thumbnail`) are arbitrary — they're how downstream nodes
reference the attachment. n8n's upload-friendly nodes (Read/Write Files,
HTTP Request binary upload, Convert to File, Email Send attachment) accept
a "Binary Property" parameter naming the key.

---

## Reading binary

### As a Buffer (full content in memory)

```js
const itemIndex = 0;     // index of input item
const binaryKey = 'data';
const buffer = await this.helpers.getBinaryDataBuffer(itemIndex, binaryKey);

// Buffer is a Node Buffer
const text = buffer.toString('utf8');
const size = buffer.length;
```

### As a stream (for large files)

```js
const stream = await this.helpers.getBinaryStream(itemIndex, binaryKey);
// stream is a Node.js Readable. Pipe to another stream, or read chunk-by-chunk.
```

### Reading metadata only

```js
const meta = await this.helpers.getBinaryMetadata(itemIndex, binaryKey);
// { fileSize, mimeType, fileName, fileExtension }
```

(In `runOnceForEachItem`, use `0` as itemIndex — there's only the current
item.)

---

## Writing binary

```js
const text = 'Hello, world!';
const buffer = Buffer.from(text, 'utf8');

const binaryData = await this.helpers.prepareBinaryData(
  buffer,
  'greeting.txt',         // optional file name
  'text/plain'            // optional MIME; auto-detected if omitted
);

return [{
  json: { ok: true },
  binary: { data: binaryData }
}];
```

`prepareBinaryData` handles filesystem/S3 spillover automatically — the
returned object has the right `data` field whether your instance is in
memory mode or filesystem mode.

### From a fetch response

```js
const resp = await fetch('https://example.com/file.pdf');
const arrayBuffer = await resp.arrayBuffer();
const buffer = Buffer.from(arrayBuffer);

const binaryData = await this.helpers.prepareBinaryData(buffer, 'file.pdf', 'application/pdf');

return [{ json: {}, binary: { data: binaryData } }];
```

### From `this.helpers.httpRequest` with binary response

```js
const buffer = await this.helpers.httpRequest({
  url: 'https://example.com/file.pdf',
  encoding: 'arraybuffer',
});

const binaryData = await this.helpers.prepareBinaryData(
  Buffer.from(buffer),
  'file.pdf'
);

return [{ json: {}, binary: { data: binaryData } }];
```

---

## Multiple attachments per item

```js
const greeting = await this.helpers.prepareBinaryData(Buffer.from('hi'), 'greeting.txt', 'text/plain');
const farewell = await this.helpers.prepareBinaryData(Buffer.from('bye'), 'farewell.txt', 'text/plain');

return [{
  json: {},
  binary: { greeting, farewell }       // two named keys
}];
```

Downstream nodes consuming attachments will accept either key name in their
"Binary Property" field.

---

## Common mistakes

### 1. Hand-constructing base64

```js
// ✗ Wrong — breaks filesystem mode
return [{
  binary: {
    data: { data: Buffer.from('hi').toString('base64'), mimeType: 'text/plain' }
  }
}];

// ✓ Right — use the helper
const binary = await this.helpers.prepareBinaryData(Buffer.from('hi'), 'hi.txt', 'text/plain');
return [{ json: {}, binary: { data: binary } }];
```

### 2. Forgetting the `json` field

```js
// ✗ Wrong — item without json field
return [{ binary: { data: binaryData } }];

// ✓ Right — always include json, even if empty
return [{ json: {}, binary: { data: binaryData } }];
```

### 3. Reading `binary.data.data` directly

```js
// ✗ Wrong — may be a pointer, not actual data in filesystem mode
const base64 = $binary.data.data;
const buffer = Buffer.from(base64, 'base64');

// ✓ Right
const buffer = await this.helpers.getBinaryDataBuffer(0, 'data');
```

### 4. Loading huge binary fully into memory

For files >10 MB, prefer streaming:

```js
const stream = await this.helpers.getBinaryStream(0, 'data');
// process chunks
```

Loading 500 MB into a Buffer crashes the n8n process.

### 5. MIME mismatch

If you pass `'text/plain'` but the file is actually PDF bytes, downstream
nodes (Convert to File, Email attachment) will mis-handle. Detect or pass
the correct MIME:

```js
const mime = await this.helpers.detectBinaryMimeType(buffer);
// fallback to a default if needed
const binary = await this.helpers.prepareBinaryData(buffer, fileName, mime ?? 'application/octet-stream');
```

---

## Filesystem mode interactions

When `N8N_DEFAULT_BINARY_DATA_MODE=filesystem`:

- `binary.data.data` is a relative path under `/n8n-binary-data/<execution>/`,
  not base64 content.
- `binary.data.directory` and a few internal fields are populated.
- Helpers transparently read/write to the FS.
- `N8N_BINARY_DATA_TTL` (minutes) controls auto-cleanup of orphaned
  binaries.

When `N8N_DEFAULT_BINARY_DATA_MODE=s3`:

- Binary spills to an S3 bucket (configured via `N8N_EXTERNAL_STORAGE_S3_*`
  env vars).
- Helpers transparently read/write to S3.

Your Code-node code is identical across modes IF you use helpers. That's
the entire point of `getBinaryDataBuffer` / `prepareBinaryData`.
