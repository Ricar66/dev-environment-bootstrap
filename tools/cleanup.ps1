#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Frontend", "Backend", "FullStack", "DataSQL", "DevOps")]
    [string]$Profile,

    [switch]$IncludeDocker,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

$packages = @()

switch ($Profile) {
    "Frontend" {
        $packages += @("OpenJS.NodeJS.LTS", "Postman.Postman")
    }
    "Backend" {
        $packages += @("OpenJS.NodeJS.LTS", "Python.Python.3.13", "Postman.Postman")
    }
    "FullStack" {
        $packages += @("OpenJS.NodeJS.LTS", "Python.Python.3.13", "Postman.Postman")
    }
    "DataSQL" {
        $packages += @("Python.Python.3.13", "DBeaver.DBeaver.Community")
    }
    "DevOps" {
    }
}

if ($IncludeDocker) {
    $packages += "Docker.DockerDesktop"
}

$packages = $packages | Sort-Object -Unique

Write-Host "Perfil: $Profile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pacotes candidatos à remoção:"

if ($packages.Count -eq 0) {
    Write-Host "  (nenhum; use -IncludeDocker se desejar incluir Docker)"
}
else {
    foreach ($package in $packages) {
        Write-Host "  - $package"
    }
}

Write-Host ""
Write-Host "IMPORTANTE:" -ForegroundColor Yellow
Write-Host "O script não sabe se o pacote já existia antes do Super Dev Kit."
Write-Host "Revise a lista antes de usar -Apply."

if (-not $Apply) {
    Write-Host ""
    Write-Host "[DRY-RUN] Nenhuma alteração foi feita." -ForegroundColor Green
    Write-Host "Exemplo para aplicar:"
    Write-Host ".\tools\cleanup.ps1 -Profile $Profile -Apply"
    exit 0
}

$confirm = Read-Host "Digite REMOVER para confirmar"

if ($confirm -ne "REMOVER") {
    Write-Host "Operação cancelada."
    exit 0
}

foreach ($package in $packages) {
    Write-Host "[REMOVENDO] $package" -ForegroundColor Cyan

    winget uninstall --id $package -e --accept-source-agreements --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Não foi possível remover $package ou ele não estava instalado."
    }
}

Write-Host "[OK] Cleanup concluído." -ForegroundColor Green
