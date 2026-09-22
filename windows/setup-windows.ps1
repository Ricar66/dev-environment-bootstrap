#requires -Version 5.1
<#
.SYNOPSIS
    Prepara um Windows para desenvolvimento usando winget.

.DESCRIPTION
    Instala um conjunto base de ferramentas de desenvolvimento de forma
    idempotente. Pacotes já instalados são ignorados.

    Perfil base:
      - Git
      - Node.js LTS
      - Visual Studio Code
      - PowerShell 7
      - Windows Terminal
      - GitHub CLI
      - 7-Zip

    Opcionais:
      - Docker Desktop
      - WSL
      - Postman

.EXAMPLE
    .\setup-windows.ps1

.EXAMPLE
    .\setup-windows.ps1 -All

.EXAMPLE
    .\setup-windows.ps1 -Docker -WSL

.EXAMPLE
    .\setup-windows.ps1 -GitName "Seu Nome" -GitEmail "voce@email.com"
#>

[CmdletBinding()]
param(
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
    param([string]$Message)
    $line = "`n=== $Message ==="
    Write-Host $line -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value $line
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
        Write-Host "[OK] $Name já está instalado."
        Add-Content -Path $LogFile -Value "[OK] $Name já está instalado."
        return
    }

    Write-Host "[INSTALANDO] $Name ($Id)"
    Add-Content -Path $LogFile -Value "[INSTALANDO] $Name ($Id)"

    winget install `
        --id $Id `
        -e `
        --accept-package-agreements `
        --accept-source-agreements `
        --silent

    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao instalar $Name ($Id). Código: $LASTEXITCODE"
    }
}

if (-not (Test-Administrator)) {
    Write-Host "Abra o PowerShell como Administrador e execute o script novamente." -ForegroundColor Yellow
    exit 1
}

"" | Set-Content -Path $LogFile
Add-Content -Path $LogFile -Value "Início: $(Get-Date -Format o)"

Write-Step "Verificando winget"

if (-not (Test-Winget)) {
    Write-Host "winget não foi encontrado." -ForegroundColor Red
    Write-Host "Instale/atualize o 'App Installer' pela Microsoft Store e tente novamente."
    exit 1
}

winget source update | Tee-Object -FilePath $LogFile -Append

$corePackages = @(
    @{ Id = "Git.Git";                    Name = "Git" },
    @{ Id = "OpenJS.NodeJS.LTS";          Name = "Node.js LTS" },
    @{ Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code" },
    @{ Id = "Microsoft.PowerShell";       Name = "PowerShell 7" },
    @{ Id = "Microsoft.WindowsTerminal";  Name = "Windows Terminal" },
    @{ Id = "GitHub.cli";                 Name = "GitHub CLI" },
    @{ Id = "7zip.7zip";                  Name = "7-Zip" }
)

Write-Step "Instalando ferramentas essenciais"

foreach ($pkg in $corePackages) {
    Install-WingetPackage -Id $pkg.Id -Name $pkg.Name
}

if ($All) {
    $Docker = $true
    $WSL = $true
    $Extras = $true
}

if ($WSL) {
    Write-Step "Configurando WSL"

    try {
        wsl --status | Out-Null
        Write-Host "[OK] WSL já está disponível."
    }
    catch {
        Write-Host "Habilitando WSL. O Windows poderá solicitar reinicialização."
        wsl --install --no-distribution
    }
}

if ($Docker) {
    Write-Step "Instalando Docker Desktop"
    Install-WingetPackage -Id "Docker.DockerDesktop" -Name "Docker Desktop"
}

if ($Extras) {
    Write-Step "Instalando ferramentas opcionais"

    $extraPackages = @(
        @{ Id = "Postman.Postman"; Name = "Postman" }
    )

    foreach ($pkg in $extraPackages) {
        Install-WingetPackage -Id $pkg.Id -Name $pkg.Name
    }
}

if ($GitName -or $GitEmail) {
    Write-Step "Configurando Git"
    $gitExe = Get-Command git -ErrorAction SilentlyContinue

    if (-not $gitExe) {
        Write-Host "Git foi instalado, mas ainda não está no PATH desta sessão."
        Write-Host "Reabra o terminal e configure manualmente ou execute o script novamente."
    }
    else {
        if ($GitName) {
            git config --global user.name "$GitName"
            Write-Host "[OK] git user.name configurado."
        }

        if ($GitEmail) {
            git config --global user.email "$GitEmail"
            Write-Host "[OK] git user.email configurado."
        }

        git config --global init.defaultBranch main
    }
}

Write-Step "Resumo"

Write-Host "Instalação concluída."
Write-Host ""
Write-Host "Recomendado:"
Write-Host "  1. Feche e abra novamente o terminal."
Write-Host "  2. Execute: git --version"
Write-Host "  3. Execute: node --version"
Write-Host "  4. Execute: npm --version"
Write-Host "  5. Execute: code --version"
Write-Host "  6. Execute: gh --version"

if ($Docker) {
    Write-Host "  7. Abra o Docker Desktop e execute: docker --version"
}

if ($WSL) {
    Write-Host ""
    Write-Host "Se o WSL foi habilitado agora, reinicie o Windows antes de continuar."
}

Write-Host ""
Write-Host "Log: $LogFile"
Add-Content -Path $LogFile -Value "Fim: $(Get-Date -Format o)"
