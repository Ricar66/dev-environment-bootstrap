#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Stack,

    [switch]$DryRun,
    [switch]$SkipExtensions
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$catalogPath = Join-Path $root "modules\catalog.json"
$stackPath = Join-Path $root "stacks\$Stack.json"
$installer = Join-Path $root "windows\setup-windows.ps1"
$extensionsInstaller = Join-Path $root "tools\install-vscode-extensions.ps1"
$stateHelper = Join-Path $root "tools\state.ps1"

if (Test-Path $stateHelper) {
    . $stateHelper
}

if (-not (Test-Path $catalogPath)) {
    throw "Catálogo de módulos não encontrado: $catalogPath"
}

if (-not (Test-Path $stackPath)) {
    Write-Host "Stack não encontrada: $Stack" -ForegroundColor Red
    Write-Host "Presets disponíveis:"
    Get-ChildItem (Join-Path $root "stacks") -Filter "*.json" |
        ForEach-Object { Write-Host "  - $($_.BaseName)" }
    exit 1
}

$catalog = Get-Content $catalogPath -Raw | ConvertFrom-Json
$stackConfig = Get-Content $stackPath -Raw | ConvertFrom-Json

$resolved = New-Object System.Collections.Generic.List[string]

function Resolve-Module {
    param([Parameter(Mandatory)][string]$Name)

    if ($resolved.Contains($Name)) {
        return
    }

    $module = $catalog.modules.PSObject.Properties[$Name].Value

    if (-not $module) {
        throw "Módulo '$Name' não existe no catálogo."
    }

    foreach ($dependency in @($module.depends_on)) {
        if ($dependency) {
            Resolve-Module -Name ([string]$dependency)
        }
    }

    if (-not $resolved.Contains($Name)) {
        $resolved.Add($Name)
    }
}

foreach ($moduleName in @($stackConfig.modules)) {
    Resolve-Module -Name ([string]$moduleName)
}

$packages = New-Object System.Collections.Generic.List[string]
$extensions = New-Object System.Collections.Generic.List[string]

foreach ($moduleName in $resolved) {
    $module = $catalog.modules.PSObject.Properties[$moduleName].Value

    foreach ($package in @($module.windows_packages)) {
        if ($package -and -not $packages.Contains([string]$package)) {
            $packages.Add([string]$package)
        }
    }

    foreach ($extension in @($module.vscode_extensions)) {
        if ($extension -and -not $extensions.Contains([string]$extension)) {
            $extensions.Add([string]$extension)
        }
    }
}

$profileMap = @{
    essential = "Essential"
    frontend  = "Frontend"
    backend   = "Backend"
    fullstack = "FullStack"
    datasql   = "DataSQL"
    devops    = "DevOps"
}

$profileKey = ([string]$stackConfig.base_profile).ToLower()

if (-not $profileMap.ContainsKey($profileKey)) {
    throw "Perfil base inválido no preset: $($stackConfig.base_profile)"
}

$profile = $profileMap[$profileKey]

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "       SUPER DEV KIT - STACK: $($stackConfig.name)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host $stackConfig.description
Write-Host ""
Write-Host "Perfil base: $profile"
Write-Host "Módulos:"
foreach ($item in $resolved) { Write-Host "  - $item" }

Write-Host ""
Write-Host "Pacotes extras Windows:"
if ($packages.Count -eq 0) { Write-Host "  (nenhum)" } else { foreach ($item in $packages) { Write-Host "  - $item" } }

Write-Host ""
Write-Host "Extensões VS Code:"
if ($extensions.Count -eq 0) { Write-Host "  (nenhuma)" } else { foreach ($item in $extensions) { Write-Host "  - $item" } }

Write-Host ""

$params = @{
    Profile = $profile
}

if ($packages.Count -gt 0) {
    $params.CustomPackages = @($packages)
}

if ($DryRun) {
    $params.DryRun = $true
}

& $installer @params

if (-not $SkipExtensions -and $extensions.Count -gt 0) {
    $extParams = @{
        Profile        = "Essential"
        ExtraExtension = @($extensions)
    }

    if ($DryRun) {
        $extParams.DryRun = $true
    }

    & $extensionsInstaller @extParams
}

Write-Host ""
if ($DryRun) {
    Write-Host "[OK] Plano da stack validado em dry-run." -ForegroundColor Green
}
else {
    if (Get-Command Add-DevKitStack -ErrorAction SilentlyContinue) {
        Add-DevKitStack -Stack ([string]$stackConfig.slug)

        foreach ($moduleName in $resolved) {
            Add-DevKitModule -Module ([string]$moduleName)
        }

        Write-DevKitEvent -Event "stack_installed" -Data @{
            stack   = [string]$stackConfig.slug
            modules = @($resolved)
        }
    }

    Write-Host "[OK] Stack $($stackConfig.name) processada." -ForegroundColor Green
}
