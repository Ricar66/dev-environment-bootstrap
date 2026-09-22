#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ConfigPath = ".\config\devkit.config.json",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path $root $ConfigPath
}

if (-not (Test-Path $ConfigPath)) {
    Write-Host "Configuração não encontrada: $ConfigPath" -ForegroundColor Red
    Write-Host "Comece copiando:"
    Write-Host "  Copy-Item .\config\devkit.config.example.json .\config\devkit.config.json"
    exit 1
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$profile = if ($config.profile) { [string]$config.profile } else { "essential" }

$profileMap = @{
    essential = "Essential"
    frontend = "Frontend"
    backend = "Backend"
    fullstack = "FullStack"
    datasql = "DataSQL"
    devops = "DevOps"
}

$key = $profile.ToLower()

if (-not $profileMap.ContainsKey($key)) {
    throw "Perfil inválido no arquivo de configuração: $profile"
}

$resolvedProfile = $profileMap[$key]
$installer = Join-Path $root "windows\setup-windows.ps1"
$extensions = Join-Path $root "tools\install-vscode-extensions.ps1"

$params = @{
    Profile = $resolvedProfile
}

if ($config.features.docker -eq $true) { $params.Docker = $true }
if ($config.features.wsl -eq $true) { $params.WSL = $true }
if ($config.features.extras -eq $true) { $params.Extras = $true }
if ($config.git.name) { $params.GitName = [string]$config.git.name }
if ($config.git.email) { $params.GitEmail = [string]$config.git.email }
if ($DryRun) { $params.DryRun = $true }

Write-Host "Configuração: $ConfigPath" -ForegroundColor Cyan
Write-Host "Perfil: $resolvedProfile"
Write-Host ""

& $installer @params

if ($config.install_vscode_extensions -eq $true) {
    if ($DryRun) {
        & $extensions -Profile $resolvedProfile -DryRun
    }
    else {
        & $extensions -Profile $resolvedProfile
    }
}
