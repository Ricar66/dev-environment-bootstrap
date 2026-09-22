#requires -Version 5.1

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$installer = Join-Path $root "windows\setup-windows.ps1"
$doctor = Join-Path $root "diagnostics\dev-doctor.ps1"
$certExporter = Join-Path $root "certificates\export-root-ca.ps1"
$extensions = Join-Path $root "tools\install-vscode-extensions.ps1"
$configRunner = Join-Path $root "tools\run-config.ps1"
$updater = Join-Path $root "tools\update-devkit.ps1"
$inventory = Join-Path $root "tools\inventory.ps1"
$cleanup = Join-Path $root "tools\cleanup.ps1"
$configExample = Join-Path $root "config\devkit.config.example.json"
$configLocal = Join-Path $root "config\devkit.config.json"
$versionFile = Join-Path $root "VERSION"
$version = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { "dev" }

function Read-Profile {
    Write-Host ""
    Write-Host "1. Essential"
    Write-Host "2. Frontend"
    Write-Host "3. Backend"
    Write-Host "4. Full Stack"
    Write-Host "5. Data / SQL"
    Write-Host "6. DevOps"
    Write-Host ""

    $profileChoice = Read-Host "Escolha o perfil"

    switch ($profileChoice) {
        "1" { return "Essential" }
        "2" { return "Frontend" }
        "3" { return "Backend" }
        "4" { return "FullStack" }
        "5" { return "DataSQL" }
        "6" { return "DevOps" }
        default { return $null }
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "              SUPER DEV KIT v$version" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1.  Instalar por perfil"
    Write-Host "2.  Instalar tudo"
    Write-Host "3.  Dry-run de um perfil"
    Write-Host "4.  Extensões VS Code por perfil"
    Write-Host "5.  Executar configuração JSON"
    Write-Host "6.  Dry-run da configuração JSON"
    Write-Host "7.  Dev Doctor"
    Write-Host "8.  Exportar inventário do ambiente"
    Write-Host "9.  Atualizar Super Dev Kit"
    Write-Host "10. Preview de cleanup/uninstall"
    Write-Host "11. Exportar certificado CA confiável"
    Write-Host "12. Criar configuração local a partir do exemplo"
    Write-Host "0.  Sair"
    Write-Host ""
}

if (-not (Test-Path $installer)) {
    throw "Instalador não encontrado: $installer"
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Escolha uma opção"

    switch ($choice) {
        "1" {
            $profile = Read-Profile
            if ($profile) { & $installer -Profile $profile }
            else { Write-Host "Perfil inválido." -ForegroundColor Yellow; Start-Sleep 1 }
        }
        "2" {
            & $installer -All
        }
        "3" {
            $profile = Read-Profile
            if ($profile) { & $installer -Profile $profile -DryRun }
            else { Write-Host "Perfil inválido." -ForegroundColor Yellow; Start-Sleep 1 }
            Read-Host "Pressione Enter para voltar"
        }
        "4" {
            $profile = Read-Profile
            if ($profile) { & $extensions -Profile $profile }
            else { Write-Host "Perfil inválido." -ForegroundColor Yellow }
            Read-Host "Pressione Enter para voltar"
        }
        "5" {
            if (-not (Test-Path $configLocal)) {
                Write-Host "Configuração local não encontrada." -ForegroundColor Yellow
                Write-Host "Use a opção 12 primeiro ou copie:"
                Write-Host "  config\devkit.config.example.json -> config\devkit.config.json"
            }
            else {
                & $configRunner -ConfigPath $configLocal
            }
            Read-Host "Pressione Enter para voltar"
        }
        "6" {
            if (-not (Test-Path $configLocal)) {
                Write-Host "Configuração local não encontrada." -ForegroundColor Yellow
            }
            else {
                & $configRunner -ConfigPath $configLocal -DryRun
            }
            Read-Host "Pressione Enter para voltar"
        }
        "7" {
            & $doctor
            Read-Host "Pressione Enter para voltar"
        }
        "8" {
            & $inventory
            Read-Host "Pressione Enter para voltar"
        }
        "9" {
            & $updater
            Read-Host "Pressione Enter para voltar"
        }
        "10" {
            $profile = Read-Profile
            if ($profile -and $profile -ne "Essential") {
                & $cleanup -Profile $profile
            }
            else {
                Write-Host "Cleanup não é executado para o perfil Essential." -ForegroundColor Yellow
            }
            Read-Host "Pressione Enter para voltar"
        }
        "11" {
            $search = Read-Host "Texto para procurar no certificado (ex.: senac.check, Zscaler, Fortinet)"
            & $certExporter -Search $search
            Read-Host "Pressione Enter para voltar"
        }
        "12" {
            if (Test-Path $configLocal) {
                Write-Host "config\devkit.config.json já existe." -ForegroundColor Yellow
            }
            else {
                Copy-Item $configExample $configLocal
                Write-Host "[OK] Configuração criada:" -ForegroundColor Green
                Write-Host "     $configLocal"
            }
            Read-Host "Pressione Enter para voltar"
        }
        "0" {
            return
        }
        default {
            Write-Host "Opção inválida." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}
