#requires -Version 5.1

$ErrorActionPreference = "Stop"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git não encontrado." -ForegroundColor Yellow
    exit 1
}

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $root ".super-dev-kit\backups\git\$stamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$keys = @(
    "user.name",
    "user.email",
    "init.defaultBranch",
    "core.autocrlf",
    "pull.rebase",
    "push.autoSetupRemote"
)

$config = [ordered]@{
    created_at = (Get-Date).ToUniversalTime().ToString("o")
    values     = [ordered]@{}
}

foreach ($key in $keys) {
    $value = git config --global --get $key 2>$null
    if ($LASTEXITCODE -eq 0 -and $value) {
        $config.values[$key] = ($value | Out-String).Trim()
    }
}

$config | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $backupDir "git-config.json") -Encoding UTF8

Write-Host "[OK] Backup da configuração Git criado:" -ForegroundColor Green
Write-Host "     $backupDir"
Write-Host "Somente chaves não sensíveis selecionadas foram exportadas."
