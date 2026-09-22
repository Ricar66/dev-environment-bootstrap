#requires -Version 5.1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git não encontrado." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path ".git")) {
    Write-Host "Este diretório não é um clone Git." -ForegroundColor Red
    exit 1
}

$dirty = git status --porcelain

if ($dirty) {
    Write-Host "Existem alterações locais não commitadas." -ForegroundColor Yellow
    Write-Host "Por segurança, o auto-update foi cancelado."
    Write-Host "Use 'git status' e salve/commit/stash suas alterações."
    exit 1
}

Write-Host "Buscando atualizações..." -ForegroundColor Cyan
git fetch origin

$local = (git rev-parse HEAD).Trim()
$upstream = (git rev-parse "@{u}" 2>$null)

if (-not $upstream) {
    Write-Host "A branch atual não possui upstream configurado." -ForegroundColor Yellow
    exit 1
}

$upstream = $upstream.Trim()

if ($local -eq $upstream) {
    Write-Host "[OK] Super Dev Kit já está atualizado." -ForegroundColor Green
    exit 0
}

git pull --ff-only

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao atualizar o repositório."
}

Write-Host "[OK] Super Dev Kit atualizado." -ForegroundColor Green
