#requires -Version 5.1

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$launcher = Join-Path $root "devkit.cmd"
$binDir = Join-Path $env:LOCALAPPDATA "SuperDevKit\bin"
$shim = Join-Path $binDir "devkit.cmd"

if (-not (Test-Path $launcher)) {
    throw "Launcher raiz não encontrado: $launcher"
}

New-Item -ItemType Directory -Path $binDir -Force | Out-Null

$shimContent = @"
@echo off
rem Super Dev Kit shim - managed by devkit cli install
call "$launcher" %*
exit /b %ERRORLEVEL%
"@

Set-Content -Path $shim -Value $shimContent -Encoding ASCII

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$parts = @()

if ($userPath) {
    $parts = @($userPath.Split(';') | Where-Object { $_ })
}

if ($parts -notcontains $binDir) {
    $newPath = if ($userPath) { "$userPath;$binDir" } else { $binDir }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $pathChanged = $true
}
else {
    $pathChanged = $false
}

Write-Host "[OK] CLI instalada:" -ForegroundColor Green
Write-Host "     $shim"

if ($pathChanged) {
    Write-Host ""
    Write-Host "O diretório foi adicionado ao PATH do usuário." -ForegroundColor Cyan
    Write-Host "Abra um novo CMD/PowerShell antes de usar 'devkit' globalmente."
}
else {
    Write-Host ""
    Write-Host "O diretório já estava no PATH do usuário."
}
