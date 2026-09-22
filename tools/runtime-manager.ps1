#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet("node","python","dotnet","java","php")]
    [string]$Runtime,

    [string]$Version,
    [string]$Manager = "auto",
    [switch]$DryRun,
    [switch]$List
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$catalogPath = Join-Path $root "versions\managers.json"

if (-not (Test-Path $catalogPath)) {
    throw "Catálogo de version managers não encontrado: $catalogPath"
}

$catalog = Get-Content $catalogPath -Raw | ConvertFrom-Json

function Test-ManagerAvailable {
    param([Parameter(Mandatory)][string]$Name)

    switch ($Name) {
        "sdkman" {
            return $null -ne (Get-Command sdk -ErrorAction SilentlyContinue)
        }
        "dotnet-install" {
            return $null -ne (Get-Command dotnet-install -ErrorAction SilentlyContinue)
        }
        default {
            return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
        }
    }
}

function Show-Managers {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "       SUPER DEV KIT - VERSION MANAGERS" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($property in $catalog.runtimes.PSObject.Properties) {
        $runtimeName = $property.Name
        $runtime = $property.Value
        Write-Host "$($runtime.display_name) ($runtimeName)"

        foreach ($candidate in @($runtime.managers)) {
            $status = if (Test-ManagerAvailable -Name ([string]$candidate)) { "disponível" } else { "não detectado" }
            Write-Host "  - ${candidate}: $status"
        }

        Write-Host "  - fallback: $($runtime.fallback)"
        Write-Host ""
    }
}

if ($List) {
    Show-Managers
    exit 0
}

if (-not $Runtime -or -not $Version) {
    Write-Host "Informe -Runtime e -Version, ou use -List." -ForegroundColor Yellow
    Write-Host "Exemplo:"
    Write-Host "  .\tools\runtime-manager.ps1 -Runtime node -Version 22 -Manager auto -DryRun"
    exit 1
}

if ($Version -notmatch '^[A-Za-z0-9._+-]+$') {
    throw "Versão inválida. Use apenas letras, números, ponto, hífen, underscore e +."
}

$runtimeConfig = $catalog.runtimes.PSObject.Properties[$Runtime].Value

if (-not $runtimeConfig) {
    throw "Runtime não encontrado no catálogo: $Runtime"
}

$selectedManager = $Manager.ToLower()

if ($selectedManager -eq "auto") {
    $selectedManager = "native"

    foreach ($candidate in @($runtimeConfig.managers)) {
        if (Test-ManagerAvailable -Name ([string]$candidate)) {
            $selectedManager = [string]$candidate
            break
        }
    }
}
elseif ($selectedManager -ne "native" -and -not (@($runtimeConfig.managers) -contains $selectedManager)) {
    throw "Manager '$selectedManager' não é suportado para $Runtime."
}

Write-Host "Runtime: $($runtimeConfig.display_name)"
Write-Host "Versão:  $Version"
Write-Host "Manager: $selectedManager"
Write-Host ""

if ($selectedManager -eq "native") {
    Write-Host "[FALLBACK] Nenhum version manager compatível foi selecionado/detectado." -ForegroundColor Yellow
    Write-Host "O Super Dev Kit não baixa version managers automaticamente."
    Write-Host "Use a instalação nativa da stack e valide a versão com check-runtime-versions."
    exit 0
}

if (-not $DryRun -and -not (Test-ManagerAvailable -Name $selectedManager)) {
    Write-Host "Manager '$selectedManager' não está disponível nesta sessão." -ForegroundColor Red
    exit 2
}

$commands = @()

switch ($selectedManager) {
    "fnm" {
        $commands += ,@("fnm","install",$Version)
        $commands += ,@("fnm","default",$Version)
    }
    "nvm" {
        $commands += ,@("nvm","install",$Version)
        $commands += ,@("nvm","use",$Version)
    }
    "pyenv" {
        $commands += ,@("pyenv","install","-s",$Version)
        $commands += ,@("pyenv","global",$Version)
    }
    "dotnet-install" {
        $commands += ,@("dotnet-install","--version",$Version)
    }
    "sdkman" {
        $commands += ,@("sdk","install","java",$Version)
        $commands += ,@("sdk","default","java",$Version)
    }
    "phpenv" {
        $commands += ,@("phpenv","install","-s",$Version)
        $commands += ,@("phpenv","global",$Version)
    }
    default {
        throw "Adapter ainda não implementado: $selectedManager"
    }
}

foreach ($command in $commands) {
    $exe = $command[0]
    $args = @($command[1..($command.Count - 1)])

    if ($DryRun) {
        Write-Host "[DRY-RUN] $exe $($args -join ' ')"
        continue
    }

    Write-Host "[EXEC] $exe $($args -join ' ')" -ForegroundColor Cyan
    & $exe @args

    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar $exe."
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "[OK] Plano do version manager validado." -ForegroundColor Green
}
else {
    Write-Host "[OK] Runtime processado pelo adapter '$selectedManager'." -ForegroundColor Green
    Write-Host "Abra uma nova sessão de terminal se o manager exigir recarga do ambiente."
}
