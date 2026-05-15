# Build script for agent-skills distribution packages (PowerShell)
#
# Regenerates plugins/ (so zips always reflect src/ + plugins.yml), then
# packages each plugin folder under plugins/<name>/ as its own zip and
# bundles all plugins + root docs into a single zip.
#
# Per-plugin zip name: <plugin>-v<version>.zip (version from plugin.json).
# Bundle zip name:     agent-skills-v<Version>.zip (from -Version / git tag).
#
# Usage:
#   .\build.ps1                  # Uses version from git tag or 0.0.0-dev
#   .\build.ps1 -Version 1.0.0  # Explicit bundle version
#   .\build.ps1 -SkipBuild       # Skip the regenerate-plugins step

[CmdletBinding()]
param(
    [string]$Version,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

# --- Determine bundle version: param > env > git tag > fallback ---
if (-not $Version) { $Version = $env:VERSION }
if (-not $Version) {
    try { $Version = (git describe --tags --abbrev=0 2>$null) -replace '^v', '' } catch { }
}
if (-not $Version) { $Version = '0.0.0-dev' }

$RepoRoot   = $PSScriptRoot
$DistDir    = Join-Path $RepoRoot 'dist'
$PluginsDir = Join-Path $RepoRoot 'plugins'
$BuildPS1   = Join-Path $RepoRoot 'scripts/build-plugins.ps1'
$RepoName   = 'agent-skills'

# --- Step 1: regenerate plugins/ from src/ + plugins.yml ---
if (-not $SkipBuild) {
    Write-Host 'Regenerating plugins/ from src/ + plugins.yml...' -ForegroundColor Cyan
    & pwsh -NoProfile -File $BuildPS1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "scripts/build-plugins.ps1 failed (exit $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
    Write-Host ''
}

if (-not (Test-Path $PluginsDir)) {
    Write-Error "plugins/ does not exist. Run scripts/build-plugins.ps1 first or omit -SkipBuild."
    exit 1
}

Write-Host "Building $RepoName distribution packages (bundle v$Version)..." -ForegroundColor Cyan
Write-Host ''

# --- Prepare dist/ ---
if (-not (Test-Path $DistDir)) { New-Item -ItemType Directory -Path $DistDir | Out-Null }
Write-Host 'Removing old zip files...'
Get-ChildItem -Path $DistDir -Filter '*.zip' -ErrorAction SilentlyContinue | Remove-Item -Force

# --- Discover plugins (each plugins/<name>/ with a plugin.json) ---
$Plugins = Get-ChildItem -Path $PluginsDir -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName 'plugin.json')
} | Select-Object -ExpandProperty Name

if ($Plugins.Count -eq 0) {
    Write-Error 'No plugin folders found under plugins/ (each must contain plugin.json)'
    exit 1
}

Write-Host "Found $($Plugins.Count) plugin(s):"
foreach ($p in $Plugins) { Write-Host "  - $p" }
Write-Host ''

# --- Build per-plugin zips (version from each plugin.json) ---
Write-Host 'Building individual plugin packages...'
foreach ($plugin in $Plugins) {
    $pluginDir   = Join-Path $PluginsDir $plugin
    $manifest    = Get-Content (Join-Path $pluginDir 'plugin.json') -Raw | ConvertFrom-Json
    $pluginVer   = $manifest.version
    if (-not $pluginVer) {
        Write-Error "plugins/$plugin/plugin.json has no 'version' field"
        exit 1
    }
    $zipName = "$plugin-v$pluginVer.zip"
    $zipPath = Join-Path $DistDir $zipName

    # Stage the plugin folder under a temp root so the zip extracts to <plugin>/
    $tempRoot = Join-Path $env:TEMP "agent-skills-build-$plugin"
    if (Test-Path $tempRoot) { Remove-Item -Recurse -Force $tempRoot }
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    Copy-Item -Recurse -Force $pluginDir (Join-Path $tempRoot $plugin)

    # Strip evaluations/ from the staged copy (CI/test artifacts only).
    Get-ChildItem -Path (Join-Path $tempRoot $plugin) -Recurse -Directory -Filter 'evaluations' |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    Compress-Archive -Path (Join-Path $tempRoot '*') -DestinationPath $zipPath -Force
    Remove-Item -Recurse -Force $tempRoot

    Write-Host "  Packaged: $zipName"
}

# --- Build the complete bundle (all plugins + root docs) ---
Write-Host ''
Write-Host 'Building complete bundle...'
$bundleName = "$RepoName-v$Version.zip"
$bundlePath = Join-Path $DistDir $bundleName

$tempRoot = Join-Path $env:TEMP 'agent-skills-build-bundle'
if (Test-Path $tempRoot) { Remove-Item -Recurse -Force $tempRoot }
New-Item -ItemType Directory -Path $tempRoot | Out-Null

Copy-Item -Recurse -Force $PluginsDir (Join-Path $tempRoot 'plugins')
Get-ChildItem -Path (Join-Path $tempRoot 'plugins') -Recurse -Directory -Filter 'evaluations' |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

if (Test-Path (Join-Path $RepoRoot 'README.md')) { Copy-Item (Join-Path $RepoRoot 'README.md') $tempRoot }
if (Test-Path (Join-Path $RepoRoot 'LICENSE'))   { Copy-Item (Join-Path $RepoRoot 'LICENSE')   $tempRoot }

Compress-Archive -Path (Join-Path $tempRoot '*') -DestinationPath $bundlePath -Force
Remove-Item -Recurse -Force $tempRoot

Write-Host "  Packaged: $bundleName"

# --- Report ---
Write-Host ''
Write-Host "Build complete! Files in dist/:" -ForegroundColor Green
Write-Host ''
Get-ChildItem -Path $DistDir -Filter '*.zip' | Format-Table Name, @{
    Label = 'Size'; Expression = { '{0:N1} KB' -f ($_.Length / 1KB) }
} -AutoSize
