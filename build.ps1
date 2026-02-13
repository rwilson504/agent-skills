# Build script for agent-skills distribution packages (PowerShell)
# Creates zip files for individual skills and a complete bundle
#
# Usage:
#   .\build.ps1                  # Uses version from git tag or defaults to 0.0.0-dev
#   .\build.ps1 -Version 1.0.0  # Explicit version

param(
    [string]$Version
)

$ErrorActionPreference = "Stop"

# Determine version: param > env > git tag > fallback
if (-not $Version) {
    $Version = $env:VERSION
}
if (-not $Version) {
    try {
        $Version = (git describe --tags --abbrev=0 2>$null) -replace '^v', ''
    } catch { }
}
if (-not $Version) {
    $Version = "0.0.0-dev"
}

$DistDir = "dist"
$RepoName = "agent-skills"

Write-Host "Building $RepoName distribution packages (v$Version)..." -ForegroundColor Cyan
Write-Host ""

# Create dist directory
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
}

# Remove old zips
Write-Host "Removing old zip files..."
Get-ChildItem -Path $DistDir -Filter "*.zip" -ErrorAction SilentlyContinue | Remove-Item -Force

# Auto-discover skill folders (any directory containing a SKILL.md)
$Skills = Get-ChildItem -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "SKILL.md")
} | Select-Object -ExpandProperty Name

if ($Skills.Count -eq 0) {
    Write-Error "No skill folders found (directories containing SKILL.md)"
    exit 1
}

Write-Host "Found $($Skills.Count) skill(s):"
foreach ($skill in $Skills) {
    Write-Host "  - $skill"
}
Write-Host ""

# Build individual skill zips
Write-Host "Building individual skill packages..."
foreach ($skill in $Skills) {
    $zipName = "$skill-v$Version.zip"
    $zipPath = Join-Path $DistDir $zipName
    
    # Get all files except evaluations folder
    $filesToZip = Get-ChildItem -Path $skill -Recurse -File | Where-Object {
        $_.FullName -notmatch "\\evaluations\\"
    }
    
    # Use Compress-Archive
    $tempDir = Join-Path $env:TEMP "agent-skills-build-$skill"
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Copy files preserving structure
    foreach ($file in $filesToZip) {
        $relativePath = $file.FullName.Substring((Resolve-Path $skill).Path.Length + 1)
        $destPath = Join-Path $tempDir $skill $relativePath
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $file.FullName -Destination $destPath
    }
    
    Compress-Archive -Path (Join-Path $tempDir "*") -DestinationPath $zipPath -Force
    Remove-Item -Recurse -Force $tempDir
    
    Write-Host "  Packaged: $zipName"
}

# Build complete bundle
Write-Host ""
Write-Host "Building complete bundle..."
$bundleName = "$RepoName-v$Version.zip"
$bundlePath = Join-Path $DistDir $bundleName

$tempDir = Join-Path $env:TEMP "agent-skills-build-bundle"
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy skill folders
foreach ($skill in $Skills) {
    $filesToZip = Get-ChildItem -Path $skill -Recurse -File | Where-Object {
        $_.FullName -notmatch "\\evaluations\\"
    }
    foreach ($file in $filesToZip) {
        $relativePath = $file.FullName.Substring((Resolve-Path $skill).Path.Length + 1)
        $destPath = Join-Path $tempDir $skill $relativePath
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $file.FullName -Destination $destPath
    }
}

# Copy root-level docs
if (Test-Path "README.md") { Copy-Item "README.md" -Destination $tempDir }
if (Test-Path "LICENSE") { Copy-Item "LICENSE" -Destination $tempDir }

Compress-Archive -Path (Join-Path $tempDir "*") -DestinationPath $bundlePath -Force
Remove-Item -Recurse -Force $tempDir

Write-Host "  Packaged: $bundleName"

# Show results
Write-Host ""
Write-Host "Build complete! Files in ${DistDir}/:" -ForegroundColor Green
Write-Host ""
Get-ChildItem -Path $DistDir -Filter "*.zip" | Format-Table Name, @{
    Label = "Size"
    Expression = { "{0:N1} KB" -f ($_.Length / 1KB) }
} -AutoSize
