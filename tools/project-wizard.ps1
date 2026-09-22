#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$catalogPath = Join-Path $root "templates\catalog.json"
$generator = Join-Path $root "tools\create-project.ps1"

if (-not (Test-Path $catalogPath)) {
    throw "Catálogo de templates não encontrado: $catalogPath"
}

$catalog = Get-Content $catalogPath -Raw | ConvertFrom-Json

$templates = @(
    $catalog.templates.PSObject.Properties |
        Sort-Object Name |
        ForEach-Object {
            [pscustomobject]@{
                Key         = $_.Name
                Name        = $_.Value.name
                Description = $_.Value.description
            }
        }
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "          SUPER DEV KIT - PROJECT WIZARD" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $templates.Count; $i++) {
    Write-Host "$($i + 1). $($templates[$i].Name)"
    Write-Host "   $($templates[$i].Description)"
}

Write-Host ""
$choice = Read-Host "Escolha um template"

if ($choice -notmatch '^\d+$') {
    Write-Host "Seleção inválida." -ForegroundColor Red
    exit 1
}

$index = [int]$choice - 1

if ($index -lt 0 -or $index -ge $templates.Count) {
    Write-Host "Seleção inválida." -ForegroundColor Red
    exit 1
}

$selected = $templates[$index]
$name = Read-Host "Nome do projeto"

if (-not $name) {
    Write-Host "Nome do projeto é obrigatório." -ForegroundColor Red
    exit 1
}

$output = Read-Host "Pasta de destino base [.]"
if (-not $output) { $output = "." }

$devContainerAnswer = Read-Host "Adicionar Dev Container? (s/N)"
$withDevContainer = $devContainerAnswer -match '^(s|sim|y|yes)$'

$installAnswer = Read-Host "Instalar dependências após gerar? (s/N)"
$installDependencies = $installAnswer -match '^(s|sim|y|yes)$'

$params = @{
    Template   = $selected.Key
    Name       = $name
    OutputPath = $output
}

if ($DryRun) { $params.DryRun = $true }
if ($withDevContainer) { $params.WithDevContainer = $true }
if ($installDependencies) { $params.InstallDependencies = $true }

Write-Host ""
& $generator @params
