# Lessons Learned — n8n-create-nodes

Continuous-learning log for the community-node skill. Newest entries on top.
Append a new entry whenever a node-build session uncovers a non-obvious
behavior, version-specific quirk, packaging gotcha, or workaround. Follow
the [Lesson entry template](../../agents/n8n.agent.md#lesson-entry-template).

When a lesson goes stale (bug fixed, behavior changed), add a dated follow-up
note under the same entry rather than deleting it.

---

<!-- New entries go HERE, above the divider. -->

---

## Seed entries

### 2026-01-01 — Class name must exactly match file name

- **Context:** Authoring a new community node.
- **Symptom / Observation:** Node fails to load with "Class name doesn't match file name" or similar.
- **Root cause:** n8n loads nodes by reflecting on filenames and expects the exported class name (minus `.node.ts` extension) to match exactly.
- **Fix / Workaround:** For `MyService.node.ts`, the class MUST be `export class MyService implements INodeType` — not `MyServiceNode`, not `myService`.
- **Citation:** Verified empirically; called out in `references/COMMON_MISTAKES.md`.
- **Applies to:** All n8n versions.
