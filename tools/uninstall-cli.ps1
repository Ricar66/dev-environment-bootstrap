#requires -Version 5.1

$ErrorActionPreference = "Stop"

$binDir = Join-Path $env:LOCALAPPDATA "SuperDevKit\bin"
$shim = Join-Path $binDir "devkit.cmd"

if (Test-Path $shim) {
    $content = Get-Content $shim -Raw

    if ($content -notmatch "Super Dev Kit shim") {
        throw "O arquivo existente não parece ser gerenciado pelo Super Dev Kit: $shim"
    }

    Remove-Item $shim -Force
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathChanged = $false

if ($userPath) {
    $parts = @(
        $userPath.Split(';') |
            Where-Object { $_ -and $_ -ne $binDir }
    )

    $newPath = $parts -join ';'

    if ($newPath -ne $userPath) {
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $pathChanged = $true
    }
}

if ((Test-Path $binDir) -and -not (Get-ChildItem $binDir -Force -ErrorAction SilentlyContinue)) {
    Remove-Item $binDir -Force
}

Write-Host "[OK] Shim global removido." -ForegroundColor Green

if ($pathChanged) {
    Write-Host "O PATH do usuário foi atualizado. Abra um novo terminal."
}
