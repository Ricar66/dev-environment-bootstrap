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
$showState = Join-Path $root "tools\show-state.ps1"
$backupVsCode = Join-Path $root "tools\backup-vscode.ps1"
$restoreVsCode = Join-Path $root "tools\restore-vscode.ps1"
$backupGit = Join-Path $root "tools\backup-git.ps1"
$restoreGit = Join-Path $root "tools\restore-git.ps1"
$stackWizard = Join-Path $root "tools\stack-wizard.ps1"
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
        "8" { return "DevOps" }
        default { return $null }
    }
}

function Pause-Menu {
    Read-Host "Pressione Enter para voltar" | Out-Null
}

function Show-Menu {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "                 SUPER DEV KIT v$version" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1.  Stack Wizard"
    Write-Host "2.  Dry-run do Stack Wizard"
    Write-Host "3.  Instalar por perfil"
    Write-Host "4.  Instalar tudo"
    Write-Host "5.  Dry-run de um perfil"
    Write-Host "6.  Extensões VS Code por perfil"
    Write-Host "7.  Executar configuração JSON"
    Write-Host "8.  Dry-run da configuração JSON"
    Write-Host "9.  Dev Doctor"
    Write-Host "10. Ver manifesto/estado local"
    Write-Host "11. Exportar inventário do ambiente"
    Write-Host "12. Atualizar Super Dev Kit"
    Write-Host "13. Preview de cleanup baseado no manifesto"
    Write-Host "14. Backup do VS Code"
    Write-Host "15. Preview de restore do VS Code"
    Write-Host "16. Backup da configuração Git"
    Write-Host "17. Preview de restore da configuração Git"
    Write-Host "18. Exportar certificado CA confiável"
    Write-Host "19. Criar configuração local a partir do exemplo"
    Write-Host "20. Mostrar exemplos Docker"
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
            & $stackWizard
            Pause-Menu
        }
        "2" {
            & $stackWizard -DryRun
            Pause-Menu
        }
        "3" {
            $profile = Read-Profile
            if ($profile) {
                & $installer -Profile $profile
            }
            else {
                Write-Host "Perfil inválido." -ForegroundColor Yellow
            }
            Pause-Menu
        }
        "4" {
            & $installer -All
            Pause-Menu
        }
        "5" {
            $profile = Read-Profile
            if ($profile) {
                & $installer -Profile $profile -DryRun
            }
            else {
                Write-Host "Perfil inválido." -ForegroundColor Yellow
            }
            Pause-Menu
        }
        "6" {
            $profile = Read-Profile
            if ($profile) {
                & $extensions -Profile $profile
            }
            else {
                Write-Host "Perfil inválido." -ForegroundColor Yellow
            }
            Pause-Menu
        }
        "9" {
            if (-not (Test-Path $configLocal)) {
                Write-Host "Configuração local não encontrada." -ForegroundColor Yellow
                Write-Host "Use a opção 19 primeiro."
            }
            else {
                & $configRunner -ConfigPath $configLocal
            }
            Pause-Menu
        }
        "6" {
            if (-not (Test-Path $configLocal)) {
                Write-Host "Configuração local não encontrada." -ForegroundColor Yellow
            }
            else {
                & $configRunner -ConfigPath $configLocal -DryRun
            }
            Pause-Menu
        }
        "7" {
            & $doctor
            Pause-Menu
        }
        "10" {
            & $showState
            Pause-Menu
        }
        "11" {
            & $inventory
            Pause-Menu
        }
        "12" {
            & $updater
            Pause-Menu
        }
        "13" {
            & $cleanup
            Pause-Menu
        }
        "14" {
            & $backupVsCode
            Pause-Menu
        }
        "15" {
            & $restoreVsCode
            Pause-Menu
        }
        "16" {
            & $backupGit
            Pause-Menu
        }
        "17" {
            & $restoreGit
            Pause-Menu
        }
        "18" {
            $search = Read-Host "Texto para procurar no certificado (ex.: senac.check, Zscaler, Fortinet)"
            & $certExporter -Search $search
            Pause-Menu
        }
        "19" {
            if (Test-Path $configLocal) {
                Write-Host "config\devkit.config.json já existe." -ForegroundColor Yellow
            }
            else {
                Copy-Item $configExample $configLocal
                Write-Host "[OK] Configuração criada:" -ForegroundColor Green
                Write-Host "     $configLocal"
            }
            Pause-Menu
        }
        "20" {
            Get-Content (Join-Path $root "examples\README.md")
            Pause-Menu
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
