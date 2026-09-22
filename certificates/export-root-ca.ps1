#requires -Version 5.1
<#
.SYNOPSIS
    Exporta um certificado público de uma CA confiável do Windows.

.DESCRIPTION
    Procura certificados nos armazenamentos Root e CA do usuário e da máquina.
    Exporta SOMENTE a parte pública do certificado em formato .cer.
    Este script não exporta chave privada.

.EXAMPLE
    .\certificates\export-root-ca.ps1 -Search "senac.check"

.EXAMPLE
    .\certificates\export-root-ca.ps1 -Search "Minha Empresa" -OutputPath "$env:USERPROFILE\Downloads\empresa-root-ca.cer"
#>

[CmdletBinding()]
param(
    [string]$Search,
    [string]$Thumbprint,
    [string]$OutputPath = "$env:USERPROFILE\Downloads\devkit-root-ca.cer"
)

$ErrorActionPreference = "Stop"

$stores = @(
    "Cert:\CurrentUser\Root",
    "Cert:\LocalMachine\Root",
    "Cert:\CurrentUser\CA",
    "Cert:\LocalMachine\CA"
)

$certificates = foreach ($store in $stores) {
    if (Test-Path $store) {
        Get-ChildItem -Path $store -ErrorAction SilentlyContinue |
            ForEach-Object {
                [PSCustomObject]@{
                    Certificate  = $_
                    Store        = $store
                    Subject      = $_.Subject
                    Issuer       = $_.Issuer
                    FriendlyName = $_.FriendlyName
                    Thumbprint   = $_.Thumbprint
                    NotAfter     = $_.NotAfter
                }
            }
    }
}

if ($Thumbprint) {
    $matches = @($certificates | Where-Object {
        $_.Thumbprint -eq $Thumbprint.Replace(" ", "")
    })
}
elseif ($Search) {
    $matches = @($certificates | Where-Object {
        $_.Subject -like "*$Search*" -or
        $_.Issuer -like "*$Search*" -or
        $_.FriendlyName -like "*$Search*"
    })
}
else {
    Write-Host "Informe um texto para procurar o certificado." -ForegroundColor Yellow
    $Search = Read-Host "Exemplo: senac.check, Zscaler, Fortinet ou nome da empresa"

    $matches = @($certificates | Where-Object {
        $_.Subject -like "*$Search*" -or
        $_.Issuer -like "*$Search*" -or
        $_.FriendlyName -like "*$Search*"
    })
}

if ($matches.Count -eq 0) {
    Write-Host "Nenhum certificado encontrado para '$Search'." -ForegroundColor Red
    Write-Host ""
    Write-Host "Dica: descubra o emissor na VM Linux com:"
    Write-Host '  curl -vk https://registry-1.docker.io/v2/ 2>&1 | grep -i issuer'
    exit 1
}

Write-Host ""
Write-Host "Certificados encontrados:" -ForegroundColor Cyan

for ($i = 0; $i -lt $matches.Count; $i++) {
    $item = $matches[$i]
    Write-Host ""
    Write-Host "[$i] $($item.Subject)"
    Write-Host "    Issuer:      $($item.Issuer)"
    Write-Host "    Store:       $($item.Store)"
    Write-Host "    Thumbprint:  $($item.Thumbprint)"
    Write-Host "    Validade:    $($item.NotAfter)"
}

if ($matches.Count -eq 1) {
    $selected = $matches[0]
}
else {
    $choice = Read-Host "Digite o número do certificado que deseja exportar"

    if ($choice -notmatch '^\d+$' -or [int]$choice -ge $matches.Count) {
        Write-Host "Seleção inválida." -ForegroundColor Red
        exit 1
    }

    $selected = $matches[[int]$choice]
}

$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

Export-Certificate -Cert $selected.Certificate -FilePath $OutputPath -Type CERT -Force | Out-Null

Write-Host ""
Write-Host "[OK] Certificado público exportado:" -ForegroundColor Green
Write-Host "     $OutputPath"
Write-Host ""
Write-Host "Nenhuma chave privada foi exportada."
Write-Host "Não publique certificados internos no GitHub sem autorização da organização."
