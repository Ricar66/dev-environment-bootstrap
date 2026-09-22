#requires -Version 5.1

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$installer = Join-Path $root "windows\setup-windows.ps1"
$doctor = Join-Path $root "diagnostics\dev-doctor.ps1"
$certExporter = Join-Path $root "certificates\export-root-ca.ps1"

function Show-Menu {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "              SUPER DEV KIT" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1.  Essential"
    Write-Host "2.  Frontend"
    Write-Host "3.  Backend"
    Write-Host "4.  Full Stack"
    Write-Host "5.  Data / SQL"
    Write-Host "6.  DevOps / Docker"
    Write-Host "7.  Instalar tudo"
    Write-Host "8.  Dev Doctor"
    Write-Host "9.  Exportar certificado CA confiável"
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
        "1" { & $installer -Profile Essential }
        "2" { & $installer -Profile Frontend }
        "3" { & $installer -Profile Backend }
        "4" { & $installer -Profile FullStack }
        "5" { & $installer -Profile DataSQL }
        "6" { & $installer -Profile DevOps }
        "7" { & $installer -All }
        "8" {
            if (Test-Path $doctor) {
                & $doctor
            }
            else {
                Write-Host "Dev Doctor não encontrado." -ForegroundColor Yellow
            }
            Read-Host "Pressione Enter para voltar"
        }
        "9" {
            if (Test-Path $certExporter) {
                $search = Read-Host "Texto para procurar no certificado (ex.: senac.check, Zscaler, Fortinet)"
                & $certExporter -Search $search
            }
            else {
                Write-Host "Exportador de certificado não encontrado." -ForegroundColor Yellow
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
