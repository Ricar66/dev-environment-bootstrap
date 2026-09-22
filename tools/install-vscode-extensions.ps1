#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet("Essential", "Frontend", "Backend", "FullStack", "DataSQL", "DevOps")]
    [string]$Profile = "Essential",

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$codeAvailable = [bool](Get-Command code -ErrorAction SilentlyContinue)

if (-not $DryRun -and -not $codeAvailable) {
    Write-Host "VS Code CLI ('code') não encontrado no PATH." -ForegroundColor Yellow
    Write-Host "Abra o VS Code uma vez ou reabra o terminal após a instalação."
    exit 1
}

$base = @(
    "EditorConfig.EditorConfig",
    "GitHub.vscode-pull-request-github"
)

$frontend = @(
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss"
)

$backend = @(
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-azuretools.vscode-docker",
    "humao.rest-client"
)

$dataSql = @(
    "ms-python.python",
    "ms-python.vscode-pylance",
    "mtxr.sqltools",
    "mtxr.sqltools-driver-mysql",
    "mtxr.sqltools-driver-pg"
)

$devOps = @(
    "ms-azuretools.vscode-docker",
    "redhat.vscode-yaml",
    "ms-vscode-remote.remote-ssh"
)

$extensions = @($base)

switch ($Profile) {
    "Frontend" { $extensions += $frontend }
    "Backend" { $extensions += $backend }
    "FullStack" { $extensions += $frontend + $backend }
    "DataSQL" { $extensions += $dataSql }
    "DevOps" { $extensions += $devOps }
}

$extensions = $extensions | Sort-Object -Unique
$installed = @()

if ($codeAvailable) {
    $installed = @(code --list-extensions 2>$null)
}

Write-Host "Perfil: $Profile" -ForegroundColor Cyan
Write-Host "Extensões planejadas: $($extensions.Count)"

foreach ($extension in $extensions) {
    if ($installed -contains $extension) {
        Write-Host "[OK] $extension já instalada." -ForegroundColor Green
        continue
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] code --install-extension $extension"
        continue
    }

    Write-Host "[INSTALANDO] $extension"
    code --install-extension $extension --force
}

Write-Host ""
Write-Host "Concluído."
