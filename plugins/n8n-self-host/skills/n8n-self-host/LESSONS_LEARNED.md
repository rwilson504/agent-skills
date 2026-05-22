# Lessons Learned — n8n-self-host

Continuous-learning log for the self-hosting skill. Newest entries on top.
Append a new entry whenever a deployment, upgrade, or operational session
uncovers a hosting gotcha, env-var quirk, version-specific change, or
workaround. Follow the [Lesson entry template](../../agents/n8n.agent.md#lesson-entry-template).

When a lesson goes stale (bug fixed, default changed), add a dated follow-up
note under the same entry rather than deleting it.

---

<!-- New entries go HERE, above the divider. -->

---

## Seed entries

### 2026-01-01 — Lost `N8N_ENCRYPTION_KEY` = lost credentials

- **Context:** Bootstrapping a new n8n instance and not setting `N8N_ENCRYPTION_KEY` explicitly.
- **Symptom / Observation:** On first boot without `N8N_ENCRYPTION_KEY`, n8n generates one and writes it to `/home/node/.n8n/config`. If that file is lost (volume deleted, host migration without copying config), credentials encrypted with that key are unrecoverable — they appear in the UI but cannot be decrypted.
- **Root cause:** The encryption key is required to decrypt all stored credentials. There is no recovery path.
- **Fix / Workaround:** ALWAYS set `N8N_ENCRYPTION_KEY` explicitly via env var, generated with `openssl rand -hex 32`. Store in a secrets manager. Back it up separately from the database.
- **Citation:** <https://docs.n8n.io/hosting/configuration/configuration-examples/encryption-key/>
- **Applies to:** All n8n versions.
