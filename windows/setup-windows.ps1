#requires -Version 5.1
<#
.SYNOPSIS
    Prepara um Windows para desenvolvimento usando winget.

.DESCRIPTION
    Instala ferramentas por perfil e ignora pacotes já instalados.

.EXAMPLE
    .\setup-windows.ps1 -Profile Frontend

.EXAMPLE
    .\setup-windows.ps1 -Profile FullStack -GitName "Seu Nome" -GitEmail "voce@email.com"

.EXAMPLE
    .\setup-windows.ps1 -Profile DevOps

.EXAMPLE
    .\setup-windows.ps1 -All
#>

[CmdletBinding()]
param(
    [ValidateSet("Essential", "Frontend", "Backend", "FullStack", "DataSQL", "DevOps")]
    [string]$Profile = "Essential",

    [switch]$Docker,
    [switch]$WSL,
    [switch]$Extras,
    [switch]$All,

    [string]$GitName,
    [string]$GitEmail
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$LogFile = Join-Path $PSScriptRoot "setup-windows.log"

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)

    $line = "`n=== $Message ==="
    Write-Host $line -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value $line
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Test-Winget {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

function Test-WingetPackage {
    param([Parameter(Mandatory)][string]$Id)

    $result = winget list --id $Id -e --accept-source-agreements 2>$null | Out-String
    return $result -match [regex]::Escape($Id)
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name
    )

    if (Test-WingetPackage -Id $Id) {
        Write-Host "[OK] $Name já está instalado." -ForegroundColor Green
        Add-Content -Path $LogFile -Value "[OK] $Name já está instalado."
        return
    }

    Write-Host "[INSTALANDO] $Name ($Id)" -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "[INSTALANDO] $Name ($Id)"

    winget install `
        --id $Id `
        -e `
        --accept-package-agreements `
        --accept-source-agreements `
        --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Não foi possível instalar $Name ($Id). Código: $LASTEXITCODE"
        Add-Content -Path $LogFile -Value "[AVISO] Falha: $Name ($Id), código $LASTEXITCODE"
    }
}

if (-not (Test-Administrator)) {
    Write-Host "Abra o PowerShell como Administrador e execute novamente." -ForegroundColor Yellow
    exit 1
}

"" | Set-Content -Path $LogFile
Add-Content -Path $LogFile -Value "Início: $(Get-Date -Format o)"

Write-Step "Verificando winget"

if (-not (Test-Winget)) {
    Write-Host "winget não foi encontrado." -ForegroundColor Red
    Write-Host "Instale/atualize o App Installer pela Microsoft Store e tente novamente."
    exit 1
}

winget source update | Tee-Object -FilePath $LogFile -Append

if ($All) {
    $Profile = "FullStack"
    $Docker = $true
    $WSL = $true
    $Extras = $true
}

$corePackages = @(
    @{ Id = "Git.Git";                    Name = "Git" },
    @{ Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code" },
    @{ Id = "Microsoft.PowerShell";       Name = "PowerShell 7" },
    @{ Id = "Microsoft.WindowsTerminal";  Name = "Windows Terminal" },
    @{ Id = "GitHub.cli";                 Name = "GitHub CLI" },
    @{ Id = "7zip.7zip";                  Name = "7-Zip" }
)

$nodePackage = @{ Id = "OpenJS.NodeJS.LTS"; Name = "Node.js LTS" }
$pythonPackage = @{ Id = "Python.Python.3.13"; Name = "Python 3.13" }
$postmanPackage = @{ Id = "Postman.Postman"; Name = "Postman" }
$dbeaverPackage = @{ Id = "DBeaver.DBeaver.Community"; Name = "DBeaver Community" }

$profilePackages = @()

switch ($Profile) {
    "Essential" {
        $profilePackages = @()
    }
    "Frontend" {
        $profilePackages = @($nodePackage, $postmanPackage)
    }
    "Backend" {
        $profilePackages = @($nodePackage, $pythonPackage, $postmanPackage)
        $Docker = $true
    }
    "FullStack" {
        $profilePackages = @($nodePackage, $pythonPackage, $postmanPackage)
        $Docker = $true
        $WSL = $true
    }
    "DataSQL" {
        $profilePackages = @($pythonPackage, $dbeaverPackage)
        $Docker = $true
    }
    "DevOps" {
        $Docker = $true
        $WSL = $true
    }
}

if ($Extras) {
    $profilePackages += @($postmanPackage, $dbeaverPackage)
}

Write-Step "Perfil selecionado: $Profile"

$packages = @($corePackages + $profilePackages) |
    Group-Object { $_.Id } |
    ForEach-Object { $_.Group[0] }

foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Name $pkg.Name
}

if ($WSL) {
    Write-Step "Configurando WSL"

    $wslAvailable = $false

    try {
        wsl --status *> $null
        if ($LASTEXITCODE -eq 0) {
            $wslAvailable = $true
        }
    }
    catch {
        $wslAvailable = $false
    }

    if ($wslAvailable) {
        Write-Host "[OK] WSL já está disponível." -ForegroundColor Green
    }
    else {
        Write-Host "Habilitando WSL. O Windows poderá solicitar reinicialização."
        wsl --install --no-distribution
    }
}

if ($Docker) {
    Write-Step "Instalando Docker Desktop"
    Install-WingetPackage -Id "Docker.DockerDesktop" -Name "Docker Desktop"
}

if ($GitName -or $GitEmail) {
    Write-Step "Configurando Git"

    $gitExe = Get-Command git -ErrorAction SilentlyContinue

    if (-not $gitExe) {
        Write-Warning "Git foi instalado, mas ainda não está no PATH desta sessão."
        Write-Host "Reabra o terminal e execute novamente a configuração do Git."
    }
    else {
        if ($GitName) {
            git config --global user.name "$GitName"
            Write-Host "[OK] git user.name configurado." -ForegroundColor Green
        }

        if ($GitEmail) {
            git config --global user.email "$GitEmail"
            Write-Host "[OK] git user.email configurado." -ForegroundColor Green
        }

        git config --global init.defaultBranch main
    }
}

Write-Step "Resumo"

Write-Host "Perfil: $Profile"
Write-Host "Instalação concluída."
Write-Host ""
Write-Host "Feche e abra novamente o terminal para atualizar o PATH."
Write-Host "Depois, execute:"
Write-Host "  .\diagnostics\dev-doctor.ps1"
Write-Host ""
Write-Host "Log:"
Write-Host "  $LogFile"

if ($Docker) {
    Write-Host ""
    Write-Host "Abra o Docker Desktop antes de executar containers."
}

if ($WSL) {
    Write-Host ""
    Write-Host "Se o WSL foi habilitado agora, reinicie o Windows."
}

Add-Content -Path $LogFile -Value "Fim: $(Get-Date -Format o)"
