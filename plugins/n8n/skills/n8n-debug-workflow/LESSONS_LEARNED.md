# Lessons Learned — n8n-debug-workflow

Continuous-learning log for the workflow-debugger skill. Newest entries on
top. Append a new entry whenever a debugging session uncovers a non-obvious
root cause, misleading error message, version-specific quirk, or workaround.
Follow the [Lesson entry template](../../agents/n8n.agent.md#lesson-entry-template).

When a previously-recorded lesson goes stale (bug fixed, behavior changed),
add a dated follow-up note under the same entry rather than deleting it.

---

<!-- New entries go HERE, above the divider. -->

---

## Seed entries

### 2026-01-01 — "On node X" prefix points at the message origin, not always the cause

- **Context:** Triaging an execution that failed in node X.
- **Symptom / Observation:** Error message starts with "On node 'X'" so the first instinct is to inspect X.
- **Root cause:** The error message origin is the node that THREW; the actual data fault is often in the immediately-upstream node (wrong shape, missing field, broken pairing).
- **Fix / Workaround:** Always click both the failing node AND the immediately-upstream node in the Executions tab. Compare expected vs actual input data.
- **Citation:** Verified empirically across many sessions.
- **Applies to:** All n8n versions.
