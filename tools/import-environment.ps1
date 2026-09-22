#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$LockPath = ".\.super-dev-kit\devkit.lock.json",
    [switch]$DryRun,
    [switch]$SkipExtensions
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$catalogPath = Join-Path $root "modules\catalog.json"
$installer = Join-Path $root "windows\setup-windows.ps1"
$stackInstaller = Join-Path $root "tools\install-stack.ps1"
$extensionsInstaller = Join-Path $root "tools\install-vscode-extensions.ps1"
$runtimeChecker = Join-Path $root "tools\check-runtime-versions.ps1"
$stateHelper = Join-Path $root "tools\state.ps1"

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

if (Test-Path $stateHelper) {
    . $stateHelper
}

$profileMap = @{
    essential = "Essential"
    frontend  = "Frontend"
    backend   = "Backend"
    fullstack = "FullStack"
    datasql   = "DataSQL"
    devops    = "DevOps"
}

$profile = "Essential"
if (@($lock.profiles).Count -gt 0) {
    $candidate = ([string]@($lock.profiles)[0]).ToLower()
    if ($profileMap.ContainsKey($candidate)) {
        $profile = $profileMap[$candidate]
    }
}

$allPackages = New-Object System.Collections.Generic.List[string]
$allExtensions = New-Object System.Collections.Generic.List[string]
$resolvedModules = New-Object System.Collections.Generic.List[string]

if (@($lock.modules).Count -gt 0 -and (Test-Path $catalogPath)) {
    $catalog = Get-Content $catalogPath -Raw | ConvertFrom-Json

    function Resolve-ImportModule {
        param([Parameter(Mandatory)][string]$Name)

        if ($resolvedModules.Contains($Name)) {
            return
        }

        $module = $catalog.modules.PSObject.Properties[$Name].Value

        if (-not $module) {
            Write-Warning "Módulo '$Name' do lock não existe mais no catálogo atual."
            return
        }

        foreach ($dependency in @($module.depends_on)) {
            if ($dependency) {
                Resolve-ImportModule -Name ([string]$dependency)
            }
        }

        if (-not $resolvedModules.Contains($Name)) {
            $resolvedModules.Add($Name)
        }
    }

    foreach ($moduleName in @($lock.modules)) {
        Resolve-ImportModule -Name ([string]$moduleName)
    }

    foreach ($moduleName in $resolvedModules) {
        $module = $catalog.modules.PSObject.Properties[$moduleName].Value

        foreach ($package in @($module.windows_packages)) {
            if ($package -and -not $allPackages.Contains([string]$package)) {
                $allPackages.Add([string]$package)
            }
        }

        foreach ($extension in @($module.vscode_extensions)) {
            if ($extension -and -not $allExtensions.Contains([string]$extension)) {
                $allExtensions.Add([string]$extension)
            }
        }
    }
}

if (@($lock.stacks).Count -eq 0 -and
    $lock.source_platform -eq "windows" -and
    $lock.packages.windows) {
    foreach ($package in @($lock.packages.windows)) {
        if ($package -and -not $allPackages.Contains([string]$package)) {
            $allPackages.Add([string]$package)
        }
    }
}

foreach ($extension in @($lock.vscode_extensions)) {
    if ($extension -and -not $allExtensions.Contains([string]$extension)) {
        $allExtensions.Add([string]$extension)
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "       SUPER DEV KIT - IMPORT ENVIRONMENT" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Lock:             $LockPath"
Write-Host "Origem:           $($lock.source_platform)"
Write-Host "Versão do kit:    $($lock.devkit_version)"
Write-Host "Perfil base:      $profile"
Write-Host "Stacks:           $(@($lock.stacks) -join ', ')"
Write-Host "Módulos:          $(@($lock.modules) -join ', ')"
Write-Host ""

if (@($lock.stacks).Count -gt 0) {
    foreach ($stack in @($lock.stacks)) {
        if (-not (Test-Path (Join-Path $root "stacks\$stack.json"))) {
            Write-Warning "Stack '$stack' não existe no catálogo atual; usando módulos/pacotes como fallback."
            continue
        }

        if ($DryRun) {
            & $stackInstaller -Stack ([string]$stack) -DryRun
        }
        else {
            & $stackInstaller -Stack ([string]$stack)
        }
    }
}
else {
    $params = @{ Profile = $profile }

    if ($allPackages.Count -gt 0) {
        $params.CustomPackages = @($allPackages)
    }

    if ($DryRun) {
        $params.DryRun = $true
    }

    & $installer @params
}

if (-not $SkipExtensions -and $allExtensions.Count -gt 0) {
    $extensionParams = @{
        Profile        = "Essential"
        ExtraExtension = @($allExtensions)
    }

    if ($DryRun) {
        $extensionParams.DryRun = $true
    }

    & $extensionsInstaller @extensionParams
}

if (-not $DryRun -and (Get-Command Add-DevKitModule -ErrorAction SilentlyContinue)) {
    foreach ($moduleName in @($lock.modules)) {
        Add-DevKitModule -Module ([string]$moduleName)
    }

    Write-DevKitEvent -Event "environment_imported" -Data @{
        source_platform = [string]$lock.source_platform
        lock_version    = [string]$lock.devkit_version
    }
}

if ($DryRun) {
    Write-Host ""
    Write-Host "[OK] Import validado em dry-run. Nenhuma alteração foi feita." -ForegroundColor Green
    Write-Host "As restrições de runtime serão verificadas após a instalação real."
    exit 0
}

Write-Host ""
Write-Host "Validando versões de runtime..." -ForegroundColor Cyan

& $runtimeChecker -LockPath $LockPath -UpdateManifest -NoFail

Write-Host ""
Write-Host "[OK] Importação concluída." -ForegroundColor Green
Write-Host "Use tools\compare-environment.cmd para confirmar se o ambiente atende integralmente o lock."
