# Agent Skills

A curated set of [AgentSkills](https://agentskills.io/)-format skills and agents for AI coding agents. Currently focused on Power Platform custom connectors, the full n8n workflow-automation lifecycle (workflow design, debugging, Code-node scripting, community-node packaging, self-hosting), and Dataverse Classic Workflow tooling. Compatible with [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-marketplace), [Claude Code](https://docs.anthropic.com/claude/docs/claude-code), and any [OpenClaw](https://docs.openclaw.ai/)-compatible runtime.

## Available agents

| Agent | What it does | Docs |
|---|---|---|
| [`n8n`](src/agents/n8n.agent.md) | Orchestrator for the n8n skill bundle. Routes to build/debug/code-node/community-nodes/self-host, drives a continuous-learning loop that captures each session's discoveries back into the bundle | [agent](src/agents/n8n.agent.md) |

## Available skills

| Skill | What it does | Docs |
|---|---|---|
| [`n8n-build-workflow`](src/skills/n8n-build-workflow/) | Design and author n8n workflow JSON — triggers, flow logic, expressions, AI workflows (LangChain cluster) | [README](src/skills/n8n-build-workflow/README.md) |
| [`n8n-debug-workflow`](src/skills/n8n-debug-workflow/) | Diagnose failing n8n executions — error catalog, item-linking forensics, rate-limit recovery, trigger debugging | [README](src/skills/n8n-debug-workflow/README.md) |
| [`n8n-code-node`](src/skills/n8n-code-node/) | Write correct JavaScript or Python in the Code node — run modes, pairedItem, binary helpers, Luxon, JMESPath, Pyodide | [README](src/skills/n8n-code-node/README.md) |
| [`n8n-create-nodes`](src/skills/n8n-create-nodes/) | Build n8n community node packages — declarative or programmatic | [README](src/skills/n8n-create-nodes/README.md) |
| [`n8n-self-host`](src/skills/n8n-self-host/) | Install, configure, and operate self-hosted n8n — Docker, queue mode, reverse proxy, Postgres, backups, upgrades | [README](src/skills/n8n-self-host/README.md) |
| [`power-platform-custom-connector`](src/skills/power-platform-custom-connector/) | Author Power Platform custom connectors (Independent + Verified Publisher) | [README](src/skills/power-platform-custom-connector/README.md) |
| [`dataverse-classic-workflow`](src/skills/dataverse-classic-workflow/) | Read, edit, copy, and publish Dataverse WF4/XAML classic workflows | [README](src/skills/dataverse-classic-workflow/README.md) |

The `n8n` plugin bundles the agent plus all five n8n skills as one install. Each skill is also available as its own plugin.

Each skill is versioned independently and ships its own per-plugin zip on every release.

## Repository layout

```
src/
  agents/             # Canonical *.agent.md files (one per agent — none yet)
  skills/             # Canonical skill folders, edited by humans
    <skill>/SKILL.md
plugins.yml           # Composition manifest: which agents/skills go in each plugin
plugins/              # GENERATED — do not edit. Built from src/ + plugins.yml.
  <plugin>/
    plugin.json       # Generated per-plugin manifest
    skills/<skill>/   # Copied from src/skills/<skill>/
.github/plugin/marketplace.json   # GENERATED — Copilot CLI marketplace listing
```

The `plugins/` tree and `marketplace.json` are produced by [`scripts/build-plugins.ps1`](scripts/build-plugins.ps1) and validated by [`scripts/lint.ps1`](scripts/lint.ps1) (which detects drift between `src/` and `plugins/` via SHA256 folder hashes).

## Installation

Replace `<skill>` below with one of: `n8n` (full agent bundle), `n8n-build-workflow`, `n8n-debug-workflow`, `n8n-code-node`, `n8n-create-nodes`, `n8n-self-host`, `power-platform-custom-connector`, or `dataverse-classic-workflow`. Per-skill READMEs have ready-to-paste copies.

### GitHub Copilot CLI (recommended)

This repo ships a [Copilot CLI plugin marketplace](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-marketplace) at [.github/plugin/marketplace.json](.github/plugin/marketplace.json).

```bash
copilot plugin marketplace add rwilson504/agent-skills
copilot plugin install <skill>@agent-skills
```

Once installed, the skill is auto-loaded into every Copilot CLI session — no per-project configuration required.

### Claude Code

```bash
claude install-github-skill rwilson504/agent-skills/<skill>
```

### ClawHub (OpenClaw registry)

> **Note:** ClawHub publishing is temporarily paused while we work with ClawHub support to resolve a connection issue. Existing published skill versions remain installable via the OpenClaw CLI; new versions will resume publishing once the connection is restored.

```bash
openclaw skills install <skill>
```

### OpenClaw (manual file copy)

OpenClaw also consumes [AgentSkills](https://agentskills.io/)-compatible skill folders directly — same format used here, no conversion needed. Drop a skill folder into any of OpenClaw's [skill roots](https://docs.openclaw.ai/tools/skills) (highest precedence first):

| Scope | Path |
|-------|------|
| Workspace | `<workspace>/skills/<skill-name>/` |
| Project agent | `<workspace>/.agents/skills/<skill-name>/` |
| Personal (all agents) | `~/.agents/skills/<skill-name>/` |
| Managed/local | `~/.openclaw/skills/<skill-name>/` |

Either sparse-clone this repo or grab a per-skill zip from the [latest release](https://github.com/rwilson504/agent-skills/releases/latest) and extract it into one of those paths. OpenClaw's skill watcher (`skills.load.watch: true`) picks it up on the next session — no restart required.

> **Frontmatter compatibility:** the `metadata:` line in each `SKILL.md` is a single-line JSON object in OpenClaw's expected shape. `metadata.openclaw.homepage` and `metadata.openclaw.emoji` show up in the OpenClaw Skills UI. To add gating (`metadata.openclaw.requires.bins`, `requires.env`, `os`, etc.), edit the `metadata` JSON block in your local copy.

### Other agents (Cursor, Windsurf, VS Code)

Download the per-skill zip from the [latest release](https://github.com/rwilson504/agent-skills/releases/latest), then reference its `SKILL.md` from your agent's instruction-file convention:

- **VS Code / Copilot Chat** — add to `.github/copilot-instructions.md` or a `.github/prompts/*.prompt.md` file
- **Cursor** — copy `SKILL.md` into `.cursor/rules/<name>.md`
- **Windsurf** — append or include the `SKILL.md` content in `.windsurfrules`

## Distribution

| Channel | Format | Cadence |
|---|---|---|
| [GitHub Releases](https://github.com/rwilson504/agent-skills/releases) | per-skill zip + bundle zip | every merged release PR |
| GitHub Copilot CLI marketplace | [`marketplace.json`](.github/plugin/marketplace.json) | on every release |
| ClawHub registry | OpenClaw bundle | paused |

Each release contains:

- `agent-skills-v<version>.zip` — full bundle (all plugins, snapshot)
- `<plugin>-v<version>.zip` — one per plugin, using each plugin's own `version:` from `plugins.yml`

## Build

```bash
# Regenerate plugins/ + marketplace.json from src/ + plugins.yml (idempotent)
pwsh scripts/build-plugins.ps1

# Validate (frontmatter, version coherence, src↔plugins drift, marketplace listing)
pwsh scripts/lint.ps1

# Produce zip artifacts in dist/ (regenerates plugins/ first)
./build.sh                    # bundle uses git tag, per-plugin zips use plugin.json versions
./build.sh 1.2.3              # explicit bundle version
.\build.ps1 -Version 1.2.3    # PowerShell equivalent
```

Output zips are written to `dist/`. Per-plugin zip filenames reflect each plugin's `version:` field; the bundle uses the CLI argument or the latest `v*` tag.

### Bumping a skill version

```bash
node scripts/bump-skill-version.mjs <skill> patch|minor|major|X.Y.Z
```

This updates `src/skills/<skill>/SKILL.md` (top-level + `metadata.version`) and `plugins.yml` atomically, then regenerates `plugins/` and `marketplace.json` so everything stays in sync.

### Promoting a skill or agent from another repo

```powershell
# Single skill -> its own plugin (version derived from SKILL.md frontmatter)
pwsh scripts/promote-skill.ps1 `
  -Name my-cool-skill `
  -SkillSource ..\agent-plugins-personal\src\skills\my-cool-skill `
  -Description "Short single-line description" `
  -Keywords kw1,kw2

# Agent + supporting skills -> one bundled plugin
pwsh scripts/promote-skill.ps1 `
  -Name release-helper `
  -AgentSource ..\agent-plugins-personal\src\agents\release-helper.agent.md `
  -SkillSource @(
      "..\agent-plugins-personal\src\skills\version-bump",
      "..\agent-plugins-personal\src\skills\changelog-gen"
  ) `
  -Description "Drives a release: bumps versions, regenerates changelog, opens PR" `
  -Version 1.0.0
```

[`scripts/promote-skill.ps1`](scripts/promote-skill.ps1) first runs [`scripts/scan-leaks.ps1`](scripts/scan-leaks.ps1) against the source paths (gitleaks + sensitivity regex checks), then copies source assets into `src/skills/` and `src/agents/`, rewrites the source repo's bare name to `agent-skills` in copied `.md` files (Claude install paths, Copilot marketplace add, `<skill>@<repo>` install commands), appends a new entry to [`plugins.yml`](plugins.yml), and runs `build-plugins.ps1` + `lint.ps1` to materialize and validate. Use `-DryRun` to preview, `-Force` to re-promote an existing entry, `-SkipBuild` if batching multiple promotions, and `-SkipScan` only for emergency overrides.

## Releasing

Releases are label-driven. Open a PR, tag it `skill:<name>` + `bump:<patch|minor|major>`, and merge. The [`release-on-merge.yml`](.github/workflows/release-on-merge.yml) workflow handles the version bump, tag, and per-skill GitHub Release with zip assets attached. The repo-wide [`release.yml`](.github/workflows/release.yml) workflow runs on `v*` tag pushes and creates a snapshot bundle release.

## Contributing

1. Each skill lives in `src/skills/<name>/` with a `SKILL.md`, a `README.md`, and a `references/` directory (or `reference/` for the Dataverse bundle). Never edit anything under `plugins/` directly — that tree is regenerated from `src/` + `plugins.yml`.
2. Add a new skill by:
   - Creating `src/skills/<name>/` (mirror an existing skill's layout)
   - Adding an entry under `plugins:` in [`plugins.yml`](plugins.yml)
   - Running `pwsh scripts/build-plugins.ps1` and committing the regenerated `plugins/` + `marketplace.json`
   - Running `pwsh scripts/lint.ps1` to confirm everything is in sync
3. Open a PR with the appropriate `skill:<name>` and `bump:<patch|minor|major>` labels.

## License

[MIT-0](https://opensource.org/license/0bsd) — no attribution required.

## Author

**rwilson504** — [@rwilson504](https://github.com/rwilson504)
