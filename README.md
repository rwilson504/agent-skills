# Agent Skills Repository

A collection of specialized skills and tools for building and deploying integrations across various platforms. This repository serves as a central hub for agent-focused development skills, currently featuring Power Platform custom connectors and n8n community nodes.

## 🎯 Overview

This repository contains expertise and resources for:

- **Power Platform Custom Connectors**: Skills for creating independent publisher and verified publisher connectors
- **n8n Node Development**: Skills for creating new n8n community nodes

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

### Installation

Clone this repository to access the skills:

```bash
git clone https://github.com/rwilson504/agent-skills.git
cd agent-skills
```

Or download individual skill packages from the [latest release](https://github.com/rwilson504/agent-skills/releases/latest).

## 📁 Repository Structure

```
agent-skills/
├── n8n-create-nodes/                    # n8n node development skill
│   ├── SKILL.md                         # Main skill instructions
│   ├── CREDENTIAL_PATTERNS.md           # Credential implementation patterns
│   ├── TRIGGER_PATTERNS.md              # Trigger node patterns
│   ├── EXAMPLES.md                      # Full examples
│   ├── COMMON_MISTAKES.md               # Common mistakes and fixes
│   └── evaluations/                     # Test scenarios
├── power-platform-custom-connector/     # Power Platform connector skill
│   ├── SKILL.md                         # Main skill instructions
│   ├── AUTH_PATTERNS.md                 # Authentication patterns
│   ├── OPENAPI_EXTENSIONS.md            # x-ms-* OpenAPI extensions
│   ├── POLICY_TEMPLATES.md              # Policy template reference
│   ├── CUSTOM_CODE.md                   # Custom code (script.csx)
│   ├── WEBHOOK_TRIGGERS.md              # Webhook trigger patterns
│   ├── EXAMPLES.md                      # Full examples
│   ├── COMMON_MISTAKES.md               # Common mistakes and fixes
│   └── evaluations/                     # Test scenarios
├── build.sh                             # Build script (bash)
├── build.ps1                            # Build script (PowerShell)
└── .github/workflows/release.yml        # CI: build + publish releases
```

## 🔧 Usage

### Creating a Power Platform Custom Connector

1. Navigate to the `power-platform-custom-connector/` directory
2. Start with `SKILL.md` for the main instructions
3. Reference `AUTH_PATTERNS.md`, `OPENAPI_EXTENSIONS.md`, and other files as needed

### Creating an n8n Community Node

1. Navigate to the `n8n-create-nodes/` directory
2. Start with `SKILL.md` for the main instructions
3. Reference `CREDENTIAL_PATTERNS.md`, `TRIGGER_PATTERNS.md`, and other files as needed

## 📦 Distribution Packages

Pre-built zip packages are available on the [Releases](https://github.com/rwilson504/agent-skills/releases) page.

Each release includes:
- **agent-skills-v\<version\>.zip** — Complete bundle with all skills
- **n8n-create-nodes-v\<version\>.zip** — n8n skill only
- **power-platform-custom-connector-v\<version\>.zip** — Power Platform skill only

### Building Locally

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