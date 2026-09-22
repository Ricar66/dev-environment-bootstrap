#requires -Version 5.1

$tools = @("git", "node", "npm", "docker", "code", "gh", "curl", "wsl")

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "          SUPER DEV KIT - DOCTOR" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Windows: $([Environment]::OSVersion.VersionString)"
Write-Host "Host: $env:COMPUTERNAME"
Write-Host ""

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

if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        docker info *> $null
        Write-Host "[OK] Docker daemon acessível." -ForegroundColor Green
    }
    catch {
        Write-Host "[AVISO] Docker instalado, mas o daemon não respondeu." -ForegroundColor Yellow
    }
}

try {
    $response = Invoke-WebRequest -Uri "https://registry-1.docker.io/v2/" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "[OK] HTTPS do Docker Hub respondeu ($($response.StatusCode))." -ForegroundColor Green
}
catch {
    if ($_.Exception.Response) {
        Write-Host "[OK] HTTPS do Docker Hub respondeu; autenticação pode ser exigida." -ForegroundColor Green
    }
    else {
        Write-Host "[AVISO] Falha ao acessar Docker Hub via HTTPS." -ForegroundColor Yellow
        Write-Host "        Verifique rede, proxy e certificados corporativos."
    }
}
