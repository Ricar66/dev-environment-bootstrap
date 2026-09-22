#requires -Version 5.1

$ErrorActionPreference = "Continue"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root ".super-dev-kit\manifest.json"

$script:Total = 0
$script:Passed = 0
$script:Warnings = 0
$script:Failed = 0

function Add-Check {
    param(
        [Parameter(Mandatory)][string]$Category,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet("PASS","WARN","FAIL","SKIP")][string]$Status,
        [string]$Detail = "",
        [string]$Hint = ""
    )

    if ($Status -ne "SKIP") {
        $script:Total++
    }

    switch ($Status) {
        "PASS" {
            $script:Passed++
            $color = "Green"
            $label = "[OK]"
        }
        "WARN" {
            $script:Warnings++
            $color = "Yellow"
            $label = "[AVISO]"
        }
        "FAIL" {
            $script:Failed++
            $color = "Red"
            $label = "[FALHA]"
        }
        "SKIP" {
            $color = "DarkGray"
            $label = "[SKIP]"
        }
    }

    Write-Host ("{0,-9} {1,-12} {2}" -f $label, $Category, $Name) -ForegroundColor $color

    if ($Detail) {
        Write-Host "           $Detail"
    }

    if ($Hint -and $Status -in @("WARN","FAIL")) {
        Write-Host "           Sugestão: $Hint" -ForegroundColor DarkGray
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "       SUPER DEV KIT - DEV DOCTOR v2" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Windows: $([Environment]::OSVersion.VersionString)"
Write-Host "Host:    $env:COMPUTERNAME"
Write-Host ""

$drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'"
if ($drive -and $drive.FreeSpace -gt 5GB) {
    Add-Check -Category "Sistema" -Name "Espaço em disco" -Status "PASS" -Detail ("{0:N1} GB livres" -f ($drive.FreeSpace / 1GB))
}
elseif ($drive) {
    Add-Check -Category "Sistema" -Name "Espaço em disco" -Status "WARN" -Detail ("{0:N1} GB livres" -f ($drive.FreeSpace / 1GB)) -Hint "Mantenha pelo menos 5 GB livres para instalações e imagens Docker."
}
else {
    Add-Check -Category "Sistema" -Name "Espaço em disco" -Status "WARN" -Detail "Não foi possível consultar o disco."
}

foreach ($tool in @("winget","git","curl")) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue

    if ($cmd) {
        Add-Check -Category "Core" -Name $tool -Status "PASS" -Detail $cmd.Source
    }
    else {
        Add-Check -Category "Core" -Name $tool -Status "FAIL" -Hint "Instale ou repare a ferramenta e confirme o PATH."
    }
}

foreach ($tool in @("node","npm","python","code","gh")) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue

    if ($cmd) {
        Add-Check -Category "Runtime" -Name $tool -Status "PASS" -Detail $cmd.Source
    }
    else {
        Add-Check -Category "Runtime" -Name $tool -Status "SKIP" -Detail "Não instalado neste ambiente."
    }
}

$docker = Get-Command docker -ErrorAction SilentlyContinue

if ($docker) {
    try {
        docker info *> $null

        if ($LASTEXITCODE -eq 0) {
            Add-Check -Category "Docker" -Name "Daemon" -Status "PASS"
        }
        else {
            Add-Check -Category "Docker" -Name "Daemon" -Status "FAIL" -Hint "Abra o Docker Desktop e tente novamente."
        }
    }
    catch {
        Add-Check -Category "Docker" -Name "Daemon" -Status "FAIL" -Hint "Abra o Docker Desktop e tente novamente."
    }

    try {
        $compose = docker compose version 2>$null

        if ($LASTEXITCODE -eq 0) {
            Add-Check -Category "Docker" -Name "Compose" -Status "PASS" -Detail (($compose | Out-String).Trim())
        }
        else {
            Add-Check -Category "Docker" -Name "Compose" -Status "WARN" -Hint "Verifique a instalação do Docker Compose."
        }
    }
    catch {
        Add-Check -Category "Docker" -Name "Compose" -Status "WARN" -Hint "Verifique a instalação do Docker Compose."
    }
}
else {
    Add-Check -Category "Docker" -Name "Docker CLI" -Status "SKIP" -Detail "Docker não está instalado."
}

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    try {
        wsl --status *> $null

        if ($LASTEXITCODE -eq 0) {
            Add-Check -Category "WSL" -Name "Status" -Status "PASS"
        }
        else {
            Add-Check -Category "WSL" -Name "Status" -Status "WARN" -Hint "Execute 'wsl --status' e verifique se falta reiniciar o Windows."
        }
    }
    catch {
        Add-Check -Category "WSL" -Name "Status" -Status "WARN" -Hint "Verifique os recursos de virtualização do Windows."
    }
}
else {
    Add-Check -Category "WSL" -Name "Disponibilidade" -Status "SKIP" -Detail "WSL não instalado."
}

try {
    Resolve-DnsName registry-1.docker.io -ErrorAction Stop | Out-Null
    Add-Check -Category "Rede" -Name "DNS Docker Hub" -Status "PASS"
}
catch {
    Add-Check -Category "Rede" -Name "DNS Docker Hub" -Status "FAIL" -Hint "Verifique DNS, VPN, proxy ou firewall."
}

try {
    $response = Invoke-WebRequest -Uri "https://registry-1.docker.io/v2/" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Add-Check -Category "Rede" -Name "TLS/HTTPS" -Status "PASS" -Detail "HTTP $($response.StatusCode)"
}
catch {
    if ($_.Exception.Response) {
        Add-Check -Category "Rede" -Name "TLS/HTTPS" -Status "PASS" -Detail "Registry respondeu; autenticação pode ser exigida."
    }
    else {
        Add-Check -Category "Rede" -Name "TLS/HTTPS" -Status "FAIL" -Hint "Verifique proxy/certificado corporativo com o guia CERTIFICADOS-CORPORATIVOS.md."
    }
}

if (Test-Path $manifestPath) {
    try {
        $state = Get-Content $manifestPath -Raw | ConvertFrom-Json

        if ($state.schema_version -in @(1, 2)) {
            Add-Check -Category "Estado" -Name "Manifesto" -Status "PASS" -Detail "schema=$($state.schema_version) | $manifestPath"
        }
        else {
            Add-Check -Category "Estado" -Name "Manifesto" -Status "WARN" -Detail "Schema desconhecido: $($state.schema_version)"
        }

        $missingOwned = @()

        foreach ($package in @($state.packages | Where-Object { $_.installed_by_devkit -eq $true -and $_.present -eq $true -and $_.manager -eq "winget" })) {
            $result = winget list --id $package.id -e --accept-source-agreements 2>$null | Out-String
            if ($result -notmatch [regex]::Escape($package.id)) {
                $missingOwned += $package.id
            }
        }

        if ($missingOwned.Count -eq 0) {
            Add-Check -Category "Estado" -Name "Drift de pacotes" -Status "PASS" -Detail "Nenhum pacote gerenciado desapareceu."
        }
        else {
            Add-Check -Category "Estado" -Name "Drift de pacotes" -Status "WARN" -Detail ($missingOwned -join ", ") -Hint "Execute novamente o perfil/stack ou atualize o manifesto."
        }
    }
    catch {
        Add-Check -Category "Estado" -Name "Manifesto" -Status "FAIL" -Detail $_.Exception.Message -Hint "Revise .super-dev-kit\manifest.json."
    }
}
else {
    Add-Check -Category "Estado" -Name "Manifesto" -Status "SKIP" -Detail "Ainda não criado; execute uma instalação v0.4+."
}

$score = if ($script:Total -gt 0) {
    [math]::Round(($script:Passed / $script:Total) * 100)
}
else {
    0
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Resumo" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Score:    $score%"
Write-Host "Checks:   $script:Total"
Write-Host "OK:       $script:Passed" -ForegroundColor Green
Write-Host "Avisos:   $script:Warnings" -ForegroundColor Yellow
Write-Host "Falhas:   $script:Failed" -ForegroundColor Red

if ($script:Failed -eq 0 -and $script:Warnings -eq 0) {
    Write-Host ""
    Write-Host "Ambiente saudável para os checks aplicáveis." -ForegroundColor Green
}
elseif ($script:Failed -eq 0) {
    Write-Host ""
    Write-Host "Ambiente utilizável, com pontos de atenção." -ForegroundColor Yellow
}
else {
    Write-Host ""
    Write-Host "Há falhas que merecem correção antes de continuar." -ForegroundColor Red
}
