#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$BackupPath,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git não encontrado." -ForegroundColor Yellow
    exit 1
}

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$backupRoot = Join-Path $root ".super-dev-kit\backups\git"

if (-not $BackupPath) {
    $latest = Get-ChildItem $backupRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if (-not $latest) {
        Write-Host "Nenhum backup Git encontrado." -ForegroundColor Yellow
        exit 1
    }

    $BackupPath = $latest.FullName
}

if (-not [System.IO.Path]::IsPathRooted($BackupPath)) {
    $BackupPath = Join-Path $root $BackupPath
}

$file = if ((Get-Item $BackupPath).PSIsContainer) {
    Join-Path $BackupPath "git-config.json"
}
else {
    $BackupPath
}

if (-not (Test-Path $file)) {
    Write-Host "Arquivo de backup não encontrado: $file" -ForegroundColor Red
    exit 1
}

$data = Get-Content $file -Raw | ConvertFrom-Json

Write-Host "Configurações que serão restauradas:" -ForegroundColor Cyan
foreach ($property in $data.values.PSObject.Properties) {
    Write-Host "  $($property.Name) = $($property.Value)"
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "[PREVIEW] Nada foi alterado." -ForegroundColor Green
    Write-Host "Use -Apply para restaurar."
    exit 0
}

foreach ($property in $data.values.PSObject.Properties) {
    git config --global $property.Name ([string]$property.Value)
}

Write-Host "[OK] Configuração Git restaurada." -ForegroundColor Green
