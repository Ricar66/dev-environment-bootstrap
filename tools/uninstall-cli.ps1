#requires -Version 5.1

$ErrorActionPreference = "Stop"

$binDir = Join-Path $env:LOCALAPPDATA "SuperDevKit\bin"
$shim = Join-Path $binDir "devkit.cmd"
$deleteScheduled = $false

if (Test-Path $shim) {
    $content = Get-Content $shim -Raw

    if ($content -notmatch "Super Dev Kit shim") {
        throw "O arquivo existente não parece ser gerenciado pelo Super Dev Kit: $shim"
    }

    # Um .cmd não deve apagar a si próprio enquanto o cmd.exe ainda precisa ler
    # as próximas linhas do arquivo. A remoção é feita por um processo curto e
    # independente depois que o comando global termina.
    $escapedShim = $shim.Replace("'", "''")
    $deleteCommand = "Start-Sleep -Milliseconds 750; Remove-Item -LiteralPath '$escapedShim' -Force -ErrorAction SilentlyContinue"

    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command", $deleteCommand
    ) | Out-Null

    $deleteScheduled = $true
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

if ($deleteScheduled) {
    Write-Host "[OK] Remoção do shim global agendada." -ForegroundColor Green
}
else {
    Write-Host "[OK] Nenhum shim global ativo precisava ser removido." -ForegroundColor Green
}

if ($pathChanged) {
    Write-Host "O PATH do usuário foi atualizado. Abra um novo terminal."
}
