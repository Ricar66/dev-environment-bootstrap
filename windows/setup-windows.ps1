#requires -Version 5.1
<#
.SYNOPSIS
    Prepara um Windows para desenvolvimento usando winget.

.DESCRIPTION
    Instala ferramentas por perfil, suporta dry-run e registra em um manifesto
    local quais pacotes já existiam e quais foram instalados pelo Super Dev Kit.

.EXAMPLE
    .\setup-windows.ps1 -Profile FullStack

.EXAMPLE
    .\setup-windows.ps1 -Profile FullStack -DryRun

.EXAMPLE
    .\setup-windows.ps1 -Profile Frontend -CustomPackages "Microsoft.AzureCLI","Hashicorp.Terraform"
#>

[CmdletBinding()]
param(
    [ValidateSet("Essential", "Frontend", "Backend", "FullStack", "DataSQL", "DevOps")]
    [string]$Profile = "Essential",

    [switch]$Docker,
    [switch]$WSL,
    [switch]$Extras,
    [switch]$All,
    [switch]$DryRun,

    [string]$GitName,
    [string]$GitEmail,

    [string[]]$CustomPackages = @()
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$StateHelper = Join-Path $RepoRoot "tools\state.ps1"
$LogFile = Join-Path $PSScriptRoot "setup-windows.log"

if (Test-Path $StateHelper) {
    . $StateHelper
}

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

    if (-not (Test-Winget)) {
        return $false
    }

    $result = winget list --id $Id -e --accept-source-agreements 2>$null | Out-String
    return $result -match [regex]::Escape($Id)
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name
    )

    if ($DryRun) {
        Write-Host "[DRY-RUN] winget install --id $Id -e"
        return
    }

    $preexisting = Test-WingetPackage -Id $Id

    if ($preexisting) {
        Write-Host "[OK] $Name já está instalado." -ForegroundColor Green
        Add-Content -Path $LogFile -Value "[OK] $Name já está instalado."

        if (Get-Command Register-DevKitPackage -ErrorAction SilentlyContinue) {
            Register-DevKitPackage -Id $Id -Name $Name -Manager "winget" -Preexisting $true -PresentAfter $true
        }

        return
    }

    Write-Host "[INSTALANDO] $Name ($Id)" -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "[INSTALANDO] $Name ($Id)"

    winget install --id $Id -e --accept-package-agreements --accept-source-agreements --silent

    $exitCode = $LASTEXITCODE
    $presentAfter = Test-WingetPackage -Id $Id

    if (Get-Command Register-DevKitPackage -ErrorAction SilentlyContinue) {
        Register-DevKitPackage -Id $Id -Name $Name -Manager "winget" -Preexisting $false -PresentAfter $presentAfter
    }

    if ($exitCode -ne 0 -and -not $presentAfter) {
        Write-Warning "Não foi possível instalar $Name ($Id). Código: $exitCode"
        Add-Content -Path $LogFile -Value "[AVISO] Falha: $Name ($Id), código $exitCode"

        if (Get-Command Write-DevKitEvent -ErrorAction SilentlyContinue) {
            Write-DevKitEvent -Event "package_install_failed" -Level "warning" -Data @{
                package = $Id
                code    = $exitCode
            }
        }

        return
    }

    Write-Host "[OK] $Name instalado." -ForegroundColor Green

    if (Get-Command Write-DevKitEvent -ErrorAction SilentlyContinue) {
        Write-DevKitEvent -Event "package_installed" -Data @{
            package = $Id
            manager = "winget"
        }
    }
}

if (-not $DryRun -and -not (Test-Administrator)) {
    Write-Host "Abra o CMD/PowerShell como Administrador e execute novamente." -ForegroundColor Yellow
    exit 1
}

"" | Set-Content -Path $LogFile
Add-Content -Path $LogFile -Value "Início: $(Get-Date -Format o)"

if (-not $DryRun -and (Get-Command Initialize-DevKitState -ErrorAction SilentlyContinue)) {
    Initialize-DevKitState -Platform "windows"
    Add-DevKitProfile -Profile $Profile
    Write-DevKitEvent -Event "setup_started" -Data @{ profile = $Profile }
}

Write-Step "Verificando winget"

if (-not $DryRun) {
    if (-not (Test-Winget)) {
        Write-Host "winget não foi encontrado." -ForegroundColor Red
        Write-Host "Instale/atualize o App Installer pela Microsoft Store e tente novamente."
        exit 1
    }

    winget source update | Tee-Object -FilePath $LogFile -Append
}
else {
    Write-Host "[DRY-RUN] Nenhuma alteração será feita." -ForegroundColor Yellow
}

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

foreach ($id in $CustomPackages) {
    if ($id) {
        $profilePackages += @{ Id = $id; Name = $id }
    }
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

    if ($DryRun) {
        Write-Host "[DRY-RUN] Verificar/habilitar WSL"
    }
    else {
        $wslPreexisting = $false

        try {
            wsl --status *> $null
            $wslPreexisting = ($LASTEXITCODE -eq 0)
        }
        catch {
            $wslPreexisting = $false
        }

        $wslPresentAfter = $wslPreexisting

        if ($wslPreexisting) {
            Write-Host "[OK] WSL já está disponível." -ForegroundColor Green
        }
        else {
            Write-Host "Habilitando WSL. O Windows poderá solicitar reinicialização."
            wsl --install --no-distribution
            $wslPresentAfter = ($LASTEXITCODE -eq 0)
        }

        if (Get-Command Register-DevKitFeature -ErrorAction SilentlyContinue) {
            Register-DevKitFeature -Name "WSL" -Preexisting $wslPreexisting -PresentAfter $wslPresentAfter
        }
    }
}

if ($Docker) {
    Write-Step "Instalando Docker Desktop"
    Install-WingetPackage -Id "Docker.DockerDesktop" -Name "Docker Desktop"
}

if ($GitName -or $GitEmail) {
    Write-Step "Configurando Git"

    if ($DryRun) {
        if ($GitName) { Write-Host "[DRY-RUN] git config --global user.name \"$GitName\"" }
        if ($GitEmail) { Write-Host "[DRY-RUN] git config --global user.email \"$GitEmail\"" }
        Write-Host "[DRY-RUN] git config --global init.defaultBranch main"
    }
    else {
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
}

Write-Step "Resumo"

Write-Host "Perfil: $Profile"

if ($DryRun) {
    Write-Host "Dry-run concluído. Nenhuma alteração foi feita."
}
else {
    Write-Host "Instalação concluída."

    if (Get-Command Write-DevKitEvent -ErrorAction SilentlyContinue) {
        Write-DevKitEvent -Event "setup_completed" -Data @{ profile = $Profile }
    }

    if (Get-Command Get-DevKitState -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Manifesto local:"
        Write-Host "  $script:DevKitManifestPath"
    }
}

Write-Host ""
Write-Host "Feche e abra novamente o terminal para atualizar o PATH."
Write-Host "Depois, execute:"
Write-Host "  diagnostics\dev-doctor.cmd"
Write-Host "ou:"
Write-Host "  .\diagnostics\dev-doctor.ps1"
Write-Host ""
Write-Host "Log simples:"
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
