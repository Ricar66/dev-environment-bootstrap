#requires -Version 5.1

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$manifest = Join-Path $root ".super-dev-kit\manifest.json"

if (-not (Test-Path $manifest)) {
    Write-Host "Manifesto ainda não existe: $manifest" -ForegroundColor Yellow
    exit 1
}

$state = Get-Content $manifest -Raw | ConvertFrom-Json

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        SUPER DEV KIT - ESTADO LOCAL" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Plataforma: $($state.platform)"
Write-Host "Host:       $($state.host)"
Write-Host "Criado:     $($state.created_at)"
Write-Host "Atualizado: $($state.updated_at)"
Write-Host "Perfis:     $(@($state.profiles) -join ', ')"
Write-Host ""

Write-Host "Pacotes instalados pelo kit:"
$ownedPackages = @($state.packages | Where-Object { $_.installed_by_devkit -eq $true })
if ($ownedPackages.Count -eq 0) {
    Write-Host "  (nenhum)"
}
else {
    foreach ($item in $ownedPackages) {
        Write-Host "  - $($item.id) [$($item.manager)] present=$($item.present)"
    }
}

Write-Host ""
Write-Host "Extensões VS Code instaladas pelo kit:"
$ownedExtensions = @($state.vscode_extensions | Where-Object { $_.installed_by_devkit -eq $true })
if ($ownedExtensions.Count -eq 0) {
    Write-Host "  (nenhuma)"
}
else {
    foreach ($item in $ownedExtensions) {
        Write-Host "  - $($item.id) present=$($item.present)"
    }
}

Write-Host ""
Write-Host "Recursos controlados:"
foreach ($item in @($state.features)) {
    Write-Host "  - $($item.name): present=$($item.present), by_devkit=$($item.enabled_by_devkit)"
}

Write-Host ""
Write-Host "Arquivo:"
Write-Host "  $manifest"
