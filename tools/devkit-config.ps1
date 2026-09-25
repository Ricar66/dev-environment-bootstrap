#requires -Version 5.1

<#
.SYNOPSIS
    Inspeciona e valida o arquivo de configuração declarativa do Super Dev Kit.

.DESCRIPTION
    Oferece três operações somente leitura:
      path      mostra qual arquivo seria usado;
      show      exibe o JSON atual;
      validate  valida sintaxe e campos básicos do contrato v1.

    O comando não cria nem altera devkit.config.json.

.PARAMETER Action
    path, show ou validate.

.PARAMETER ConfigPath
    Caminho opcional. Quando omitido, usa config/devkit.config.json.

.NOTES
    Exit code 2 indica configuração sintaticamente válida, porém incompatível
    com as regras conhecidas da linha v1.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet("path", "show", "validate")]
    [string]$Action,

    [string]$ConfigPath = "config\devkit.config.json"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path $root $ConfigPath
}

if ($Action -eq "path") {
    Write-Output $ConfigPath
    Write-Host "Existe: $(Test-Path $ConfigPath)"
    exit 0
}

if (-not (Test-Path $ConfigPath)) {
    Write-Host "Configuração não encontrada: $ConfigPath" -ForegroundColor Yellow
    Write-Host "Crie a configuração a partir do exemplo:"
    Write-Host "  Copy-Item .\config\devkit.config.example.json .\config\devkit.config.json"
    exit 1
}

try {
    $raw = Get-Content $ConfigPath -Raw
    $config = $raw | ConvertFrom-Json
}
catch {
    Write-Host "JSON inválido: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}

if ($Action -eq "show") {
    $config | ConvertTo-Json -Depth 20
    exit 0
}

$errors = New-Object System.Collections.Generic.List[string]
$allowedProfiles = @("essential", "frontend", "backend", "fullstack", "datasql", "devops")

if ($config.profile -and ([string]$config.profile).ToLowerInvariant() -notin $allowedProfiles) {
    $errors.Add("profile deve ser um de: $($allowedProfiles -join ', ')")
}

foreach ($field in @("install_vscode_extensions", "non_interactive")) {
    if ($config.PSObject.Properties.Name -contains $field) {
        if ($config.$field -isnot [bool]) {
            $errors.Add("$field deve ser booleano.")
        }
    }
}

if ($config.features) {
    foreach ($field in @("docker", "wsl", "extras")) {
        if ($config.features.PSObject.Properties.Name -contains $field -and $config.features.$field -isnot [bool]) {
            $errors.Add("features.$field deve ser booleano.")
        }
    }
}

if ($config.custom) {
    foreach ($field in @("windows_packages", "linux_packages", "vscode_extensions")) {
        if ($config.custom.PSObject.Properties.Name -contains $field) {
            $value = $config.custom.$field
            if ($null -ne $value -and $value -is [string]) {
                $errors.Add("custom.$field deve ser uma lista.")
            }
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Configuração inválida:" -ForegroundColor Red
    foreach ($item in $errors) {
        Write-Host "  - $item"
    }
    exit 2
}

Write-Host "[OK] Configuração válida: $ConfigPath" -ForegroundColor Green
Write-Host "Perfil: $($config.profile)"
exit 0
