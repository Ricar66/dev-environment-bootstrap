#requires -Version 5.1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$installer = Join-Path $root "windows\setup-windows.ps1"
$doctor = Join-Path $root "diagnostics\dev-doctor.ps1"

function Show-Menu {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "             SUPER DEV KIT" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Instalação essencial"
    Write-Host "2. Essencial + Docker Desktop"
    Write-Host "3. Essencial + WSL"
    Write-Host "4. Instalar tudo"
    Write-Host "5. Diagnosticar ambiente"
    Write-Host "0. Sair"
    Write-Host ""
}

if (-not (Test-Path $installer)) {
    throw "Instalador não encontrado: $installer"
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Escolha uma opção"

    switch ($choice) {
        "1" { & $installer; break }
        "2" { & $installer -Docker; break }
        "3" { & $installer -WSL; break }
        "4" { & $installer -All; break }
        "5" {
            if (Test-Path $doctor) {
                & $doctor
            }
            else {
                Write-Host "Dev Doctor não encontrado." -ForegroundColor Yellow
            }
            Read-Host "Pressione Enter para voltar"
        }
        "0" { return }
        default {
            Write-Host "Opção inválida." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}
