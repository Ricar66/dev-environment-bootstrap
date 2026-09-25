#requires -Version 5.1

<#
.SYNOPSIS
    Exibe informações de diagnóstico sobre a instalação atual do Super Dev Kit.

.DESCRIPTION
    Consolida informações locais que normalmente exigiriam abrir vários arquivos:
    versão do kit, plataforma, shell, commit Git, configuração, manifesto e shim global.

    Este comando é somente leitura. Ele não instala, remove ou altera ferramentas.

.NOTES
    O script evita consultar serviços externos. Todas as informações são obtidas
    localmente para que possa ser usado com segurança em troubleshooting.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$versionFile = Join-Path $root "VERSION"
$configPath = Join-Path $root "config\devkit.config.json"
$configExamplePath = Join-Path $root "config\devkit.config.example.json"
$manifestPath = Join-Path $root ".super-dev-kit\manifest.json"
$shimPath = Join-Path $env:LOCALAPPDATA "SuperDevKit\bin\devkit.cmd"

$version = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { "dev" }

$branch = ""
$commit = ""
if (Get-Command git -ErrorAction SilentlyContinue) {
    try {
        $branch = (& git -C $root rev-parse --abbrev-ref HEAD 2>$null | Out-String).Trim()
        $commit = (& git -C $root rev-parse --short HEAD 2>$null | Out-String).Trim()
    }
    catch {
        # Git metadata is optional; info must continue when the clone is incomplete.
    }
}

$manifestSummary = $null
if (Test-Path $manifestPath) {
    try {
        $state = Get-Content $manifestPath -Raw | ConvertFrom-Json
        $manifestSummary = [pscustomobject]@{
            schema   = $state.schema_version
            profiles = @($state.profiles)
            stacks   = @($state.stacks)
            modules  = @($state.modules)
        }
    }
    catch {
        $manifestSummary = [pscustomobject]@{
            schema   = "invalid"
            profiles = @()
            stacks   = @()
            modules  = @()
        }
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "          SUPER DEV KIT - INFO" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Versão:       $version"
Write-Host "Plataforma:   Windows"
Write-Host "PowerShell:   $($PSVersionTable.PSVersion)"
Write-Host "Repositório:  $root"
if ($branch) { Write-Host "Branch:       $branch" }
if ($commit) { Write-Host "Commit:       $commit" }
Write-Host ""
Write-Host "Configuração:"
Write-Host "  Local:      $configPath"
Write-Host "  Existe:     $(Test-Path $configPath)"
Write-Host "  Exemplo:    $configExamplePath"
Write-Host ""
Write-Host "Estado:"
Write-Host "  Manifesto:  $manifestPath"
Write-Host "  Existe:     $(Test-Path $manifestPath)"

if ($manifestSummary) {
    Write-Host "  Schema:     $($manifestSummary.schema)"
    Write-Host "  Perfis:     $(@($manifestSummary.profiles) -join ', ')"
    Write-Host "  Stacks:     $(@($manifestSummary.stacks) -join ', ')"
    Write-Host "  Módulos:    $(@($manifestSummary.modules) -join ', ')"
}

Write-Host ""
Write-Host "CLI global:"
Write-Host "  Shim:       $shimPath"
Write-Host "  Instalado:  $(Test-Path $shimPath)"
