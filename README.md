# Agent Skills Repository

A collection of specialized skills and tools for building and deploying integrations across various platforms. This repository serves as a central hub for agent-focused development skills, currently featuring Power Platform custom connectors, n8n community nodes, and Dataverse Classic Workflow tooling.

## 🎯 Overview

This repository contains expertise and resources for:

- **Power Platform Custom Connectors**: Skills for creating independent publisher and verified publisher connectors
- **n8n Node Development**: Skills for creating new n8n community nodes
- **Dataverse Classic Workflow**: Read, analyze, compare, edit, copy, and publish WF4/XAML classic workflows + scaffold custom workflow activities
- **XrmToolBox Plugin Development**: Build, debug, and ship XrmToolBox tools for Dataverse / Dynamics 365 CE
- **Stream Deck Plugin Development**: Author Elgato Stream Deck plugins end-to-end, from manifest to Marketplace package
- **CAD with build123d**: Code-first parametric modeling, reverse engineering, rendering and export
- **3D Printing**: Bambu Lab P2S operation, Bambu Studio slicing, and the `.3mf` project format

These skills are designed to help AI agents and developers build, test, and deploy integrations more efficiently.

## 📦 Available Skills

### Power Platform Custom Connectors

The Power Platform custom connector skills enable the creation of custom connectors for Microsoft Power Platform (Power Apps, Power Automate, and Power BI).

**Key Capabilities:**
- Creating independent publisher connectors
- Creating verified publisher connectors
- Configuring authentication (OAuth2, API Key, etc.)
- Defining API operations and parameters
- Testing and validating connector functionality
- Publishing connectors to the Power Platform ecosystem

**Use Cases:**
- Extending Power Platform with custom API integrations
- Building connectors for proprietary or third-party services
- Enabling low-code/no-code integration solutions

### n8n

A five-skill bundle plus an orchestrator agent covering the whole n8n workflow-automation lifecycle. Installed as a single `n8n` plugin; the agent routes to the right skill for the task at hand.

**Skills in the bundle:**
- `n8n-build-workflow` — design and author workflow JSON (triggers, flow logic, expressions, AI cluster nodes, sub-workflows)
- `n8n-debug-workflow` — diagnose failing executions (error catalog, item-linking forensics, rate limits, resilience patterns)
- `n8n-code-node` — JavaScript and Python in the Code node (run modes, pairedItem, Luxon, JMESPath, Pyodide)
- `n8n-create-nodes` — build community nodes as npm packages (declarative and programmatic styles, credentials, triggers)
- `n8n-self-host` — install and operate self-hosted n8n (Docker Compose, queue mode, Postgres, backups, upgrades)

**Use Cases:**
- Turning a requirement into a runnable, import-ready workflow
- Debugging an execution that fails only in production
- Adding support for a new service by publishing a community node
- Standing up and scaling a self-hosted instance

### Dataverse Classic Workflow

The Dataverse Classic Workflow skill covers WF4/XAML-based classic workflows (the `workflow` table, category=0) — **not** Power Automate cloud flows. It bundles 7 sub-skills behind a single top-level `SKILL.md` orchestrator and a shared knowledge base.

**Key Capabilities:**
- Parse and summarize a workflow XAML file (trigger, scope, mode, step-by-step narrative)
- Gap-analyze an existing workflow against new requirements
- Diff two workflow XAML versions structurally
- Round-trip-safe XAML edits that preserve `UserData`, `mva:VisualBasicValue`, and namespace prefix mappings
- Clone a workflow via the Process Template path (with the gotchas the platform doesn't tell you about)
- Scaffold custom workflow activities — `CodeActivity`-derived C# classes targeting .NET Framework 4.6.2, with `[Input]` / `[Output]` / `[RequiredArgument]` / `[Default]` / `[ReferenceTarget]` / `[AttributeTarget]` parameter attributes and `spkl`'s `[CrmPluginRegistration]` registration
- Publish via Power Platform CLI (`pac solution pack` / `import` + activation)

**Use Cases:**
- Working with classic workflows extracted from a Dataverse solution (`pac solution clone` / `unpack`)
- Modernizing legacy CRM/Dynamics 365 workflows
- Authoring new C# workflow activity assemblies that XAML can call via `mxswa:ActivityReference`
- Cross-environment promotion (DEV → TEST → PROD) of workflow solutions
- Air-gapped environments (Online, on-premises, GCC, GCC-High, DoD) — no live env required for read/analyze/compare/edit

### XrmToolBox Plugin Development

Build, debug, and ship XrmToolBox tools — WinForms `UserControl`s hosted in the XrmToolBox shell that talk to Dataverse / Dynamics 365 CE. Ships with an orchestrator agent alongside the skill.

**Key Capabilities:**
- Scaffold `PluginBase` / `PluginControlBase` classes and wire `ExportMetadata`
- Call `IOrganizationService` correctly via `ExecuteMethod` + `WorkAsync` so the UI never freezes
- Implement the optional interfaces (`IGitHubPlugin`, `IHelpPlugin`, `IStatusBarMessenger`, `IMessageBusHost`, `IAboutPlugin`, `ISettingsPlugin`, `IShortcutReceiver`)
- Set up Visual Studio debugging — post-build copy, `.csproj.user` launch settings, `/overridepath`, `/connection`, `/plugin`
- Store secrets with DPAPI vs `CryptoManager`
- Package and distribute via NuGet to the Tool Library

**Use Cases:**
- Starting a new XrmToolBox tool from scratch
- Getting breakpoints working, including on Windows-on-ARM (ARM64 cannot debug .NET Framework in VS Code — use Visual Studio 2022)
- Preparing an existing tool for publication

### Stream Deck Plugin Development

Build Elgato Stream Deck plugins end-to-end with the official `@elgato/streamdeck` SDK — a Node.js backend paired with a Chromium property inspector. Ships with an orchestrator agent alongside nine skills.

**Key Capabilities:**
- Scaffold a plugin with the `streamdeck` CLI and lay out the `.sdPlugin` project correctly
- Write the `manifest.json` contract — actions, controllers, states, encoders, `SDKVersion`, DRM
- Implement key and dial actions on `SingletonAction` (`onKeyDown`, `onDialRotate`, `setFeedback`, multi-state toggles)
- Build the property inspector UI with `sdpi-components`, and persist action vs global settings
- Wire OAuth 2.0 (authorization code + PKCE) through the Elgato redirect proxy, including refresh-token rotation
- Bundle profiles, localize into eight languages, and author custom touch-strip layouts
- Package a `.streamDeckPlugin` and submit it to the Elgato Marketplace

**Use Cases:**
- Starting a new Stream Deck plugin from scratch
- Connecting a plugin to Spotify, Twitch, Hue, GitHub or any OAuth2 provider
- Getting a plugin through Maker Console review and shipped

### CAD with build123d

Code-first parametric CAD in Python — model, verify, reverse-engineer, render and export without ever opening a GUI CAD app. Ships with an orchestrator agent alongside sixteen skills.

**Key Capabilities:**
- Core build123d idioms and the OCCT gotchas that cause most modeling bugs
- Parametric parts from the `bd_warehouse` library — fasteners, bearings, gears, threads
- 3D-printable threads, thumbscrews and printed nuts tuned for FDM resolution
- Reverse-engineer an existing STL or STEP back into parametric source
- Port OpenSCAD scripts to build123d incrementally
- Verification tooling — six-view orthographic checks, per-face feature inventories, annotated 2D layout maps, colour-tagged GLB component maps
- Publication renders (hero, exploded, cutaway, turntable) and terminal previews
- Mode-aware STL and `.3mf` export for the design / test / production workflow

**Use Cases:**
- Turning photos, sketches or caliper measurements into a parametric model
- Rebuilding a downloaded STL you have no source for
- Producing documentation renders and print-ready exports from the same script

### 3D Printing (Bambu Lab)

Everything that happens *after* a model exists — slicing, material choice, printer operation, failure diagnosis and post-processing. Focused on the Bambu Lab P2S with Bambu Studio. Ships with an operator agent alongside four skills.

**Key Capabilities:**
- P2S hardware reference — build volume, AMS loading, bed types, calibration, maintenance
- Bambu Studio profiles, per-material settings, support strategy and plate management
- The `.3mf` project format at the ZIP/XML level, so slicer settings can be read, diffed and generated programmatically
- Scaffolding a print project with a decision record for material and orientation choices
- A catalogue of documented failure modes with the fix for each

**Use Cases:**
- Diagnosing warping, layer shifts, poor adhesion or stringing from the symptom
- Choosing material and print orientation, and recording *why* for the next revision
- Generating `.3mf` files from a known-good slice instead of re-configuring by hand

> Pairs with the `cad` plugin, which produces the model this plugin prints. Each works standalone.

## 🚀 Getting Started

### Prerequisites

Depending on which skill you're working with:

**For Power Platform Custom Connectors:**
- Power Platform account
- Power Platform CLI (for development)
- OpenAPI/Swagger specification knowledge
- Understanding of authentication protocols

**For n8n Node Development:**
- Node.js (v14 or higher)
- npm or yarn
- Basic TypeScript knowledge
- n8n instance for testing

**For Dataverse Classic Workflow:**
- Workflow XAML files extracted from a Dataverse solution (typically via `pac solution clone` or `pac solution unpack`)
- Power Platform CLI (`pac`) — required only for the `publish-workflow` sub-skill
- For custom workflow activities: .NET Framework 4.6.2 SDK + `Microsoft.CrmSdk.Workflow` NuGet package

### Installation

Choose the method that matches your AI coding agent:

#### GitHub Copilot CLI (Plugin Marketplace) — Recommended

This repository ships a [GitHub Copilot CLI plugin marketplace](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-marketplace) at [.github/plugin/marketplace.json](.github/plugin/marketplace.json). Each skill is published as an individually installable plugin.

```bash
# 1. Add this repository as a marketplace
copilot plugin marketplace add rwilson504/agent-skills

# 2. Install one or more plugins from the marketplace
copilot plugin install power-platform-custom-connector@agent-skills
copilot plugin install n8n@agent-skills
copilot plugin install dataverse-classic-workflow@agent-skills
copilot plugin install xrmtoolbox-plugin-dev@agent-skills

# 3. (Optional) List what's installed and check for updates
copilot plugin list
copilot plugin marketplace update agent-skills
```

Once installed, the skills are auto-loaded into every Copilot CLI session — no per-project configuration required.

#### Claude Code

Install skills directly from GitHub using the Claude Code CLI:

```bash
# Install a specific skill
claude install-github-skill rwilson504/agent-skills/power-platform-custom-connector
claude install-github-skill rwilson504/agent-skills/n8n-build-workflow
claude install-github-skill rwilson504/agent-skills/dataverse-classic-workflow
claude install-github-skill rwilson504/agent-skills/xrmtoolbox-plugin-dev
```

Copilot CLI installs **plugins** (4 of them); Claude Code and ClawHub install
individual **skills** (8 of them). The five `n8n-*` skills are installable one
by one here, but arrive together as the `n8n` plugin above.

After installation, the skill's instructions are automatically available in your Claude Code sessions.

#### ClawHub (OpenClaw registry)

Each skill is published to the [ClawHub](https://clawhub.ai) registry under the [MIT-0](https://opensource.org/license/0bsd) license (no attribution required). If you already use OpenClaw, this is the lowest-friction install path:

```bash
# One-time: install the OpenClaw CLI
# (see https://docs.openclaw.ai/clawhub/quickstart)

# Install any of the skills directly from ClawHub
openclaw skills install power-platform-custom-connector
openclaw skills install n8n-build-workflow
openclaw skills install dataverse-classic-workflow
openclaw skills install xrmtoolbox-plugin-dev

# Update installed skills later
openclaw skills update --all
```

Inspect a skill before installing (recommended for any registry-installed content):

```bash
clawhub inspect power-platform-custom-connector
```

#### OpenClaw (manual file copy)

If you don't want to use ClawHub, OpenClaw also consumes [AgentSkills](https://agentskills.io/)-compatible skill folders, which is the same format used here — no conversion needed. Drop a skill folder into any of OpenClaw's [skill roots](https://docs.openclaw.ai/tools/skills) (highest precedence first):

| Scope | Path |
|-------|------|
| Workspace | `<workspace>/skills/<skill-name>/` |
| Project agent | `<workspace>/.agents/skills/<skill-name>/` |
| Personal (all agents) | `~/.agents/skills/<skill-name>/` |
| Managed/local | `~/.openclaw/skills/<skill-name>/` |

Quick install via sparse clone (personal scope shown — swap the destination for any of the rows above):

```bash
# Clone just the skill folder you want
git clone --depth 1 --filter=blob:none --sparse https://github.com/rwilson504/agent-skills.git /tmp/agent-skills
cd /tmp/agent-skills
git sparse-checkout set power-platform-custom-connector
mkdir -p ~/.agents/skills
cp -r power-platform-custom-connector ~/.agents/skills/
```

Or grab a pre-built zip from the [latest release](https://github.com/rwilson504/agent-skills/releases/latest) and extract it into the same destination. OpenClaw's skill watcher (`skills.load.watch: true`) will pick it up on the next session — no restart required.

> **Frontmatter compatibility:** The `metadata:` line in our `SKILL.md` files is a single-line JSON object — exactly the shape OpenClaw's parser expects. The `metadata.openclaw.homepage` and `metadata.openclaw.emoji` fields show up in the OpenClaw Skills UI. To add OpenClaw-specific gating (`metadata.openclaw.requires.bins`, `requires.env`, `os`, etc.), edit the `metadata` JSON block in your local copy.

#### VS Code / GitHub Copilot Chat

1. Download the skill zip from the [latest release](https://github.com/rwilson504/agent-skills/releases/latest)
2. Extract the skill folder into your project
3. Add the SKILL.md as a custom instruction file in `.github/copilot-instructions.md` or reference it via a VS Code prompt file (`.github/prompts/*.prompt.md`)

Alternatively, clone the repo and point a prompt file at the SKILL.md:

```yaml
# .github/prompts/power-platform-connector.prompt.md
---
description: Power Platform custom connector creation
---
@skill path/to/power-platform-custom-connector/SKILL.md
```

#### Cursor

1. Download or clone the skill
2. Copy the SKILL.md content into `.cursor/rules/` as a rule file:

```bash
# Example
cp power-platform-custom-connector/SKILL.md .cursor/rules/power-platform-connector.md
```

#### Windsurf

1. Download or clone the skill
2. Append or include the SKILL.md content in your `.windsurfrules` file

#### Manual (Any Agent)

Clone the repository and reference the skill files directly:

```bash
git clone https://github.com/rwilson504/agent-skills.git
cd agent-skills
```

Or download individual skill packages from the [latest release](https://github.com/rwilson504/agent-skills/releases/latest).

## 📁 Repository Structure

```
agent-skills/
├── plugins.yml                          # Composition manifest: which skills/agents form each plugin
├── src/                                 # CANONICAL source. Edit here only.
│   ├── agents/                          # <name>.agent.md orchestrators
│   │   ├── 3d-print-operator.agent.md
│   │   ├── cad-builder.agent.md
│   │   ├── dataverse-classic-workflow.agent.md
│   │   ├── n8n.agent.md
│   │   ├── streamdeck-plugin-builder.agent.md
│   │   └── xrmtoolbox-plugin-dev.agent.md
│   └── skills/                          # <name>/SKILL.md + supporting files
│       ├── cad-*/                       # 16 skills — build123d modeling, verification, export
│       ├── dataverse-classic-*/         # 8 skills — orchestrator + 7 task skills
│       ├── n8n-*/                       # 5 skills — build, debug, code node, self-host, community nodes
│       ├── print-*/                     # 4 skills — P2S, Bambu Studio, .3mf, project scaffold
│       ├── streamdeck-*/                # 9 skills — manifest, actions, PI, OAuth, publishing
│       ├── power-platform-custom-connector/
│       └── xrmtoolbox-plugin-dev/
├── plugins/                             # GENERATED by scripts/build-plugins.ps1. Never edit by hand.
│   ├── 3dprint/                         # agent + four print skills
│   ├── cad/                             # agent + sixteen cad skills
│   ├── dataverse-classic-workflow/
│   ├── n8n/                             # agent + all five n8n skills
│   ├── power-platform-custom-connector/
│   ├── streamdeck/                      # agent + nine streamdeck skills
│   └── xrmtoolbox-plugin-dev/
├── scripts/
│   ├── build-plugins.ps1                # src/ + plugins.yml -> plugins/
│   ├── lint.ps1                         # frontmatter, version coherence, src/->plugins/ drift
│   ├── promote-skill.ps1                # import a skill/agent from the private source repo
│   ├── scan-leaks.ps1                   # gitleaks + sensitivity regex, run before promotion
│   └── bump-skill-version.mjs           # bump SKILL.md + plugins.yml versions together
├── .github/
│   ├── plugin/
│   │   └── marketplace.json             # GENERATED. Copilot CLI marketplace registry.
│   └── workflows/
│       ├── release.yml                  # CI: build + publish zip releases on v* tags
│       ├── release-on-merge.yml
│       └── clawhub-publish.yml          # CI: publish skills to ClawHub (workflow_dispatch)
├── build.sh                             # Release packaging (bash)
└── build.ps1                            # Release packaging (PowerShell)
```

> Skills and agents are authored in the private upstream repo and copied here by
> `scripts/promote-skill.ps1`. Edit `src/` here only when the change is specific
> to this repo's packaging; content changes belong upstream.

## 🔧 Usage

### Creating a Power Platform Custom Connector

1. Open `src/skills/power-platform-custom-connector/SKILL.md` for the main instructions
2. Reference files in `references/` (e.g., `AUTH_PATTERNS.md`, `OPENAPI_EXTENSIONS.md`) as needed

### Working with n8n

1. Install the `n8n` plugin — the agent routes to the right skill for the task
2. Or open the skill directly under `src/skills/n8n-<build-workflow|debug-workflow|code-node|create-nodes|self-host>/SKILL.md`

### Working with a Dataverse Classic Workflow

1. Open `src/skills/dataverse-classic-workflow/SKILL.md` — it routes to the right sub-skill based on user intent
2. Sub-skills live in `skills/<name>/SKILL.md`; the shared knowledge base lives in `reference/`
3. The `examples/` folder contains a fully anonymized custom workflow activity scaffold

### Building an XrmToolBox Tool

1. Install the `xrmtoolbox-plugin-dev` plugin, or open `src/skills/xrmtoolbox-plugin-dev/SKILL.md`
2. The bundled agent enforces the `ExecuteMethod` → `WorkAsync` rule that keeps the shell responsive

### Building a Stream Deck Plugin

1. Install the `streamdeck` plugin, or start from `src/skills/streamdeck-general/SKILL.md`
2. Load `streamdeck-manifest` before writing code — the manifest is the contract, and `manifest.UUID` can never change once users have buttons bound to it
3. For third-party APIs, `streamdeck-oauth` covers the Elgato redirect proxy, which works where custom URL schemes do not

### Modeling a Part with build123d

1. Install the `cad` plugin, or start from `src/skills/cad-build123d-general/SKILL.md` — load it before any other CAD skill
2. The bundled agent is code-first by design: it will not recommend a GUI CAD app
3. Rebuild and look at the result after every edit — `cad-build123d-six-view-checks` and `cad-feature-inventory` exist so you verify geometry instead of assuming it

### Printing a Part on a Bambu Lab P2S

1. Install the `3dprint` plugin, or start from `src/skills/print-bambu-p2s/SKILL.md`
2. Decide material and orientation *before* slicing, and record the reasoning — `print-project-new` scaffolds a decision record for exactly this
3. When a print fails, describe the symptom rather than guessing the cause; the failure-diagnosis table in `print-bambu-p2s` maps symptoms to documented fixes
4. To script slicer settings instead of clicking through them, `print-bambu-3mf` documents the `.3mf` format well enough to read, diff and generate project files

## 📦 Distribution

Skills can be consumed four ways — pick whichever fits your tooling:

### 1. GitHub Copilot CLI Marketplace

The repo itself is a Copilot CLI plugin marketplace (see [.github/plugin/marketplace.json](.github/plugin/marketplace.json)). Add it once and install any of the skills as plugins — see [Installation](#installation) above.

### 2. ClawHub Registry

Each skill is published to [ClawHub](https://clawhub.ai), the OpenClaw registry. ClawHub auto-licenses everything as [MIT-0](https://opensource.org/license/0bsd) and runs every release through ClawScan + VirusTotal audits. Installation is one command per skill via the OpenClaw CLI — see [Installation](#installation) above.

The publish pipeline lives in [.github/workflows/clawhub-publish.yml](.github/workflows/clawhub-publish.yml) and is triggered manually (`workflow_dispatch`) so we can dry-run, attach changelogs, and review ClawScan results before each push.

### 3. Pre-built Zip Releases

Pre-built zip packages are published on the [Releases](https://github.com/rwilson504/agent-skills/releases) page for agents that don't speak the Copilot CLI plugin protocol or use the ClawHub registry (Cursor, Windsurf, manual installs, air-gapped environments, etc.).

Each release includes one zip per plugin, plus a bundle:
- **agent-skills-v\<version\>.zip** — Complete bundle with all plugins
- **n8n-v\<version\>.zip** — n8n agent + all five n8n skills
- **power-platform-custom-connector-v\<version\>.zip**
- **dataverse-classic-workflow-v\<version\>.zip**
- **xrmtoolbox-plugin-dev-v\<version\>.zip**

### 4. Building Locally

```bash
# Bash (Linux / macOS / CI)
./build.sh 1.0.0

# PowerShell (Windows)
.\build.ps1 -Version 1.0.0
```

Output zips are written to the `dist/` folder.

### Publishing a Release

Push a version tag to trigger the GitHub Actions workflow, which builds the packages and creates a GitHub Release with the zips attached:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Tags containing `-` (e.g., `v1.0.0-beta`) are automatically marked as pre-releases.

## 🤝 Contributing

Contributions are welcome! If you'd like to add new skills or improve existing ones:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-skill`)
3. Commit your changes (`git commit -m 'Add new skill'`)
4. Push to the branch (`git push origin feature/new-skill`)
5. Open a Pull Request

## 📚 Resources

### Power Platform
- [Power Platform Custom Connectors Documentation](https://learn.microsoft.com/en-us/connectors/custom-connectors/)
- [Power Platform CLI](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction)
- [Connector Certification](https://learn.microsoft.com/en-us/connectors/custom-connectors/submit-certification)

### n8n
- [n8n Node Development Documentation](https://docs.n8n.io/integrations/creating-nodes/)
- [n8n Community Nodes](https://docs.n8n.io/integrations/community-nodes/)
- [n8n GitHub Repository](https://github.com/n8n-io/n8n)

### Dataverse Classic Workflow
- [Workflow processes (MS Learn)](https://learn.microsoft.com/power-automate/workflow-processes) — authoritative reference
- [Workflow extensions / Custom workflow activities (MS Learn)](https://learn.microsoft.com/power-apps/developer/data-platform/workflow/workflow-extensions)
- [Power Platform CLI](https://learn.microsoft.com/power-platform/developer/cli/introduction)

### Stream Deck
- [Stream Deck SDK documentation](https://docs.elgato.com/streamdeck/sdk/introduction/getting-started) — authoritative reference
- [`@elgato/streamdeck` on npm](https://www.npmjs.com/package/@elgato/streamdeck)
- [sdpi-components (property inspector UI)](https://sdpi-components.dev)
- [Maker Console (Marketplace submission)](https://maker.elgato.com)

### CAD
- [build123d documentation](https://build123d.readthedocs.io/) — authoritative reference
- [build123d cheat sheet](https://build123d.readthedocs.io/en/latest/cheat_sheet.html)
- [PartCAD repository](https://partcad.org/repository) — community parts and assemblies

### 3D Printing
- [Bambu Lab wiki](https://wiki.bambulab.com) — authoritative printer and slicer reference
- [Bambu Studio](https://bambulab.com/en/download/studio) — slicer download
- [3MF specification](https://github.com/3MFConsortium/spec_core) — the core format the `.3mf` skill builds on

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**rwilson504**

- GitHub: [@rwilson504](https://github.com/rwilson504)

## 🙏 Acknowledgments

- Microsoft Power Platform team for the connector framework
- n8n community for the workflow automation platform
- All contributors to this repository

---

**Note:** This repository is actively maintained and new skills will be added over time. Star ⭐ the repository to stay updated!
