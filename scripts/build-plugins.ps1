<#
.SYNOPSIS
    Build the plugins/ tree and .github/plugin/marketplace.json from
    plugins.yml + src/.

.DESCRIPTION
    Single source of truth for the plugins/ generated artifact:
      - For each plugin in plugins.yml, copies declared skills from
        src/skills/<name>/ into plugins/<plugin>/skills/<name>/ and
        declared agents from src/agents/<name>.agent.md into
        plugins/<plugin>/agents/.
      - Generates plugins/<plugin>/plugin.json with author / homepage /
        repository / license / keywords / category fields populated from
        plugins.yml.
      - Generates .github/plugin/marketplace.json listing every plugin.
      - Cross-checks each plugin's `version:` against the matching skill's
        SKILL.md frontmatter top-level `version:` (when the plugin has one
        primary skill of the same name) and refuses to build on mismatch.

    Skills declared by multiple plugins are duplicated into each plugin
    folder (Copilot CLI plugins have no dependency mechanism).

    The plugins/ tree is REPLACED on every run. Never edit anything under
    plugins/ by hand — it will be overwritten. Use scripts/lint.ps1 to
    detect drift.

    Requires: PowerShell module 'powershell-yaml' (auto-installs to
    CurrentUser scope on first run if missing).

.EXAMPLE
    pwsh scripts/build-plugins.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
)

$ErrorActionPreference = 'Stop'

# --- Ensure powershell-yaml ---
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "Installing 'powershell-yaml' module (CurrentUser scope)..." -ForegroundColor Yellow
    Install-Module powershell-yaml -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module powershell-yaml -ErrorAction Stop

# --- Paths ---
$pluginsYml   = Join-Path $RepoRoot 'plugins.yml'
$srcAgents    = Join-Path $RepoRoot 'src/agents'
$srcSkills    = Join-Path $RepoRoot 'src/skills'
$pluginsRoot  = Join-Path $RepoRoot 'plugins'
$marketJson   = Join-Path $RepoRoot '.github/plugin/marketplace.json'

if (-not (Test-Path $pluginsYml)) { throw "plugins.yml not found at $pluginsYml" }
if (-not (Test-Path $srcSkills))  { throw "src/skills not found at $srcSkills" }
if (-not (Test-Path $srcAgents))  { throw "src/agents not found at $srcAgents" }

# --- Load YAML ---
$yamlText = Get-Content $pluginsYml -Raw
$config   = ConvertFrom-Yaml $yamlText

if (-not $config.marketplace) { throw "plugins.yml is missing 'marketplace:' section" }
if (-not $config.plugins)     { throw "plugins.yml is missing 'plugins:' section" }

# --- Helpers ---
function Get-SkillFrontmatterField {
    param(
        [Parameter(Mandatory)] [string]$SkillMdPath,
        [Parameter(Mandatory)] [string]$Field
    )
    $content = Get-Content $SkillMdPath -Raw
    if ($content -notmatch '^---\s*\r?\n([\s\S]*?)\r?\n---') {
        throw "$SkillMdPath has no YAML frontmatter"
    }
    $fm = $Matches[1]
    $pattern = "(?m)^${Field}:\s*(.+?)\s*$"
    if ($fm -match $pattern) {
        return $Matches[1].Trim().Trim('"').Trim("'")
    }
    return $null
}

# --- Wipe and recreate plugins/ ---
if (Test-Path $pluginsRoot) {
    Write-Host "Removing existing plugins/ tree..." -ForegroundColor DarkGray
    Remove-Item -Recurse -Force $pluginsRoot
}
New-Item -ItemType Directory -Force -Path $pluginsRoot | Out-Null

# --- Build each plugin ---
$marketplacePlugins = @()
$builtCount = 0

foreach ($pluginName in ($config.plugins.Keys | Sort-Object)) {
    $plugin = $config.plugins[$pluginName]
    Write-Host "Building plugin: $pluginName" -ForegroundColor Cyan

    if (-not $plugin.version)     { throw "[$pluginName] plugins.yml entry missing 'version'" }
    if (-not $plugin.description) { throw "[$pluginName] plugins.yml entry missing 'description'" }

    $pluginDir = Join-Path $pluginsRoot $pluginName
    New-Item -ItemType Directory -Force -Path $pluginDir | Out-Null

    # --- Copy agents ---
    $agentList = @()
    if ($plugin.agents) {
        $agentDir = Join-Path $pluginDir 'agents'
        New-Item -ItemType Directory -Force -Path $agentDir | Out-Null
        foreach ($agentName in $plugin.agents) {
            $src = Join-Path $srcAgents "$agentName.agent.md"
            if (-not (Test-Path $src)) {
                throw "[$pluginName] agent '$agentName' not found at $src"
            }
            Copy-Item $src $agentDir -Force
            $agentList += $agentName
        }
        Write-Host "  agents: $($agentList -join ', ')" -ForegroundColor DarkGray
    }

    # --- Copy skills (full folder copy) ---
    $skillList = @()
    if ($plugin.skills -and $plugin.skills.Count -gt 0) {
        $skillDir = Join-Path $pluginDir 'skills'
        New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
        foreach ($skillName in $plugin.skills) {
            $src = Join-Path $srcSkills $skillName
            if (-not (Test-Path $src)) {
                throw "[$pluginName] skill '$skillName' not found at $src"
            }
            $skillMd = Join-Path $src 'SKILL.md'
            if (-not (Test-Path $skillMd)) {
                throw "[$pluginName] skill '$skillName' missing SKILL.md at $skillMd"
            }

            # Cross-check version coherence: when the plugin has one
            # primary skill of the same name, its SKILL.md `version:` must
            # match the plugins.yml plugin `version:`.
            if ($skillName -eq $pluginName) {
                $skillVer = Get-SkillFrontmatterField -SkillMdPath $skillMd -Field 'version'
                if ($skillVer -and $skillVer -ne $plugin.version) {
                    throw "[$pluginName] version drift: SKILL.md version '$skillVer' != plugins.yml version '$($plugin.version)'"
                }
            }

            Copy-Item -Recurse -Force $src $skillDir
            $skillList += $skillName
        }
        Write-Host "  skills: $($skillList -join ', ')" -ForegroundColor DarkGray
    }

    # --- Generate per-plugin plugin.json ---
    $pluginManifest = [ordered]@{
        name        = $pluginName
        description = $plugin.description
        version     = $plugin.version
    }
    if ($config.marketplace.owner_name) {
        $author = [ordered]@{ name = $config.marketplace.owner_name }
        if ($config.marketplace.owner_url) { $author.url = $config.marketplace.owner_url }
        $pluginManifest.author = $author
    }
    if ($plugin.homepage)   { $pluginManifest.homepage   = $plugin.homepage }
    if ($plugin.repository) { $pluginManifest.repository = $plugin.repository }
    if ($plugin.license)    { $pluginManifest.license    = $plugin.license }
    if ($plugin.category)   { $pluginManifest.category   = $plugin.category }
    if ($plugin.keywords)   {
        $pluginManifest.keywords = $plugin.keywords
        # `tags` historically mirrored `keywords` in this repo's manifests.
        $pluginManifest.tags     = $plugin.keywords
    }
    if ($agentList.Count -gt 0) { $pluginManifest.agents = 'agents/' }
    if ($skillList.Count -gt 0) { $pluginManifest.skills = 'skills/' }

    $manifestPath = Join-Path $pluginDir 'plugin.json'
    ($pluginManifest | ConvertTo-Json -Depth 10) + "`n" |
        Set-Content -Path $manifestPath -Encoding UTF8 -NoNewline

    # --- Add to marketplace listing ---
    $marketEntry = [ordered]@{
        name        = $pluginName
        source      = "plugins/$pluginName"
        description = $plugin.description
        version     = $plugin.version
    }
    if ($plugin.keywords) { $marketEntry.keywords = $plugin.keywords }
    if ($plugin.category) { $marketEntry.category = $plugin.category }
    if ($plugin.license)  { $marketEntry.license  = $plugin.license }
    $marketplacePlugins += $marketEntry

    $builtCount++
}

# --- Write marketplace.json ---
$marketplaceManifest = [ordered]@{
    name = $config.marketplace.name
}
if ($config.marketplace.owner_name) {
    $owner = [ordered]@{ name = $config.marketplace.owner_name }
    if ($config.marketplace.owner_url)   { $owner.url   = $config.marketplace.owner_url }
    if ($config.marketplace.owner_email) { $owner.email = $config.marketplace.owner_email }
    $marketplaceManifest.owner = $owner
}
$metadata = [ordered]@{
    description = $config.marketplace.description
    version     = $config.marketplace.version
}
if ($config.marketplace.plugin_root) {
    $metadata.pluginRoot = $config.marketplace.plugin_root
}
$marketplaceManifest.metadata = $metadata
$marketplaceManifest.plugins  = $marketplacePlugins

$marketplaceDir = Split-Path $marketJson -Parent
New-Item -ItemType Directory -Force -Path $marketplaceDir | Out-Null
($marketplaceManifest | ConvertTo-Json -Depth 10) + "`n" |
    Set-Content -Path $marketJson -Encoding UTF8 -NoNewline

Write-Host ''
Write-Host "Built $builtCount plugin(s)" -ForegroundColor Green
$marketRel = $marketJson -replace [regex]::Escape($RepoRoot + [System.IO.Path]::DirectorySeparatorChar), ''
Write-Host "Wrote $marketRel" -ForegroundColor Green
