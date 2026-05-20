<#
.SYNOPSIS
    Scan source paths for potential secrets and sensitive identifiers before
    promotion into the public repository.

.DESCRIPTION
    Runs two checks:
      1. gitleaks detect --no-git (default + repo config)
      2. Lightweight regex checks for common sensitive identifiers that may
         still be risky to publish (emails, tenant domains, credential-in-URL,
         public IPs).

    Exit codes:
      0 = no findings
      1 = findings detected

.PARAMETER Path
    One or more files or directories to scan.

.PARAMETER RepoRoot
    Repository root; used to resolve default config path.

.PARAMETER ConfigPath
    gitleaks config path. Defaults to scripts/gitleaks-promote.toml.

.PARAMETER SkipGitleaks
    Skip the gitleaks pass (regex-only).

.PARAMETER SkipRegex
    Skip the regex pass (gitleaks-only).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string[]]$Path,
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path,
    [string]$ConfigPath,
    [switch]$SkipGitleaks,
    [switch]$SkipRegex
)

$ErrorActionPreference = 'Stop'

if ($SkipGitleaks -and $SkipRegex) {
    throw "At least one scan pass must run. Remove -SkipGitleaks or -SkipRegex."
}

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $RepoRoot 'scripts/gitleaks-promote.toml'
}
if (-not (Test-Path $ConfigPath)) {
    throw "gitleaks config not found: $ConfigPath"
}

$scanItems = [System.Collections.Generic.List[pscustomobject]]::new()
foreach ($p in $Path) {
    if (-not (Test-Path $p)) {
        throw "Path does not exist: $p"
    }
    $resolved = (Resolve-Path $p).Path
    $item = Get-Item $resolved
    $scanItems.Add([pscustomobject]@{
        Original = $p
        Resolved = $resolved
        IsFile   = -not $item.PSIsContainer
    }) | Out-Null
}

$anyFindings = $false

function Invoke-GitleaksNoGit {
    param(
        [Parameter(Mandatory)] [string]$ScanPath,
        [Parameter(Mandatory)] [string]$Config
    )

    & gitleaks detect --no-git --source $ScanPath --redact --verbose --config $Config
    return $LASTEXITCODE
}

function Get-IsPublicIpv4 {
    param([string]$Ip)

    try {
        $addr = [System.Net.IPAddress]::Parse($Ip)
    } catch {
        return $false
    }

    $bytes = $addr.GetAddressBytes()
    if ($bytes.Length -ne 4) { return $false }

    $b0 = $bytes[0]
    $b1 = $bytes[1]

    # Private, loopback, link-local, multicast, and documentation ranges.
    if ($b0 -eq 10) { return $false }
    if ($b0 -eq 127) { return $false }
    if ($b0 -eq 0) { return $false }
    if ($b0 -eq 169 -and $b1 -eq 254) { return $false }
    if ($b0 -eq 172 -and $b1 -ge 16 -and $b1 -le 31) { return $false }
    if ($b0 -eq 192 -and $b1 -eq 168) { return $false }
    if ($b0 -ge 224) { return $false }

    # TEST-NET ranges.
    if ($b0 -eq 192 -and $b1 -eq 0 -and $bytes[2] -eq 2) { return $false }
    if ($b0 -eq 198 -and $b1 -eq 51 -and $bytes[2] -eq 100) { return $false }
    if ($b0 -eq 203 -and $b1 -eq 0 -and $bytes[2] -eq 113) { return $false }

    return $true
}

$regexPatterns = @(
    [pscustomobject]@{
        Id      = 'email-address'
        Pattern = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
        Accept  = { param($m) $m -notmatch '(?i)@(example\.com|users\.noreply\.github\.com)$' }
    },
    [pscustomobject]@{
        Id      = 'tenant-domain'
        Pattern = '(?i)\b[a-z0-9][a-z0-9-]{1,62}\.onmicrosoft\.com\b'
        Accept  = { param($m) $true }
    },
    [pscustomobject]@{
        Id      = 'credential-in-url'
        Pattern = '(?i)https?://[^\s/@:]+:[^\s/@]+@'
        Accept  = { param($m) $true }
    },
    [pscustomobject]@{
        Id      = 'public-ipv4'
        Pattern = '\b(?:\d{1,3}\.){3}\d{1,3}\b'
        Accept  = { param($m) Get-IsPublicIpv4 -Ip $m }
    }
)

$includeExtensions = @('.md', '.markdown', '.txt', '.yml', '.yaml', '.json', '.ps1', '.sh', '.cs', '.csx', '.ts', '.js', '.xaml')

if (-not $SkipGitleaks) {
    if (-not (Get-Command gitleaks -ErrorAction SilentlyContinue)) {
        throw "gitleaks is not installed or not on PATH. Install gitleaks first, then re-run."
    }

    Write-Host ''
    Write-Host 'Running gitleaks scan...' -ForegroundColor Cyan

    foreach ($item in $scanItems) {
        if ($item.IsFile) {
            $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("promote-scan-" + [System.Guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
            try {
                $tmpFile = Join-Path $tmpDir ([System.IO.Path]::GetFileName($item.Resolved))
                Copy-Item -Path $item.Resolved -Destination $tmpFile -Force
                Write-Host "  gitleaks: $($item.Original)" -ForegroundColor DarkGray
                $code = Invoke-GitleaksNoGit -ScanPath $tmpDir -Config $ConfigPath
            }
            finally {
                if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
            }
        }
        else {
            Write-Host "  gitleaks: $($item.Original)" -ForegroundColor DarkGray
            $code = Invoke-GitleaksNoGit -ScanPath $item.Resolved -Config $ConfigPath
        }

        if ($code -ne 0) {
            $anyFindings = $true
        }
    }
}

if (-not $SkipRegex) {
    Write-Host ''
    Write-Host 'Running regex sensitivity scan...' -ForegroundColor Cyan

    $regexFindings = [System.Collections.Generic.List[string]]::new()

    foreach ($item in $scanItems) {
        $files = @()
        if ($item.IsFile) {
            $files = @(Get-Item $item.Resolved)
        }
        else {
            $files = @(Get-ChildItem $item.Resolved -Recurse -File -ErrorAction SilentlyContinue)
        }

        foreach ($f in $files) {
            if ($includeExtensions -notcontains $f.Extension.ToLowerInvariant()) { continue }
            [string[]]$lines = @(Get-Content -Path $f.FullName -ErrorAction SilentlyContinue)
            if (-not $lines) { continue }
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                foreach ($rule in $regexPatterns) {
                    $matches = [regex]::Matches($line, $rule.Pattern)
                    foreach ($m in $matches) {
                        $token = $m.Value
                        $accept = & $rule.Accept $token
                        if (-not $accept) { continue }
                        $rel = $f.FullName
                        if ($rel.StartsWith($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                            $rel = $rel.Substring($RepoRoot.Length).TrimStart('\','/').Replace('\','/')
                        }
                        $finding = "[{0}] {1}:{2} -> {3}" -f $rule.Id, $rel, ($i + 1), $token
                        $regexFindings.Add($finding) | Out-Null
                    }
                }
            }
        }
    }

    if ($regexFindings.Count -gt 0) {
        $anyFindings = $true
        Write-Host ''
        Write-Host 'Regex findings:' -ForegroundColor Red
        foreach ($rf in $regexFindings) {
            Write-Host "  $rf" -ForegroundColor Red
        }
    }
}

Write-Host ''
if ($anyFindings) {
    Write-Host 'Leak/sensitivity scan failed. Review and sanitize before promotion.' -ForegroundColor Red
    exit 1
}

Write-Host 'Leak/sensitivity scan clean.' -ForegroundColor Green
