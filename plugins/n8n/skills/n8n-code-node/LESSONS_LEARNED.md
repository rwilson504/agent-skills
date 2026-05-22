# Lessons Learned — n8n-code-node

Continuous-learning log for the Code-node skill. Newest entries on top.
Append a new entry whenever a session uncovers a non-obvious Code-node
behavior, mode-specific quirk, helper edge case, or workaround. Follow the
[Lesson entry template](../../agents/n8n.agent.md#lesson-entry-template).

When a lesson goes stale (bug fixed, behavior changed), add a dated follow-up
note under the same entry rather than deleting it.

---

<!-- New entries go HERE, above the divider. -->

---

## Seed entries

### 2026-01-01 — `$input.all()` in `runOnceForEachItem` returns one item

- **Context:** Iterating "all upstream items" from inside a Code node configured for per-item mode.
- **Symptom / Observation:** `$input.all().length` is always 1.
- **Root cause:** In `runOnceForEachItem` mode, each invocation receives only the current item. `$input.all()` returns `[currentItem]`, not the full upstream array.
- **Fix / Workaround:** Use `$('UpstreamNode').all()` to access the full upstream array from per-item mode.
- **Citation:** <https://docs.n8n.io/code/code-node/#mode>
- **Applies to:** All n8n versions.
