#requires -Version 5.1

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$reportDir = Join-Path $root "reports"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $reportDir "windows-inventory-$stamp.txt"

New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("SUPER DEV KIT - INVENTORY")
$lines.Add("Gerado em: $(Get-Date -Format o)")
$lines.Add("")
$lines.Add("=== SISTEMA ===")
$lines.Add("Windows: $([Environment]::OSVersion.VersionString)")
$lines.Add("Host: $env:COMPUTERNAME")
$lines.Add("")
$lines.Add("=== FERRAMENTAS ===")

$tools = @("git","node","npm","python","docker","code","gh","wsl")

foreach ($tool in $tools) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue

    if (-not $cmd) {
        $lines.Add("[$tool] não encontrado")
        continue
    }

    try {
        $version = switch ($tool) {
            "git" { git --version }
            "node" { node --version }
            "npm" { npm --version }
            "python" { python --version }
            "docker" { docker --version }
            "code" { (code --version | Select-Object -First 1) }
            "gh" { (gh --version | Select-Object -First 1) }
            "wsl" { (wsl --version 2>$null | Select-Object -First 1) }
        }

        $lines.Add("[$tool] $version")
    }
    catch {
        $lines.Add("[$tool] encontrado, versão não detectada")
    }
}

$lines.Add("")
$lines.Add("=== DOCKER COMPOSE ===")

try {
    $lines.Add((docker compose version 2>$null | Out-String).Trim())
}
catch {
    $lines.Add("Docker Compose não detectado.")
}

$lines.Add("")
$lines.Add("=== VS CODE EXTENSIONS ===")

try {
    foreach ($extension in (code --list-extensions 2>$null)) {
        $lines.Add($extension)
    }
}
catch {
    $lines.Add("VS Code CLI não disponível.")
}

$lines | Set-Content -Path $out -Encoding UTF8

Write-Host "[OK] Inventário salvo em:" -ForegroundColor Green
Write-Host "     $out"
