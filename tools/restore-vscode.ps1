#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$BackupPath,
    [switch]$Apply,
    [switch]$SkipExtensions
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$backupRoot = Join-Path $root ".super-dev-kit\backups\vscode"
$userDir = Join-Path $env:APPDATA "Code\User"

if (-not $BackupPath) {
    if (-not (Test-Path $backupRoot)) {
        Write-Host "Nenhum backup do VS Code encontrado." -ForegroundColor Yellow
        exit 1
    }

    $latest = Get-ChildItem $backupRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latest) {
        Write-Host "Nenhum backup do VS Code encontrado." -ForegroundColor Yellow
        exit 1
    }

    $BackupPath = $latest.FullName
}

if (-not [System.IO.Path]::IsPathRooted($BackupPath)) {
    $BackupPath = Join-Path $root $BackupPath
}

if (-not (Test-Path $BackupPath)) {
    Write-Host "Backup não encontrado: $BackupPath" -ForegroundColor Red
    exit 1
}

Write-Host "Backup selecionado:" -ForegroundColor Cyan
Write-Host "  $BackupPath"
Write-Host ""
Write-Host "Itens disponíveis:"

foreach ($item in @("settings.json", "keybindings.json", "snippets", "extensions.txt")) {
    if (Test-Path (Join-Path $BackupPath $item)) {
        Write-Host "  - $item"
    }
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "[PREVIEW] Nada foi restaurado." -ForegroundColor Green
    Write-Host "Para aplicar:"
    Write-Host ".\tools\restore-vscode.ps1 -BackupPath \"$BackupPath\" -Apply"
    exit 0
}

$safetyRoot = Join-Path $root ".super-dev-kit\backups\vscode-pre-restore"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$safetyDir = Join-Path $safetyRoot $stamp
New-Item -ItemType Directory -Path $safetyDir -Force | Out-Null

foreach ($file in @("settings.json", "keybindings.json")) {
    $current = Join-Path $userDir $file
    if (Test-Path $current) {
        Copy-Item $current (Join-Path $safetyDir $file) -Force
    }
}

$currentSnippets = Join-Path $userDir "snippets"
if (Test-Path $currentSnippets) {
    Copy-Item $currentSnippets (Join-Path $safetyDir "snippets") -Recurse -Force
}

New-Item -ItemType Directory -Path $userDir -Force | Out-Null

foreach ($file in @("settings.json", "keybindings.json")) {
    $source = Join-Path $BackupPath $file
    if (Test-Path $source) {
        Copy-Item $source (Join-Path $userDir $file) -Force
    }
}

$backupSnippets = Join-Path $BackupPath "snippets"
if (Test-Path $backupSnippets) {
    $destSnippets = Join-Path $userDir "snippets"
    New-Item -ItemType Directory -Path $destSnippets -Force | Out-Null
    Copy-Item (Join-Path $backupSnippets "*") $destSnippets -Recurse -Force
}

$extensionFile = Join-Path $BackupPath "extensions.txt"
if (-not $SkipExtensions -and (Test-Path $extensionFile) -and (Get-Command code -ErrorAction SilentlyContinue)) {
    foreach ($extension in Get-Content $extensionFile) {
        if ($extension) {
            code --install-extension $extension --force
        }
    }
}

Write-Host "[OK] VS Code restaurado." -ForegroundColor Green
Write-Host "Backup de segurança do estado anterior:"
Write-Host "  $safetyDir"
