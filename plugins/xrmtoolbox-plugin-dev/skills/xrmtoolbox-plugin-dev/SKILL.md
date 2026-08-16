---
name: xrmtoolbox-plugin-dev
description: 'Build, debug, and ship XrmToolBox plugins (tools) that connect to Dataverse / Dynamics 365 CE. USE WHEN: creating a new XrmToolBox tool, scaffolding PluginBase/PluginControlBase, wiring ExportMetadata, calling the OrganizationService via ExecuteMethod/WorkAsync, handling UpdateConnection, showing errors (ShowErrorDialog), logging, notifications, saving tool settings, adding interfaces (IGitHubPlugin, IHelpPlugin, IStatusBarMessenger, IMessageBusHost, IAboutPlugin, ISettingsPlugin, IShortcutReceiver), setting up Visual Studio debug (post-build copy to Plugins, .csproj.user launch settings, pdb-for-breakpoints, /overridepath, /connection, /plugin), debugging on Windows-on-ARM (ARM64 can''t debug .NET Framework in VS Code — use Visual Studio 2022), MSBuild /restore, Hot Reload limits, storing secrets with DPAPI vs CryptoManager, or packaging/distributing via NuGet to the Tool Library. DO NOT USE FOR: Dataverse plugins/SDK steps registered in CRM, FetchXML query syntax, or general C# unrelated to XrmToolBox.'
license: MIT-0
version: 1.0.0
metadata: { "author": "rwilson504", "version": "1.0.0", "category": "development", "tags": ["xrmtoolbox", "dataverse", "dynamics-365", "winforms", "plugin-development", "csharp"], "openclaw": { "homepage": "https://github.com/rwilson504/agent-skills/tree/main/plugins/xrmtoolbox-plugin-dev", "emoji": "🧰" } }
---

# XrmToolBox Plugin Development

XrmToolBox tools are WinForms `UserControl`s hosted inside the XrmToolBox shell. The shell owns the
Dataverse connection and hands your tool an `IOrganizationService`. Always call the service through
`ExecuteMethod` + `WorkAsync` so the UI never freezes and the user is prompted to connect when needed.

Reference: https://www.xrmtoolbox.com/documentation/for-developers/

## Golden rules

- Inherit `PluginControlBase` (single connection) or `MultipleConnectionsPluginControlBase` (multi-org).
- Never touch `Service` directly from UI events — route through `ExecuteMethod(...)`.
- Do all CRM/SDK calls inside `WorkAsync` (runs on a background thread).
- **Never use early-bound entity types / `EnableProxyTypes`** — it conflicts with other tools and breaks the shell's connections.
- Keep the assembly name / files under a `Plugins` folder for the shell to discover them.
- Target `.NET Framework 4.8` (or 4.6.2+); XrmToolBox is a Framework WinForms app.

## 1. Two classes per tool

A tool = a **plugin class** (metadata + factory) and a **control class** (the UI).

```csharp
using System.ComponentModel.Composition;
using XrmToolBox.Extensibility;
using XrmToolBox.Extensibility.Interfaces;

namespace MyCompany.MyTool
{
    [Export(typeof(IXrmToolBoxPlugin)),
     ExportMetadata("Name", "My Tool"),
     ExportMetadata("Description", "What my tool does"),
     ExportMetadata("BackgroundColor", "MediumBlue"),
     ExportMetadata("PrimaryFontColor", "White"),
     ExportMetadata("SecondaryFontColor", "LightGray"),
     ExportMetadata("SmallImageBase64", null),   // 32x32 base64 png (optional)
     ExportMetadata("BigImageBase64", null)]      // 80x80 base64 png (optional)
    public class MyToolPlugin : PluginBase
    {
        public override IXrmToolBoxPluginControl GetControl() => new MyToolControl();
    }
}
```

```csharp
using System;
using System.Windows.Forms;
using Microsoft.Crm.Sdk.Messages;
using Microsoft.Xrm.Sdk;
using XrmToolBox.Extensibility;

namespace MyCompany.MyTool
{
    public partial class MyToolControl : PluginControlBase
    {
        public MyToolControl() => InitializeComponent();

        private void btnWhoAmI_Click(object sender, EventArgs e)
            => ExecuteMethod(WhoAmI);   // ensures a live connection first

        private void WhoAmI()
        {
            WorkAsync(new WorkAsyncInfo
            {
                Message = "Retrieving your user id...",
                Work = (worker, args) =>          // background thread
                {
                    var resp = (WhoAmIResponse)Service.Execute(new WhoAmIRequest());
                    args.Result = resp.UserId;
                },
                ProgressChanged = args => SetWorkingMessage(args.UserState?.ToString()),
                PostWorkCallBack = args =>        // back on UI thread
                {
                    if (args.Error != null) { ShowErrorDialog(args.Error); return; }
                    MessageBox.Show($"You are {(Guid)args.Result}");
                },
                IsCancelable = true,
                MessageWidth = 340,
                MessageHeight = 150
            });
        }
    }
}
```

## 2. Connection lifecycle

The user can switch connections while your tool is open. Override to react (reload data, clear caches):

```csharp
public override void UpdateConnection(IOrganizationService newService,
    ConnectionDetail detail, string actionName, object parameter)
{
    base.UpdateConnection(newService, detail, actionName, parameter);
    // e.g. reload metadata for the newly connected org
}
```

Cancel/save on close by overriding `ClosingPlugin(PluginCloseInfo info)` and setting `info.Cancel`.

## 3. Error handling (v1.2022.2.54+)

Use the shared dialog so all tools report errors consistently. If the tool implements `IGitHubPlugin`
the dialog offers a "Create issue" action.

```csharp
if (args.Error != null) { ShowErrorDialog(args.Error); return; }
// advanced:
ShowErrorDialog(ex, heading: "Request failed", extrainfo: "context info", allownewissue: true);
```

## 4. Logging & notifications

```csharp
LogInfo("info"); LogWarning("warning"); LogError("error"); OpenLogFile();
ShowInfoNotification("Visit the portal", new Uri("https://www.xrmtoolbox.com"), 32);
ShowWarningNotification("...", null); ShowErrorNotification("...", null);
HideNotification();
```

Logs land in `%AppData%\MscrmTools\XrmToolBox\Logs`.

## 5. Optional interfaces (add menu items / integrations)

Implement any of these on the control class. Real example (FetchXML Builder):
`IGitHubPlugin, IPayPalPlugin, IMessageBusHost, IHelpPlugin, IStatusBarMessenger, IShortcutReceiver, IAboutPlugin, IDuplicatableTool, ISettingsPlugin`.

| Interface | Adds |
|-----------|------|
| `IGitHubPlugin` | GitHub Issues menu; needs `UserName` + `RepositoryName` |
| `IHelpPlugin` | Help menu; needs `HelpUrl` |
| `IPayPalPlugin` | Donate menu; needs `DonationDescription` + `EmailAccount` |
| `IStatusBarMessenger` | Push progress text/bar to the shell status bar |
| `IMessageBusHost` | Send/receive data to/from other tools (`OnIncomingMessage`, `OnOutgoingMessage`) |
| `IAboutPlugin` | Custom About action |
| `ISettingsPlugin` | Hook into shell settings load/save |
| `IDuplicatableTool` | Allow "Duplicate tool" |
| `IShortcutReceiver` | Handle keyboard shortcuts |

```csharp
public partial class MyToolControl : PluginControlBase, IGitHubPlugin, IHelpPlugin, IPayPalPlugin
{
    public string UserName => "myorg";
    public string RepositoryName => "MyTool";
    public string HelpUrl => "https://mytool.example.com/help";
    public string DonationDescription => "My Tool Fan Club";
    public string EmailAccount => "me@example.com";
}
```

## 6. Tool settings (persist per user)

Create a simple `[DataContract]`/serializable settings class and use the shell's settings helpers
(`SettingsManager.Instance.Save/TryLoad`) or store in your own file under the storage folder. Load in
control constructor / `OnLoad`, save in `ClosingPlugin`.

## 7. Multiple connections

Inherit `MultipleConnectionsPluginControlBase` when moving data between orgs. It extends
`PluginControlBase`, so everything above still applies; use `AddAdditionalOrganization()` and the
`AdditionalConnectionDetails` collection for the second+ service.

## 8. Debug from Visual Studio

The `XrmToolBox` NuGet package (id `XrmToolBoxPackage`) drops `XrmToolBox.exe` + its dependencies
into `bin\Debug` on build, so the exe you launch is already there. Point the project's Debug target
at it and copy your dll into a `Plugins` subfolder.

**Post-build event** (only runs in Debug, moves the plugin dll where the shell looks for it):
```
if $(ConfigurationName) == Debug (
  IF NOT EXIST Plugins mkdir Plugins
  move /Y $(TargetFileName) Plugins
)
```

**Project > Debug > Start external program:** `$(TargetDir)XrmToolBox.exe` (i.e. `...\bin\Debug\XrmToolBox.exe`)

**Command line arguments:**
```
/overridepath:.  /connection:"My Dev Org"  /plugin:"My Tool"
```
- `/overridepath:.` — use the build folder as the XrmToolBox root (its own `Plugins`, `Settings`, `Logs`, and saved connections live under `bin\Debug`, isolated from your real XrmToolBox).
- `/connection:"..."` — auto-connect to a saved connection on start (add this only *after* you have saved one).
- `/plugin:"..."` — auto-open your tool (the `Name` from `ExportMetadata`).

Set a breakpoint, F5, and XrmToolBox launches with your tool attached.
Reference: https://www.xrmtoolbox.com/documentation/for-developers/debug/

### 8.1 Breakpoints need the PDB in `Plugins`
The post-build `move` moves only the **dll**, leaving the **.pdb** behind in `bin\Debug`, so plugin
breakpoints won't bind. Copy the pdb next to the moved dll. To avoid polluting a shippable csproj,
put this in the **git-ignored `.csproj.user`** (MSBuild auto-imports it), not the csproj:
```xml
<Target Name="CopyPluginPdbForDebug" AfterTargets="PostBuildEvent" Condition="'$(Configuration)' == 'Debug'">
  <Copy SourceFiles="$(TargetDir)$(TargetName).pdb" DestinationFolder="$(TargetDir)Plugins"
        SkipUnchangedFiles="true" Condition="Exists('$(TargetDir)$(TargetName).pdb')" />
</Target>
```

### 8.2 Debug launch lives in `.csproj.user` (not the csproj)
For classic (non-SDK) projects, the start settings go in `<Project>.csproj.user`, which is git-ignored
by the standard VS `.gitignore` (`*.user`) — so it never ships:
```xml
<Project ToolsVersion="Current" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup Condition="'$(Configuration)|$(Platform)' == 'Debug|AnyCPU'">
    <StartAction>Program</StartAction>
    <StartProgram>$(TargetDir)XrmToolBox.exe</StartProgram>
    <StartWorkingDirectory>$(TargetDir)</StartWorkingDirectory>
    <StartArguments>/overridepath:. /plugin:"My Tool"</StartArguments>
  </PropertyGroup>
</Project>
```

### 8.3 Command-line builds need `/restore`
An MSBuild CLI build can fail with `Your project file doesn't list 'win' as a "RuntimeIdentifier"`.
Run restore first (VS/F5 does this automatically): `msbuild MyTool.csproj /restore /t:Build ...`.

### 8.4 Keep the shippable csproj clean
VS and manual debug tinkering often leave noise in the csproj — revert these before committing:
- an empty `<PropertyGroup><StartupObject /></PropertyGroup>` VS adds,
- post-build `move` flipped to `copy`/extra pdb lines (move that to `.csproj.user` per 8.1),
- a stripped/added UTF-8 BOM on line 1 (classic csproj files use a BOM).

## 9. Debugging on Windows on ARM (ARM64) — important

VS Code's C# extension on **ARM64 Windows ships an ARM64-only debugger** that "can only debug ARM64
processes." **.NET Framework never runs as ARM64** — it runs x86/x64 under emulation (XrmToolBox.exe
is x86) — so **VS Code cannot debug an XrmToolBox plugin on an ARM64 machine**. This is a platform
limitation, not a config issue.

- **Do breakpoint debugging in Visual Studio 2022** — on ARM64 it debugs emulated x86/x64 fine.
- To just *run* the tool from VS Code (no breakpoints), launch the exe via a task with the right cwd.
- A VS Code `launch.json` for .NET Framework would use `"type": "clr"` (from `ms-dotnettools.csharp`),
  which is what fails on ARM64; it works on x64 hosts.

## 10. Hot Reload limits (.NET Framework)
Hot Reload applies **method-body edits** live, but **new methods, new fields, and WinForms designer/
constructor changes are "rude edits"** — they require a full rebuild + relaunch. Also, a build fails
with a file-lock error (`being used by another process`) while XrmToolBox is still running; stop
debugging first.

## 11. Storing secrets (tokens, keys)
XrmToolBox connection passwords use `McTools.Xrm.Connection`'s `CryptoManager` (Rijndael + an embedded
passphrase) — **reversible by design** so connection files stay portable. For **bearer tokens / OAuth**
prefer **Windows DPAPI** (`ProtectedData.Protect(..., DataProtectionScope.CurrentUser)`): no key in the
assembly, ciphertext bound to the current user+machine, and a copied/roamed settings file simply fails
to decrypt (return empty → prompt re-auth). Use a distinct **entropy** per secret so unrelated secrets
can't cross-decrypt. Don't "match XrmToolBox's pattern" for tokens — that's a reversibility downgrade.

## 12. Contributing to a repo you don't own (forks + submodules)
- Keep personal dev/agent files out of the repo: add them to **`.git/info/exclude`** (local-only, never
  committed) rather than editing the shared `.gitignore`.
- PRs come from **your fork**; add it as a remote (`git remote add fork <your-fork-url>`), push, then
  `gh pr create --repo <upstream> --base <branch> --head <you>:<branch>`.
- **Submodules:** commit + PR the submodule **first** (its own repo). The parent PR bumps the submodule
  pointer to a commit that only exists on your fork branch until the submodule PR merges — call this out
  in the parent PR ("merge the submodule PR first").
- You **can't apply labels** on an upstream repo without triage access — note suggested labels in the body.

## 13. Distribute via NuGet (Tool Library)

Package rules for shell discovery:
- Tags **must start with** `XrmToolBox` but not equal it, e.g. `XrmToolBox Plugin MyTool`.
- Fill `title`, `version`, `authors`, `description`.
- Version your assemblies to match the package version (else updates won't be detected).
- Put all files under a `Plugins` target folder; **do not** include CRM SDK assemblies already shipped with XrmToolBox.
- Depend on `XrmToolBox` at the version you built against.

```xml
<package>
  <metadata>
    <id>MyCompany.MyTool</id>
    <version>1.2026.7.1</version>
    <title>My Tool for XrmToolBox</title>
    <authors>My Name</authors>
    <description>What my tool does</description>
    <tags>XrmToolBox Plugin MyTool</tags>
    <dependencies>
      <dependency id="XrmToolBox" version="1.2016.3.30" />
    </dependencies>
  </metadata>
  <files>
    <file src="MyTool\bin\Release\MyCompany.*.dll" target="lib\net452\Plugins" />
  </files>
</package>
```

Reference: https://www.xrmtoolbox.com/documentation/for-developers/deploy-your-plugin-in-plugins-store/

## Quick checklist

- [ ] Plugin class `[Export(typeof(IXrmToolBoxPlugin))]` + all `ExportMetadata` filled.
- [ ] Control inherits `PluginControlBase`; CRM calls only via `ExecuteMethod` → `WorkAsync`.
- [ ] No early-bound types / proxy types enabled.
- [ ] Errors via `ShowErrorDialog`; progress via `SetWorkingMessage`.
- [ ] Debug: post-build copies dll to `Plugins`, external program = XrmToolBox.exe, args set.
- [ ] Debug launch + pdb-copy live in `.csproj.user` (git-ignored); shippable csproj stays clean.
- [ ] On ARM64: debug in Visual Studio 2022, not VS Code (.NET Framework can't be debugged by the ARM64 vsdbg).
- [ ] Secrets/tokens stored with DPAPI (CurrentUser) + per-secret entropy, not the reversible CryptoManager.
- [ ] Package: `Plugins` folder, `XrmToolBox`-prefixed tags, versioned, depends on XrmToolBox.
