# Dataverse Classic Workflow

> Read, analyze, compare, edit, copy, and publish Microsoft Dataverse **Classic Workflows** — the WF4/XAML-based `workflow` table (category=0). This is **not** for Power Automate cloud flows, Business Process Flows, or Business Rules.

This is the human-facing landing page for the skill bundle. The AI agent contract lives in [SKILL.md](SKILL.md), which orchestrates 7 sub-skills behind a shared knowledge base.

## Key capabilities

- Parse and summarize a workflow XAML file (trigger, scope, mode, step-by-step narrative)
- Gap-analyze an existing workflow against new requirements
- Diff two workflow XAML versions structurally
- Round-trip-safe XAML edits that preserve `UserData`, `mva:VisualBasicValue`, and namespace prefix mappings
- Clone a workflow via the Process Template path (with the gotchas the platform doesn't tell you about)
- Scaffold custom workflow activities — `CodeActivity`-derived C# classes targeting .NET Framework 4.6.2, with `[Input]` / `[Output]` / `[RequiredArgument]` / `[Default]` / `[ReferenceTarget]` / `[AttributeTarget]` parameter attributes and `spkl`'s `[CrmPluginRegistration]` registration
- Publish via Power Platform CLI (`pac solution pack` / `import` + activation)

## Use cases

- Working with classic workflows extracted from a Dataverse solution (`pac solution clone` / `unpack`)
- Modernizing legacy CRM/Dynamics 365 workflows
- Authoring new C# workflow activity assemblies that XAML can call via `mxswa:ActivityReference`
- Cross-environment promotion (DEV → TEST → PROD) of workflow solutions
- Air-gapped environments (Online, on-premises, GCC, GCC-High, DoD) — no live env required for read/analyze/compare/edit

## Prerequisites

- Workflow XAML files extracted from a Dataverse solution (typically via `pac solution clone` or `pac solution unpack`)
- Power Platform CLI (`pac`) — required only for the `publish-workflow` sub-skill
- For custom workflow activities: .NET Framework 4.6.2 SDK + `Microsoft.CrmSdk.Workflow` NuGet package

## Install (this skill only)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add rwilson504/agent-skills
copilot plugin install dataverse-classic-workflow@agent-skills
```

### Claude Code

```bash
claude install-github-skill rwilson504/agent-skills/dataverse-classic-workflow
```

### ClawHub

```bash
openclaw skills install dataverse-classic-workflow
```

ClawHub publishing is currently paused — see the [root README](../README.md#installation) for status and alternative install methods (Cursor, Windsurf, VS Code, manual file copy).

## What's in this folder

### Sub-skills

| Sub-skill | Purpose |
|---|---|
| [`skills/read-workflow/`](skills/read-workflow/SKILL.md) | Parse + summarize a workflow |
| [`skills/analyze-workflow/`](skills/analyze-workflow/SKILL.md) | Gap-analyze against requirements |
| [`skills/compare-workflows/`](skills/compare-workflows/SKILL.md) | Diff two workflow XAML files |
| [`skills/copy-workflow/`](skills/copy-workflow/SKILL.md) | Clone via Process Template (with gotchas) |
| [`skills/write-workflow/`](skills/write-workflow/SKILL.md) | Round-trip-safe XAML edits |
| [`skills/write-custom-activity/`](skills/write-custom-activity/SKILL.md) | Scaffold C# `CodeActivity` assemblies |
| [`skills/publish-workflow/`](skills/publish-workflow/SKILL.md) | Activate / import / export via PAC CLI |

### Shared knowledge base

| Path | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | Top-level orchestrator + routing table |
| [`reference/xaml-anatomy.md`](reference/xaml-anatomy.md) | WF4 XAML structure, namespaces, `ActivityReference` |
| [`reference/activity-types.md`](reference/activity-types.md) | `mxswa:*` / `mcwc:*` activity catalog |
| [`reference/vb-expressions.md`](reference/vb-expressions.md) | `[expr]` bracket dynamic value patterns |
| [`reference/trigger-types.md`](reference/trigger-types.md) | `TriggerType`, `Scope`, `Mode`, `RunAs` reference |
| [`reference/web-research.md`](reference/web-research.md) | MS Learn citations + AsyncOperation states + best practices |
| [`reference/example-workflow.xaml`](reference/example-workflow.xaml) | One anonymized end-to-end example |
| [`examples/custom-activity-substring.cs`](examples/custom-activity-substring.cs) | `CodeActivity` scaffold (anonymized) |

## Resources

- [Workflow processes (MS Learn)](https://learn.microsoft.com/power-automate/workflow-processes) — authoritative reference
- [Workflow extensions / Custom workflow activities (MS Learn)](https://learn.microsoft.com/power-apps/developer/data-platform/workflow/workflow-extensions)
- [Power Platform CLI](https://learn.microsoft.com/power-platform/developer/cli/introduction)

## License

[MIT-0](https://opensource.org/license/0bsd) — no attribution required.
