# Agent Skills

A curated set of [AgentSkills](https://agentskills.io/)-format skills for AI coding agents. Currently focused on Power Platform custom connectors, n8n community nodes, and Dataverse Classic Workflow tooling. Compatible with [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-marketplace), [Claude Code](https://docs.anthropic.com/claude/docs/claude-code), and any [OpenClaw](https://docs.openclaw.ai/)-compatible runtime.

## Available skills

| Skill | What it does | Docs |
|---|---|---|
| [`n8n-create-nodes`](n8n-create-nodes/) | Build n8n community node packages — declarative or programmatic | [README](n8n-create-nodes/README.md) |
| [`power-platform-custom-connector`](power-platform-custom-connector/) | Author Power Platform custom connectors (Independent + Verified Publisher) | [README](power-platform-custom-connector/README.md) |
| [`dataverse-classic-workflow`](dataverse-classic-workflow/) | Read, edit, copy, and publish Dataverse WF4/XAML classic workflows | [README](dataverse-classic-workflow/README.md) |

Each skill is versioned independently and ships its own per-skill zip on every release.

## Installation

Replace `<skill>` below with one of: `n8n-create-nodes`, `power-platform-custom-connector`, or `dataverse-classic-workflow`. Per-skill READMEs have ready-to-paste copies.

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

- `agent-skills-v<version>.zip` — full bundle (all skills, snapshot)
- `<skill>-v<version>.zip` — one per skill, using each skill's own `version:` from its `SKILL.md`

## Build

```bash
./build.sh                    # bundle uses repo-wide version arg, per-skill zips use SKILL.md versions
./build.sh 1.2.3              # explicit bundle version
.\build.ps1 -Version 1.2.3    # PowerShell equivalent
```

Output zips are written to the `dist/` folder. Per-skill zip filenames reflect each skill's own `version:` from its `SKILL.md` frontmatter; the bundle uses the CLI argument or the latest `v*` tag.

## Releasing

Releases are label-driven. Open a PR, tag it `skill:<name>` + `bump:<patch|minor|major>`, and merge. The [`release-on-merge.yml`](.github/workflows/release-on-merge.yml) workflow handles the version bump, tag, and per-skill GitHub Release with zip assets attached. The repo-wide [`release.yml`](.github/workflows/release.yml) workflow runs on `v*` tag pushes and creates a snapshot bundle release.

## Contributing

1. Each skill lives in its own top-level folder with a `SKILL.md`, a `README.md`, and a `references/` directory (or `reference/` for the Dataverse bundle).
2. Add new skills by mirroring the existing layout — see any per-skill folder for the template.
3. Open a PR with the appropriate `skill:<name>` and `bump:<patch|minor|major>` labels.

## License

[MIT-0](https://opensource.org/license/0bsd) — no attribution required.

## Author

**rwilson504** — [@rwilson504](https://github.com/rwilson504)
