#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$LockPath = ".\.super-dev-kit\devkit.lock.json"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$manifestPath = Join-Path $root ".super-dev-kit\manifest.json"
$runtimeChecker = Join-Path $root "tools\check-runtime-versions.ps1"

if (-not [System.IO.Path]::IsPathRooted($LockPath)) {
    $LockPath = Join-Path $root $LockPath
}

if (-not (Test-Path $LockPath)) {
    Write-Host "Lock file não encontrado: $LockPath" -ForegroundColor Red
    exit 1
}

$lock = Get-Content $LockPath -Raw | ConvertFrom-Json

if ($lock.schema_version -ne 1) {
    throw "Schema de lock não suportado: $($lock.schema_version)"
}

$state = $null
if (Test-Path $manifestPath) {
    $state = Get-Content $manifestPath -Raw | ConvertFrom-Json
}

$drift = New-Object System.Collections.Generic.List[string]

function Add-Drift {
    param([Parameter(Mandatory)][string]$Message)
    if (-not $drift.Contains($Message)) {
        $drift.Add($Message)
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "      SUPER DEV KIT - ENVIRONMENT DIFF" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Lock: $LockPath"
Write-Host ""

if ($state) {
    foreach ($stack in @($lock.stacks)) {
        if (@($state.stacks) -notcontains [string]$stack) {
            Add-Drift "Stack ausente no manifesto: $stack"
        }
    }

    foreach ($module in @($lock.modules)) {
        if (@($state.modules) -notcontains [string]$module) {
            Add-Drift "Módulo ausente no manifesto: $module"
        }
    }
}
elseif (@($lock.stacks).Count -gt 0 -or @($lock.modules).Count -gt 0) {
    Add-Drift "Manifesto local ausente; stacks/módulos não puderam ser confirmados."
}

foreach ($extension in @($lock.vscode_extensions)) {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Add-Drift "VS Code CLI ausente; extensão não verificável: $extension"
        continue
    }

    $installed = @(code --list-extensions 2>$null)

    if ($installed -notcontains [string]$extension) {
        Add-Drift "Extensão VS Code ausente: $extension"
    }
}

if ($lock.source_platform -eq "windows") {
    foreach ($package in @($lock.packages.windows)) {
        $result = winget list --id $package -e --accept-source-agreements 2>$null | Out-String
        if ($result -notmatch [regex]::Escape([string]$package)) {
            Add-Drift "Pacote winget ausente: $package"
        }
    }
}
elseif (@($lock.packages.windows).Count -gt 0) {
    Write-Host "[INFO] Pacotes Windows do lock não são comparados nesta plataforma."
}

Write-Host "Versões de runtime:" -ForegroundColor Cyan

$checkerArgs = @(
    "-NoLogo",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $runtimeChecker,
    "-LockPath", $LockPath
)

& powershell.exe @checkerArgs
$runtimeExit = $LASTEXITCODE

if ($runtimeExit -ne 0) {
    Add-Drift "Uma ou mais versões de runtime não atendem o lock."
}

Write-Host ""
Write-Host "Diferenças estruturais:" -ForegroundColor Cyan

if ($drift.Count -eq 0) {
    Write-Host "[OK] Nenhuma diferença relevante encontrada." -ForegroundColor Green
    exit 0
}

foreach ($item in $drift) {
    Write-Host "[DRIFT] $item" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "$($drift.Count) diferença(s) encontrada(s)." -ForegroundColor Yellow
exit 2
