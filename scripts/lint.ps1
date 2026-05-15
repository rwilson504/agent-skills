<#
.SYNOPSIS
    Lint the agent-skills marketplace: validate src/, plugins.yml, and built
    artifacts under plugins/ + .github/plugin/marketplace.json.

.DESCRIPTION
    Checks (any failure = exit 1):
      1. Every src/agents/<name>.agent.md has parseable YAML frontmatter
      2. Every src/skills/<name>/SKILL.md has parseable frontmatter and the
         `name:` field matches the folder name and a top-level `version:`
      3. plugins.yml references only agents and skills that exist in src/
      4. Per plugin: plugins.yml `version:` matches src/skills/<plugin>/SKILL.md
         top-level `version:` (when the plugin has a same-named primary skill)
      5. plugins/ tree is in sync with src/ (no drift). Hashes folder content.
      6. .github/plugin/marketplace.json exists and references each plugin
         by name, source, and version

    Skill folders starting with _ (e.g. _template) are skipped.

    Exit codes:
      0 = clean
      1 = errors found

.EXAMPLE
    pwsh scripts/lint.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "Installing 'powershell-yaml' module (CurrentUser scope)..." -ForegroundColor Yellow
    Install-Module powershell-yaml -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module powershell-yaml -ErrorAction Stop

$srcAgents   = Join-Path $RepoRoot 'src/agents'
$srcSkills   = Join-Path $RepoRoot 'src/skills'
$pluginsYml  = Join-Path $RepoRoot 'plugins.yml'
$pluginsRoot = Join-Path $RepoRoot 'plugins'
$marketJson  = Join-Path $RepoRoot '.github/plugin/marketplace.json'

$errors   = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Err  { param([string]$m) $errors.Add($m)   | Out-Null }
function Add-Warn { param([string]$m) $warnings.Add($m) | Out-Null }

function Get-FrontmatterField {
    param(
        [Parameter(Mandatory)] [string]$FilePath,
        [Parameter(Mandatory)] [string]$Field
    )
    $content = Get-Content $FilePath -Raw
    if ($content -notmatch '^---\s*\r?\n([\s\S]*?)\r?\n---') {
        return $null
    }
    $fm = $Matches[1]
    $pattern = "(?m)^${Field}:\s*(.+?)\s*$"
    if ($fm -match $pattern) {
        return $Matches[1].Trim().Trim('"').Trim("'")
    }
    return $null
}

# --- 1. Validate src/agents ---
$availableAgents = @()
if (Test-Path $srcAgents) {
    Get-ChildItem $srcAgents -Filter '*.agent.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.BaseName -replace '\.agent$', ''
        $availableAgents += $name
        $content = Get-Content $_.FullName -Raw
        if ($content -notmatch '^---\s*\r?\n([\s\S]*?)\r?\n---') {
            Add-Err "[agent:$name] missing YAML frontmatter"
        }
    }
} else {
    Add-Err "src/agents/ directory not found"
}

# --- 2. Validate src/skills ---
$availableSkills = @()
$skillVersions   = @{}
if (Test-Path $srcSkills) {
    Get-ChildItem $srcSkills -Directory | Where-Object { $_.Name -notmatch '^_' } | ForEach-Object {
        $name = $_.Name
        $availableSkills += $name
        $skillFile = Join-Path $_.FullName 'SKILL.md'
        if (-not (Test-Path $skillFile)) {
            Add-Err "[skill:$name] missing SKILL.md"
            return
        }
        $content = Get-Content $skillFile -Raw
        if ($content -notmatch '^---\s*\r?\n([\s\S]*?)\r?\n---') {
            Add-Err "[skill:$name] SKILL.md missing YAML frontmatter"
            return
        }
        $declared = Get-FrontmatterField -FilePath $skillFile -Field 'name'
        if (-not $declared) {
            Add-Err "[skill:$name] SKILL.md frontmatter missing 'name:' field"
        } elseif ($declared -ne $name) {
            Add-Err "[skill:$name] frontmatter name '$declared' != folder name '$name'"
        }
        $version = Get-FrontmatterField -FilePath $skillFile -Field 'version'
        if (-not $version) {
            Add-Err "[skill:$name] SKILL.md frontmatter missing top-level 'version:' field"
        } else {
            $skillVersions[$name] = $version
        }
    }
} else {
    Add-Err "src/skills/ directory not found"
}

# --- 3. Validate plugins.yml references ---
$config = $null
if (-not (Test-Path $pluginsYml)) {
    Add-Err "plugins.yml not found"
} else {
    $config = ConvertFrom-Yaml (Get-Content $pluginsYml -Raw)
    if (-not $config.plugins) {
        Add-Err "plugins.yml has no 'plugins:' section"
    } else {
        foreach ($pName in $config.plugins.Keys) {
            $p = $config.plugins[$pName]
            if (-not $p.version)     { Add-Err "[plugin:$pName] missing 'version'" }
            if (-not $p.description) { Add-Err "[plugin:$pName] missing 'description'" }
            if ($p.agents) {
                foreach ($a in $p.agents) {
                    if ($availableAgents -notcontains $a) {
                        Add-Err "[plugin:$pName] references unknown agent '$a'"
                    }
                }
            }
            if ($p.skills) {
                foreach ($s in $p.skills) {
                    if ($availableSkills -notcontains $s) {
                        Add-Err "[plugin:$pName] references unknown skill '$s'"
                    }
                }
            }
        }

        # Warn about agents/skills not used by any plugin
        $usedAgents = @($config.plugins.Values | ForEach-Object { $_.agents } | Where-Object { $_ })
        $usedSkills = @($config.plugins.Values | ForEach-Object { $_.skills } | Where-Object { $_ })
        foreach ($a in $availableAgents) {
            if ($usedAgents -notcontains $a) { Add-Warn "agent '$a' is not included in any plugin" }
        }
        foreach ($s in $availableSkills) {
            if ($usedSkills -notcontains $s) { Add-Warn "skill '$s' is not included in any plugin" }
        }
    }
}

# --- 4. Per-plugin version coherence with primary skill ---
if ($config -and $config.plugins) {
    foreach ($pName in $config.plugins.Keys) {
        $p = $config.plugins[$pName]
        if (-not $p.version) { continue }
        # When a plugin includes a same-named skill as its primary, its
        # version must match that skill's SKILL.md top-level version.
        if ($p.skills -and ($p.skills -contains $pName)) {
            $skillVer = $skillVersions[$pName]
            if ($skillVer -and ($skillVer -ne $p.version)) {
                Add-Err "[plugin:$pName] plugins.yml version '$($p.version)' != src/skills/$pName/SKILL.md version '$skillVer'"
            }
        }
    }
}

# --- 5. Drift check between src/ and plugins/ ---
function Get-FolderHash {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $files = Get-ChildItem $Path -Recurse -File | Sort-Object FullName
    $sb = [System.Text.StringBuilder]::new()
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($Path.Length).Replace('\','/')
        $h = (Get-FileHash -Algorithm SHA256 -Path $f.FullName).Hash
        $null = $sb.AppendLine("${rel}:$h")
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','')
}

if ($config -and $config.plugins -and (Test-Path $pluginsRoot)) {
    foreach ($pName in $config.plugins.Keys) {
        $p = $config.plugins[$pName]
        $pluginDir = Join-Path $pluginsRoot $pName

        if (-not (Test-Path $pluginDir)) {
            Add-Err "[drift:$pName] plugins/$pName/ does not exist (run scripts/build-plugins.ps1)"
            continue
        }

        if ($p.skills) {
            foreach ($skill in $p.skills) {
                $srcPath = Join-Path $srcSkills $skill
                $dstPath = Join-Path $pluginDir "skills/$skill"
                $srcHash = Get-FolderHash $srcPath
                $dstHash = Get-FolderHash $dstPath
                if ($srcHash -ne $dstHash) {
                    Add-Err "[drift:$pName] skill '$skill' differs from src/ (run scripts/build-plugins.ps1)"
                }
            }
        }
        if ($p.agents) {
            foreach ($agent in $p.agents) {
                $srcFile = Join-Path $srcAgents "$agent.agent.md"
                $dstFile = Join-Path $pluginDir "agents/$agent.agent.md"
                if (-not (Test-Path $dstFile)) {
                    Add-Err "[drift:$pName] agent '$agent.agent.md' missing in plugin (run scripts/build-plugins.ps1)"
                    continue
                }
                $sH = (Get-FileHash $srcFile).Hash
                $dH = (Get-FileHash $dstFile).Hash
                if ($sH -ne $dH) {
                    Add-Err "[drift:$pName] agent '$agent' differs from src/ (run scripts/build-plugins.ps1)"
                }
            }
        }
    }
}

# --- 6. marketplace.json check ---
if (-not (Test-Path $marketJson)) {
    Add-Err "marketplace.json not found at .github/plugin/marketplace.json (run scripts/build-plugins.ps1)"
} elseif ($config -and $config.plugins) {
    $market = Get-Content $marketJson -Raw | ConvertFrom-Json
    $listed = @($market.plugins | ForEach-Object { $_.name })
    foreach ($pName in $config.plugins.Keys) {
        if ($listed -notcontains $pName) {
            Add-Err "[marketplace.json] plugin '$pName' not listed (run scripts/build-plugins.ps1)"
            continue
        }
        $entry = $market.plugins | Where-Object { $_.name -eq $pName }
        $expectedSource = "plugins/$pName"
        if ($entry.source -ne $expectedSource) {
            Add-Err "[marketplace.json:$pName] source '$($entry.source)' != expected '$expectedSource'"
        }
        $expectedVersion = $config.plugins[$pName].version
        if ($entry.version -ne $expectedVersion) {
            Add-Err "[marketplace.json:$pName] version '$($entry.version)' != plugins.yml '$expectedVersion'"
        }
    }
}

# --- Report ---
if ($warnings.Count -gt 0) {
    Write-Host ''
    Write-Host 'Warnings:' -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  $w" -ForegroundColor Yellow }
}

if ($errors.Count -gt 0) {
    Write-Host ''
    Write-Host 'Errors:' -ForegroundColor Red
    foreach ($e in $errors) { Write-Host "  $e" -ForegroundColor Red }
    Write-Host ''
    Write-Host "Lint failed: $($errors.Count) error(s), $($warnings.Count) warning(s)" -ForegroundColor Red
    exit 1
} else {
    Write-Host ''
    Write-Host "Lint clean ($($warnings.Count) warning(s))" -ForegroundColor Green
}
