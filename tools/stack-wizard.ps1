#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$stackDir = Join-Path $root "stacks"
$installer = Join-Path $root "tools\install-stack.ps1"

$stacks = @(
    Get-ChildItem $stackDir -Filter "*.json" |
        Sort-Object Name |
        ForEach-Object {
            $data = Get-Content $_.FullName -Raw | ConvertFrom-Json
            [pscustomobject]@{
                Slug        = $_.BaseName
                Name        = $data.name
                Description = $data.description
            }
        }
)

if ($stacks.Count -eq 0) {
    Write-Host "Nenhuma stack encontrada." -ForegroundColor Yellow
    exit 1
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "          SUPER DEV KIT - STACK WIZARD" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $stacks.Count; $i++) {
    Write-Host "$($i + 1). $($stacks[$i].Name)"
    Write-Host "   $($stacks[$i].Description)"
}

Write-Host ""
$choice = Read-Host "Escolha uma stack"

if ($choice -notmatch '^\d+$') {
    Write-Host "Seleção inválida." -ForegroundColor Red
    exit 1
}

$index = [int]$choice - 1

if ($index -lt 0 -or $index -ge $stacks.Count) {
    Write-Host "Seleção inválida." -ForegroundColor Red
    exit 1
}

$selected = $stacks[$index]

Write-Host ""
Write-Host "Selecionado: $($selected.Name)" -ForegroundColor Green

if ($DryRun) {
    & $installer -Stack $selected.Slug -DryRun
}
else {
    & $installer -Stack $selected.Slug
}
