---
applyTo: '**/SKILL.md'
description: Frontmatter convention for SKILL.md files in this repo so they load cleanly across GitHub Copilot CLI, Claude Code, OpenClaw, and ClawHub.
---

# `SKILL.md` frontmatter convention

Every top-level skill in this repo (`<skill>/SKILL.md`) must use this exact
frontmatter shape so the same file works across all supported AI agent
toolchains: GitHub Copilot CLI, Claude Code, AgentSkills-spec consumers,
OpenClaw, and the ClawHub registry.

## Required shape

```yaml
---
name: <skill-folder-name>
description: <single-line description, used for routing/discovery>
license: MIT-0
version: 1.0.0
metadata: { "author": "...", "version": "...", "category": "...", "tags": ["..."], "openclaw": { "homepage": "https://github.com/rwilson504/agent-skills/tree/main/<skill-folder-name>", "emoji": "..." } }
---
```

### Rules

1. **`name`, `description`, `license`, `version` MUST stay one-key-per-line.**
   OpenClaw's embedded parser only supports single-line top-level frontmatter
   keys. Do not split `description` across multiple lines.
2. **`metadata` MUST be a single-line JSON object** (valid YAML flow-mapping).
   OpenClaw documents this as a hard requirement
   ([docs](https://docs.openclaw.ai/tools/skills) → "SKILL.md format").
   Multi-line YAML mappings under `metadata:` may be silently dropped by the
   OpenClaw loader. Other agents (Copilot CLI, Claude Code) accept the
   single-line JSON form unchanged because it is also valid YAML.
3. **`name` MUST equal the skill folder name.** The marketplace
   (`.github/plugin/marketplace.json`), per-skill `plugin.json`, and the
   ClawHub slug (derived from folder name) all reference it by this name.
   Folder names must match `^[a-z0-9][a-z0-9-]*$` (ClawHub slug rule).
4. **`description` is the routing signal.** Front-load discriminative
   trigger phrases ("Use when user says ..."). Keep it on one physical line.
   ClawHub uses this verbatim as the skill summary in search results.
5. **`license: MIT-0`** — ClawHub force-publishes every skill under MIT-0
   and refuses per-skill license overrides
   ([skill-format docs](https://docs.openclaw.ai/clawhub/skill-format)).
   Setting `MIT-0` here keeps non-ClawHub consumers (Copilot CLI, Claude Code,
   manual installs) consistent with what gets published. The repo-root
   `LICENSE` file remains the canonical license for the repository itself.
6. **Top-level `version:`** mirrors `metadata.version` and matches the
   `--version` flag the ClawHub publish CLI requires. Bump both together
   on every release.
7. **Allowed top-level keys are exactly:** `name`, `description`, `license`,
   `version`, `metadata`. Anything else (e.g. `tags:`, `author:`) belongs
   inside the `metadata` JSON object so OpenClaw's strict parser is not
   confronted with unknown top-level keys.

## OpenClaw / ClawHub-specific fields (optional, all under `metadata.openclaw`)

| Field | Purpose |
|-------|---------|
| `homepage` | URL surfaced as "Website" in the OpenClaw / ClawHub Skills UI. |
| `emoji` | Emoji shown in the OpenClaw / ClawHub Skills UI. |
| `os` | Array of `"darwin" \| "linux" \| "win32"` — restricts where the skill loads. Omit for cross-platform skills. |
| `requires.bins` | Array of binaries that must all exist on `PATH` for the skill to be eligible. **Use sparingly** — gating a skill out hides its instructions from the agent entirely, and ClawScan flags the skill if declared bins do not match referenced behavior. |
| `requires.anyBins` | Like `requires.bins` but only one needs to be present. Prefer this over `requires.bins` when alternatives exist (e.g. `npm`/`pnpm`/`yarn`). |
| `requires.env` | Array of environment variables that must be set for the skill to run. **ClawScan checks declarations match references** — declaring an env var the skill never uses (or vice versa) is a metadata-mismatch signal. |
| `requires.config` | Array of config file paths the skill reads. |
| `primaryEnv` | Single env var name used as the API-key handle in `skills.entries.<name>.apiKey`. |
| `envVars` | Per-variable declarations with `{ name, required, description }`. Use for optional env vars (`required: false`) — `requires.env` means the skill cannot run without them. |
| `install` | Array of installer hints (`brew`/`node`/`go`/`uv`) shown by the macOS Skills UI. Mostly Mac-centric; skip for cross-platform / Windows-first skills. |
| `always` | `true` to bypass all gating and always include the skill. |
| `skillKey` | Override the skill's invocation key (defaults to slug). |

References:
- OpenClaw skills: <https://docs.openclaw.ai/tools/skills>
- ClawHub skill format: <https://docs.openclaw.ai/clawhub/skill-format>

## ClawHub publish requirements

Each top-level skill folder MUST also contain:

1. **`<skill>/.clawhubignore`** — exclude `evaluations/`, `.github/`, `dist/`,
   `*.zip`, `*.tgz`, and editor junk from the publish bundle. ClawHub also
   honors `.gitignore`. Bundle cap is 50 MB; the embedding pipeline reads
   `SKILL.md` plus up to ~40 non-`.md` files.
2. **All files must be text-based.** Allowed extensions are documented at
   <https://docs.openclaw.ai/clawhub/skill-format>. PowerShell `.ps1` /
   `.psm1` / `.psd1` are accepted.

ClawHub's audit pipeline (ClawScan + VirusTotal) checks for:
- Coherence between declared metadata and skill body content
- Undeclared env var or binary references
- Obfuscated install commands or hidden execution
- Acceptable-usage compliance (no security bypass, scraping at scale, etc.)

When publishing, attach a `--clawscan-note` explaining any pattern that may
look unusual at first glance (provider-specific CLIs, OAuth flows, certificate
submission, etc.). The note is stored on the published version and helps reduce
false positives without being treated as trusted proof.

## Sub-skill files

Files at `<skill>/skills/<sub-skill>/SKILL.md` (e.g. inside
`dataverse-classic-workflow/`) intentionally do NOT have frontmatter — they
are read as content from inside the parent skill, not loaded as standalone
skills. Do not add `name`/`description` to those files unless promoting them
to standalone skills (which would also require new entries in
`marketplace.json`, the parent `plugin.json`, and ClawHub if published).

## When updating frontmatter

- Run a quick visual check that the JSON object on the `metadata:` line has
  balanced braces and is on exactly one physical line.
- Do not break the line for readability — single-line is the spec.
- If you add a new field to `metadata.openclaw`, update this instruction
  file's table above so the convention stays discoverable.
- Bump both top-level `version:` AND `metadata.version` together on every
  release. **Easiest way:** `node scripts/bump-skill-version.mjs <skill> patch`
  — also updates `<skill>/.github/plugin/plugin.json` and
  `.github/plugin/marketplace.json` in one shot. Or just merge a PR with
  the right release labels and let `release-on-merge.yml` do it for you
  (see release procedure below).

## When adding a new skill

1. Create `<new-skill>/SKILL.md` following the template above (substitute
   `<skill-folder-name>` everywhere). Folder name must match the ClawHub
   slug regex `^[a-z0-9][a-z0-9-]*$`.
2. Create `<new-skill>/.clawhubignore` (copy from an existing skill).
3. Create `<new-skill>/.github/plugin/plugin.json` for GitHub Copilot CLI
   (mirror an existing one).
4. Add an entry to `.github/plugin/marketplace.json` for Copilot CLI
   marketplace discovery.
5. The build scripts (`build.ps1`, `build.sh`) auto-discover the folder by
   `SKILL.md` presence — no edits needed there.
6. Add a `claude install-github-skill ...` line to the README's Claude Code
   section so Claude users get a copy-paste install command.
7. Add the skill to **both** ClawHub workflows' skill lists:
   - `.github/workflows/clawhub-publish.yml` — the `skills` input `choice:`
     enum, the `Build skill list` step's `all` branch, and the
     `Publish skills` step's `NOTES` associative array
   - `.github/workflows/release-on-merge.yml` — the `NOTES` associative
     array in the `Real publish to ClawHub` step
   Also create a `skill:<new-slug>` GitHub label so the label-driven
   release workflow can target it: `gh label create skill:<new-slug>
   --color BFD4F2 --description "Release this skill on merge"`

## Publishing to ClawHub (release procedure)

The repo has TWO release workflows. Use the **label-driven** one for normal
changes; use the manual one for ad-hoc publishes.

### Primary: PR-label release (`release-on-merge.yml`)

This is the everyday release path. When a PR is merged into `main` with the
right labels, the workflow automatically:

1. Bumps versions in all 3 files (`SKILL.md` top + `metadata.version`,
   `<skill>/.github/plugin/plugin.json`, `.github/plugin/marketplace.json`)
   via `scripts/bump-skill-version.mjs`
2. Validates the bumps are consistent across files (sanity check)
3. Commits the bumps to `main` with a `chore(release): ...` message
4. Publishes each labeled skill to ClawHub
5. Creates per-skill git tags (`<skill>-v<version>`) and GitHub Releases
   with the changelog + ClawHub link
6. Comments on the PR with the new versions and links

**Required labels:**

| Label | Purpose |
|-------|---------|
| `skill:<slug>` | Which skill to release. Multi-allowed for parallel releases. Slugs: `n8n-create-nodes`, `power-platform-custom-connector`, `dataverse-classic-workflow`. |
| `bump:patch` \| `bump:minor` \| `bump:major` | Exactly one. Determines semver bump type. |
| `release:skip-clawhub` (optional) | Bumps versions and tags but skips ClawHub publish. Use for pure docs changes you want versioned. |

**Changelog source:** PR title by default. To provide longer release notes,
add a `## Changelog` section to the PR body — its contents (up to the next
`## ` heading) become the changelog instead.

**Failure modes:**
- No `skill:*` labels → workflow no-ops (logs "nothing to release")
- No `bump:*` label → workflow fails with clear error
- Multiple `bump:*` labels → workflow fails (conflict)
- Bumped version already exists in ClawHub → publish step fails; bumps are
  already committed, so recover by labeling a follow-up PR with the next
  bump level

### Fallback: Manual workflow (`clawhub-publish.yml`)

Use only when you need to publish without going through a PR — e.g.,
re-publishing after a registry-side issue, or shipping a hand-edited bundle.
This workflow does NOT bump version files; you must bump them yourself
first.

1. **Bump versions in the SKILL.md** you're shipping:
   - Top-level `version: X.Y.Z`
   - `metadata.version` inside the single-line JSON
   Both MUST match the `version` workflow input. Mismatched versions cause
   the ClawHub publish CLI to reject the bundle. (Use
   `node scripts/bump-skill-version.mjs <skill> <patch|minor|major|X.Y.Z>`
   to do all 3 files at once.)
2. **Commit and push to `main`.**
3. **Dry-run first.** GitHub UI → Actions → "Publish to ClawHub" → Run
   workflow with `dry_run: true`.
4. **Real publish.** Re-run with `dry_run: false`.
5. **Verify** at `https://clawhub.ai/skills/<slug>`.

### Operational gotchas

- **CLI flag drift.** ClawHub CLI flags have changed between versions
  (e.g. `--version` → `--cli-version` in v0.15). Always read the failing
  job log before assuming the workflow is broken — fix the flag and
  re-run. The manual workflow includes diagnostic steps (`clawhub --help`,
  `clawhub skill publish --help`) that print the live flag surface.
- **Local `clawhub inspect` on Windows can hang** if `NODE_OPTIONS`
  inherits debugger flags from the VS Code session. The GitHub Actions
  log is the authoritative source of publish success — local inspection
  is optional. To work around locally, open a fresh terminal and run
  `$env:NODE_OPTIONS=''; clawhub inspect <slug> --version <X.Y.Z>`.
- **Republishing the same version is rejected** by ClawHub. To retry a
  failed real-publish, bump the patch version and try again.
- **ClawScan notes** (`--clawscan-note`) are pre-written per skill in
  both workflows' associative arrays. Update them when adding a skill
  that has unusual provider CLIs, OAuth flows, or certificate
  submission patterns so the audit pipeline doesn't false-positive.
- **Copilot CLI / Claude Code don't enforce versions.** Both
  `gh agent install` and `claude install-github-skill` pull the skill
  from `main` at install time. The version fields in `plugin.json` /
  `marketplace.json` are discoverability metadata only. ClawHub is the
  only consumer that strictly enforces versions.
