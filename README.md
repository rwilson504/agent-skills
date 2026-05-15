# Agent Skills Repository

A collection of specialized skills and tools for building and deploying integrations across various platforms. This repository serves as a central hub for agent-focused development skills, currently featuring Power Platform custom connectors, n8n community nodes, and Dataverse Classic Workflow tooling.

## 🎯 Overview

This repository contains expertise and resources for:

- **Power Platform Custom Connectors**: Skills for creating independent publisher and verified publisher connectors
- **n8n Node Development**: Skills for creating new n8n community nodes
- **Dataverse Classic Workflow**: Read, analyze, compare, edit, copy, and publish WF4/XAML classic workflows + scaffold custom workflow activities

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

### n8n Node Development

The n8n node development skills facilitate the creation of custom nodes for the n8n workflow automation platform.

**Key Capabilities:**
- Creating new n8n community nodes
- Implementing node operations and resources
- Configuring node parameters and credentials
- Testing nodes locally
- Preparing nodes for community publication

**Use Cases:**
- Adding support for new services in n8n
- Creating specialized automation nodes
- Contributing to the n8n open-source ecosystem

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
copilot plugin install n8n-create-nodes@agent-skills
copilot plugin install dataverse-classic-workflow@agent-skills

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
claude install-github-skill rwilson504/agent-skills/n8n-create-nodes
claude install-github-skill rwilson504/agent-skills/dataverse-classic-workflow
```

After installation, the skill's instructions are automatically available in your Claude Code sessions.

#### ClawHub (OpenClaw registry)

Each skill is published to the [ClawHub](https://clawhub.ai) registry under the [MIT-0](https://opensource.org/license/0bsd) license (no attribution required). If you already use OpenClaw, this is the lowest-friction install path:

```bash
# One-time: install the OpenClaw CLI
# (see https://docs.openclaw.ai/clawhub/quickstart)

# Install any of the skills directly from ClawHub
openclaw skills install power-platform-custom-connector
openclaw skills install n8n-create-nodes
openclaw skills install dataverse-classic-workflow

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
├── .github/
│   ├── instructions/
│   │   └── skill-frontmatter.instructions.md   # Frontmatter convention applyTo: '**/SKILL.md'
│   ├── plugin/
│   │   └── marketplace.json             # Copilot CLI marketplace registry (lists all plugins)
│   └── workflows/
│       ├── release.yml                  # CI: build + publish zip releases on v* tags
│       └── clawhub-publish.yml          # CI: publish skills to ClawHub on workflow_dispatch
├── n8n-create-nodes/                    # n8n node development skill
│   ├── .clawhubignore                   # Files excluded from ClawHub publish bundle
│   ├── .github/plugin/plugin.json       # Copilot CLI plugin manifest
│   ├── SKILL.md                         # Main skill instructions
│   ├── references/                      # Detailed reference docs (loaded on demand)
│   │   ├── CREDENTIAL_PATTERNS.md       # Credential implementation patterns
│   │   ├── TRIGGER_PATTERNS.md          # Trigger node patterns
│   │   ├── EXAMPLES.md                  # Full examples
│   │   └── COMMON_MISTAKES.md           # Common mistakes and fixes
│   └── evaluations/                     # Test scenarios
├── power-platform-custom-connector/     # Power Platform connector skill
│   ├── .clawhubignore                   # Files excluded from ClawHub publish bundle
│   ├── .github/plugin/plugin.json       # Copilot CLI plugin manifest
│   ├── SKILL.md                         # Main skill instructions
│   ├── references/                      # Detailed reference docs (loaded on demand)
│   │   ├── AUTH_PATTERNS.md             # Authentication patterns
│   │   ├── OPENAPI_EXTENSIONS.md        # x-ms-* OpenAPI extensions
│   │   ├── POLICY_TEMPLATES.md          # Policy template reference
│   │   ├── CUSTOM_CODE.md              # Custom code (script.csx)
│   │   ├── WEBHOOK_TRIGGERS.md          # Webhook trigger patterns
│   │   ├── CERTIFICATION.md            # Certification workflows & submission
│   │   ├── EXAMPLES.md                  # Full examples
│   │   └── COMMON_MISTAKES.md           # Common mistakes and fixes
│   └── evaluations/                     # Test scenarios
├── dataverse-classic-workflow/          # Dataverse Classic Workflow (WF4/XAML) skill bundle
│   ├── .clawhubignore                   # Files excluded from ClawHub publish bundle
│   ├── .github/plugin/plugin.json       # Copilot CLI plugin manifest
│   ├── SKILL.md                         # Top-level orchestrator + routing table to sub-skills
│   ├── reference/                       # Shared knowledge base (cited by every sub-skill)
│   │   ├── xaml-anatomy.md              # WF4 XAML structure, namespaces, ActivityReference
│   │   ├── activity-types.md            # mxswa:* / mcwc:* activity catalog
│   │   ├── vb-expressions.md            # bracket [expr] dynamic value patterns
│   │   ├── trigger-types.md             # TriggerType, Scope, Mode, RunAs reference
│   │   ├── web-research.md              # MS Learn citations + AsyncOperation states + best practices
│   │   └── example-workflow.xaml        # one anonymized end-to-end example
│   ├── examples/                        # Worked code examples
│   │   └── custom-activity-substring.cs # CodeActivity scaffold (anonymized)
│   └── skills/                          # 7 sub-skills, each with its own SKILL.md
│       ├── read-workflow/               # parse + summarize a workflow
│       ├── analyze-workflow/            # gap-analyze against requirements
│       ├── compare-workflows/           # diff two workflow XAML files
│       ├── copy-workflow/               # clone via Process Template (with gotchas)
│       ├── write-workflow/              # round-trip-safe XAML edits
│       ├── write-custom-activity/       # scaffold C# CodeActivity assemblies
│       └── publish-workflow/            # activate / import / export via PAC CLI
├── build.sh                             # Build script (bash)
└── build.ps1                            # Build script (PowerShell)
```

## 🔧 Usage

### Creating a Power Platform Custom Connector

1. Navigate to the `power-platform-custom-connector/` directory
2. Start with `SKILL.md` for the main instructions
3. Reference files in `references/` (e.g., `AUTH_PATTERNS.md`, `OPENAPI_EXTENSIONS.md`) as needed

### Creating an n8n Community Node

1. Navigate to the `n8n-create-nodes/` directory
2. Start with `SKILL.md` for the main instructions
3. Reference files in `references/` (e.g., `CREDENTIAL_PATTERNS.md`, `TRIGGER_PATTERNS.md`) as needed

### Working with a Dataverse Classic Workflow

1. Navigate to the `dataverse-classic-workflow/` directory
2. Start with `SKILL.md` — it routes to the right sub-skill based on user intent
3. Sub-skills live in `skills/<name>/SKILL.md`; the shared knowledge base lives in `reference/`
4. The `examples/` folder contains a fully anonymized custom workflow activity scaffold

## 📦 Distribution

Skills can be consumed four ways — pick whichever fits your tooling:

### 1. GitHub Copilot CLI Marketplace

The repo itself is a Copilot CLI plugin marketplace (see [.github/plugin/marketplace.json](.github/plugin/marketplace.json)). Add it once and install any of the skills as plugins — see [Installation](#installation) above.

### 2. ClawHub Registry

Each skill is published to [ClawHub](https://clawhub.ai), the OpenClaw registry. ClawHub auto-licenses everything as [MIT-0](https://opensource.org/license/0bsd) and runs every release through ClawScan + VirusTotal audits. Installation is one command per skill via the OpenClaw CLI — see [Installation](#installation) above.

The publish pipeline lives in [.github/workflows/clawhub-publish.yml](.github/workflows/clawhub-publish.yml) and is triggered manually (`workflow_dispatch`) so we can dry-run, attach changelogs, and review ClawScan results before each push.

> **Note:** ClawHub publishing is temporarily paused while we work with ClawHub support to resolve a connection issue. Existing published skill versions remain installable via the OpenClaw CLI; new versions will resume publishing once the connection is restored.

### 3. Pre-built Zip Releases

Pre-built zip packages are published on the [Releases](https://github.com/rwilson504/agent-skills/releases) page for agents that don't speak the Copilot CLI plugin protocol or use the ClawHub registry (Cursor, Windsurf, manual installs, air-gapped environments, etc.).

Each release includes:
- **agent-skills-v\<version\>.zip** — Complete bundle with all skills
- **n8n-create-nodes-v\<version\>.zip** — n8n skill only
- **power-platform-custom-connector-v\<version\>.zip** — Power Platform skill only
- **dataverse-classic-workflow-v\<version\>.zip** — Dataverse Classic Workflow skill only

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