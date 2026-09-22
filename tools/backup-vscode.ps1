#requires -Version 5.1

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $root ".super-dev-kit\backups\vscode\$stamp"
$userDir = Join-Path $env:APPDATA "Code\User"

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

foreach ($file in @("settings.json", "keybindings.json")) {
    $source = Join-Path $userDir $file
    if (Test-Path $source) {
        Copy-Item $source (Join-Path $backupDir $file) -Force
    }
}

$snippets = Join-Path $userDir "snippets"
if (Test-Path $snippets) {
    Copy-Item $snippets (Join-Path $backupDir "snippets") -Recurse -Force
}

if (Get-Command code -ErrorAction SilentlyContinue) {
    code --list-extensions | Set-Content (Join-Path $backupDir "extensions.txt") -Encoding UTF8
}

[pscustomobject]@{
    created_at = (Get-Date).ToUniversalTime().ToString("o")
    platform   = "windows"
    source     = $userDir
} | ConvertTo-Json | Set-Content (Join-Path $backupDir "metadata.json") -Encoding UTF8

Write-Host "[OK] Backup do VS Code criado:" -ForegroundColor Green
Write-Host "     $backupDir"
