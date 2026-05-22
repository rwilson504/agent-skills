# Lessons Learned — n8n-build-workflow

Continuous-learning log for the workflow-builder skill. Newest entries on top.
Append a new entry whenever a session uncovers a non-obvious behavior,
version-specific quirk, workaround, or correction. Follow the [Lesson entry
template](../../agents/n8n.agent.md#lesson-entry-template) in the agent file.

When a previously-recorded lesson goes stale (bug fixed, behavior changed),
add a dated follow-up note under the same entry rather than deleting it. The
historical record matters.

---

<!-- New entries go HERE, above the divider. -->

---

## Seed entries

### 2026-01-01 — `executionOrder` must be `"v1"` on new workflows

- **Context:** Authoring fresh workflow JSON for import.
- **Symptom / Observation:** Workflows imported without `settings.executionOrder` default to legacy execution order, which evaluates merged branches in an order that surprises modern users.
- **Root cause:** Pre-v1 execution order was DFS-style and not predictable across merges.
- **Fix / Workaround:** Always emit `"settings": { "executionOrder": "v1" }` in generated JSON.
- **Citation:** <https://docs.n8n.io/flow-logic/execution-order/>
- **Applies to:** All n8n versions ≥ 1.0.
