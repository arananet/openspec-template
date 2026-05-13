#requires -Version 5.1
<#
.SYNOPSIS
    OpenSpec — local spec-driven development helper (PowerShell port).

.DESCRIPTION
    Functional parity with scripts/openspec for Windows-native developers.
    Subcommands: scaffold, check, init.

    Zero external dependencies: PowerShell 5.1+ and git only. No yq, jq,
    python, or gh CLI required.

.EXAMPLE
    pwsh ./scripts/openspec.ps1 scaffold "user authentication"
    pwsh ./scripts/openspec.ps1 scaffold "fix login crash" -Type bugfix
    pwsh ./scripts/openspec.ps1 check
    pwsh ./scripts/openspec.ps1 check -Strict
    pwsh ./scripts/openspec.ps1 init
#>

[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Position = 0)]
    [ValidateSet('scaffold', 'check', 'init', 'help', '--help', '-h')]
    [string]$Command = 'help',

    [Parameter(Position = 1)]
    [string]$Name,

    [ValidateSet('feature', 'bugfix')]
    [string]$Type = 'feature',

    [switch]$Force,
    [switch]$Strict,
    [int]$Pr
)

$ErrorActionPreference = 'Stop'

# ── Paths ─────────────────────────────────────────────────────────────
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root        = Resolve-Path (Join-Path $ScriptDir '..')
$SpecsDir    = Join-Path $Root '.openspec/specs'
$TemplatesDir = Join-Path $Root '.openspec/templates'
$ConfigFile  = Join-Path $Root '.openspec/config.yaml'

# ── Helpers ───────────────────────────────────────────────────────────
function Write-Err  { param($m) Write-Host "error: $m"   -ForegroundColor Red }
function Write-Warn { param($m) Write-Host "warning: $m" -ForegroundColor Yellow }
function Write-Info { param($m) Write-Host $m }

function Get-Slug {
    param([string]$s)
    ($s.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
}

function Get-TodayIso { (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd') }

function Get-GitUser {
    try { (git config --get user.name 2>$null) } catch { $env:USERNAME }
}

function Get-ConfigValue {
    param([string]$Section, [string]$Key)
    if (-not (Test-Path $ConfigFile)) { return '' }
    $inSection = $false
    foreach ($line in Get-Content $ConfigFile) {
        if ($line -match "^${Section}:") { $inSection = $true; continue }
        if ($inSection -and $line -match '^[a-z_]+:') { $inSection = $false }
        if ($inSection -and $line -match "^\s+${Key}:\s*(.*)$") {
            $v = $Matches[1].Trim().Trim('"').Trim("'")
            if ($v -in @('null', '~', '')) { return '' }
            if ($v -match '^\{\{.+\}\}$') { return '' }
            return $v
        }
    }
    ''
}

# ── Subcommands ───────────────────────────────────────────────────────
function Show-Help {
    @"
OpenSpec (PowerShell) — local spec-driven development helper.

Usage:
  openspec.ps1 scaffold "<name>" [-Type bugfix|feature] [-Force]
  openspec.ps1 check [-Strict] [-Pr <number>]
  openspec.ps1 init

For full docs see docs/OPENSPEC.md
"@ | Write-Host
}

function Invoke-Scaffold {
    if (-not $Name) { Write-Err 'scaffold requires a name'; exit 1 }
    if (-not (Test-Path $TemplatesDir)) { Write-Err "templates dir missing: $TemplatesDir"; exit 1 }
    $template = Join-Path $TemplatesDir "$Type.spec.yaml"
    if (-not (Test-Path $template)) { Write-Err "template not found: $template"; exit 1 }

    $slug = Get-Slug $Name
    if (-not $slug) { Write-Err 'name produced empty slug'; exit 1 }

    $out = Join-Path $SpecsDir "$slug.spec.yaml"
    if ((Test-Path $out) -and -not $Force) {
        Write-Err "spec already exists: $out (use -Force to overwrite)"; exit 1
    }
    New-Item -ItemType Directory -Force -Path $SpecsDir | Out-Null

    $content = Get-Content $template -Raw
    $content = $content `
        -replace '\{\{SLUG\}\}',   $slug `
        -replace '\{\{NAME\}\}',   $Name `
        -replace '\{\{DATE\}\}',   (Get-TodayIso) `
        -replace '\{\{AUTHOR\}\}', (Get-GitUser)

    foreach ($role in 'implementer','reviewer','qa','product_owner') {
        $val = Get-ConfigValue -Section 'roles' -Key "default_$role"
        if ($val) {
            $content = $content -replace "(?m)^(\s*${role}:)\s*null\s*$", "`$1 $val"
        }
    }

    Set-Content -Path $out -Value $content -NoNewline:$false -Encoding UTF8
    Write-Info "Created $out"
    Write-Info "Edit description, acceptance_criteria, and test_plan, then set status to 'review'."
}

function Invoke-Check {
    if (-not (Test-Path $SpecsDir)) {
        Write-Warn "no specs directory: $SpecsDir"; return
    }
    $specs = Get-ChildItem $SpecsDir -Filter '*.spec.yaml' -ErrorAction SilentlyContinue
    if (-not $specs) { Write-Info 'No specs found.'; return }

    $errors = 0
    foreach ($f in $specs) {
        $text = Get-Content $f.FullName -Raw
        $missing = @()
        foreach ($field in 'id:','status:','description:','acceptance_criteria:','test_plan:') {
            if ($text -notmatch [regex]::Escape($field)) { $missing += $field }
        }
        if ($missing) {
            Write-Err "$($f.Name): missing fields: $($missing -join ', ')"
            $errors++; continue
        }
        if ($Strict -and $text -match '(?m)^status:\s*draft\s*$') {
            Write-Err "$($f.Name): status is draft (--strict)"; $errors++
        }
    }
    if ($errors -gt 0) { exit 1 }
    Write-Info "OK ($($specs.Count) spec(s) validated)"
}

function Invoke-Init {
    if (-not (Test-Path $ConfigFile)) {
        Write-Err "$ConfigFile not found"; exit 1
    }
    if ((Get-Content $ConfigFile -Raw) -match '\{\{') {
        Write-Warn 'config.yaml still has {{PLACEHOLDER}} tokens — open in Claude Code or VS Code to onboard.'
        exit 2
    }
    Write-Info 'OpenSpec is configured.'
}

# ── Dispatch ──────────────────────────────────────────────────────────
switch ($Command) {
    'scaffold' { Invoke-Scaffold }
    'check'    { Invoke-Check }
    'init'     { Invoke-Init }
    default    { Show-Help }
}
