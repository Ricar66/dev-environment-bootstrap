#requires -Version 5.1

$tools = @(
    "winget",
    "git",
    "node",
    "npm",
    "python",
    "docker",
    "code",
    "gh",
    "curl",
    "wsl"
)

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "          SUPER DEV KIT - DEV DOCTOR" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Windows: $([Environment]::OSVersion.VersionString)"
Write-Host "Host: $env:COMPUTERNAME"
Write-Host ""

Write-Host "--- Ferramentas ---" -ForegroundColor Cyan

foreach ($tool in $tools) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue

    if ($cmd) {
        Write-Host "[OK]    $tool -> $($cmd.Source)" -ForegroundColor Green
    }
    else {
        Write-Host "[AVISO] $tool não encontrado" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "--- Docker ---" -ForegroundColor Cyan

if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        docker info *> $null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Docker daemon acessível." -ForegroundColor Green
        }
        else {
            Write-Host "[AVISO] Docker instalado, mas o daemon não respondeu." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[AVISO] Docker instalado, mas o daemon não respondeu." -ForegroundColor Yellow
    }

    try {
        $compose = docker compose version 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] $compose" -ForegroundColor Green
        }
        else {
            Write-Host "[AVISO] Docker Compose não respondeu." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[AVISO] Docker Compose não respondeu." -ForegroundColor Yellow
    }
}
else {
    Write-Host "[AVISO] Docker não encontrado." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "--- WSL ---" -ForegroundColor Cyan

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    try {
        wsl --status
    }
    catch {
        Write-Host "[AVISO] WSL existe, mas o status não pôde ser consultado." -ForegroundColor Yellow
    }
}
else {
    Write-Host "[AVISO] WSL não encontrado." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "--- HTTPS / Docker Hub ---" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "https://registry-1.docker.io/v2/" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "[OK] HTTPS respondeu ($($response.StatusCode))." -ForegroundColor Green
}
catch {
    if ($_.Exception.Response) {
        Write-Host "[OK] HTTPS respondeu; autenticação pode ser exigida." -ForegroundColor Green
    }
    else {
        Write-Host "[AVISO] Falha ao acessar Docker Hub via HTTPS." -ForegroundColor Yellow
        Write-Host "        Verifique rede, proxy e certificados corporativos."
        Write-Host "        Para exportar uma CA confiável:"
        Write-Host '        .\certificates\export-root-ca.ps1 -Search "nome-do-emissor"'
    }
}

Write-Host ""
Write-Host "Diagnóstico concluído."
