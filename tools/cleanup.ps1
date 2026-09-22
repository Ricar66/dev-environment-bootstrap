#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$IncludeCore,
    [switch]$IncludeDocker,
    [switch]$ExtensionsOnly,
    [switch]$PackagesOnly
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$manifestPath = Join-Path $root ".super-dev-kit\manifest.json"
$stateHelper = Join-Path $root "tools\state.ps1"

if (Test-Path $stateHelper) {
    . $stateHelper
}

if (-not (Test-Path $manifestPath)) {
    Write-Host "Manifesto não encontrado: $manifestPath" -ForegroundColor Yellow
    Write-Host "Execute uma instalação v0.4+ primeiro para registrar o estado da máquina."
    exit 1
}

$state = Get-Content $manifestPath -Raw | ConvertFrom-Json

$corePackages = @(
    "Git.Git",
    "Microsoft.VisualStudioCode",
    "Microsoft.PowerShell",
    "Microsoft.WindowsTerminal",
    "GitHub.cli",
    "7zip.7zip"
)

$dockerPackages = @("Docker.DockerDesktop")

$ownedPackages = @(
    $state.packages |
        Where-Object {
            $_.manager -eq "winget" -and
            $_.installed_by_devkit -eq $true -and
            $_.present -eq $true
        }
)

if (-not $IncludeCore) {
    $ownedPackages = @($ownedPackages | Where-Object { $corePackages -notcontains $_.id })
}

if (-not $IncludeDocker) {
    $ownedPackages = @($ownedPackages | Where-Object { $dockerPackages -notcontains $_.id })
}

$ownedExtensions = @(
    $state.vscode_extensions |
        Where-Object {
            $_.installed_by_devkit -eq $true -and
            $_.present -eq $true
        }
)

if ($ExtensionsOnly) {
    $ownedPackages = @()
}

if ($PackagesOnly) {
    $ownedExtensions = @()
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "       SUPER DEV KIT - MANIFEST CLEANUP" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pacotes registrados como instalados pelo kit:"
if ($ownedPackages.Count -eq 0) {
    Write-Host "  (nenhum selecionado)"
}
else {
    foreach ($package in $ownedPackages) {
        Write-Host "  - $($package.id)"
    }
}

Write-Host ""
Write-Host "Extensões VS Code registradas como instaladas pelo kit:"
if ($ownedExtensions.Count -eq 0) {
    Write-Host "  (nenhuma)"
}
else {
    foreach ($extension in $ownedExtensions) {
        Write-Host "  - $($extension.id)"
    }
}

Write-Host ""
Write-Host "Proteções ativas:" -ForegroundColor Yellow
if (-not $IncludeCore) {
    Write-Host "  - ferramentas core preservadas"
}
if (-not $IncludeDocker) {
    Write-Host "  - Docker Desktop preservado"
}
Write-Host "  - itens que já existiam antes do kit não são removidos"
Write-Host "  - WSL, certificados e dados/volumes Docker não são removidos"

if (-not $Apply) {
    Write-Host ""
    Write-Host "[PREVIEW] Nenhuma alteração foi feita." -ForegroundColor Green
    Write-Host ""
    Write-Host "Para aplicar:"
    Write-Host "  .\tools\cleanup.ps1 -Apply"
    Write-Host ""
    Write-Host "Para incluir core:"
    Write-Host "  .\tools\cleanup.ps1 -IncludeCore -Apply"
    Write-Host ""
    Write-Host "Para incluir Docker:"
    Write-Host "  .\tools\cleanup.ps1 -IncludeDocker -Apply"
    exit 0
}

if ($ownedPackages.Count -gt 0) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "Abra o CMD/PowerShell como Administrador para remover pacotes." -ForegroundColor Red
        exit 1
    }
}

$confirm = Read-Host "Digite REMOVER para confirmar"

if ($confirm -ne "REMOVER") {
    Write-Host "Operação cancelada."
    exit 0
}

foreach ($extension in $ownedExtensions) {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Warning "VS Code CLI não encontrado; extensão $($extension.id) não foi removida."
        continue
    }

    Write-Host "[REMOVENDO EXTENSÃO] $($extension.id)" -ForegroundColor Cyan
    code --uninstall-extension $extension.id

    $stillPresent = @(code --list-extensions 2>$null) -contains $extension.id

    if (Get-Command Register-DevKitExtension -ErrorAction SilentlyContinue) {
        Register-DevKitExtension -Id $extension.id -Preexisting $false -PresentAfter $stillPresent
    }
}

foreach ($package in $ownedPackages) {
    Write-Host "[REMOVENDO PACOTE] $($package.id)" -ForegroundColor Cyan

    winget uninstall --id $package.id -e --accept-source-agreements --silent
    $exitCode = $LASTEXITCODE

    $presentAfter = $false
    $result = winget list --id $package.id -e --accept-source-agreements 2>$null | Out-String

    if ($result -match [regex]::Escape($package.id)) {
        $presentAfter = $true
    }

    if (Get-Command Register-DevKitPackage -ErrorAction SilentlyContinue) {
        Register-DevKitPackage -Id $package.id -Name $package.name -Manager "winget" -Preexisting $false -PresentAfter $presentAfter
    }

    if ($exitCode -ne 0 -and $presentAfter) {
        Write-Warning "Não foi possível remover $($package.id)."
    }
}

if (Get-Command Write-DevKitEvent -ErrorAction SilentlyContinue) {
    Write-DevKitEvent -Event "cleanup_completed" -Data @{
        packages   = $ownedPackages.Count
        extensions = $ownedExtensions.Count
    }
}

Write-Host ""
Write-Host "[OK] Cleanup concluído." -ForegroundColor Green
Write-Host "O manifesto foi atualizado com o estado atual."
