#requires -Version 5.1

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$versionFile = Join-Path $root "VERSION"
$commandsFile = Join-Path $root "cli\commands.json"

$exitUsage = 64
$exitUnavailable = 69
$exitInternal = 70

function Get-DevKitVersion {
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw).Trim()
    }

    return "dev"
}

function Write-JsonEnvelope {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][int]$ExitCode,
        [object]$Data,
        [string[]]$Output = @()
    )

    $payload = [ordered]@{
        schema_version = 1
        command        = $Command
        success        = ($ExitCode -eq 0)
        exit_code      = $ExitCode
        timestamp      = (Get-Date).ToUniversalTime().ToString("o")
    }

    if ($null -ne $Data) {
        $payload.data = $Data
    }

    if ($Output.Count -gt 0) {
        $payload.output = @($Output)
    }

    $payload | ConvertTo-Json -Depth 20
}

function Stop-Usage {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "Erro: $Message" -ForegroundColor Red
    Write-Host "Use 'devkit help' para ver os comandos."
    exit $exitUsage
}

function Show-Help {
    param([string]$Topic = "")

    switch ($Topic.ToLowerInvariant()) {
        "setup" {
            @"
Uso:
  devkit setup [perfil] [--dry-run] [--docker] [--wsl] [--extras] [--all]

Perfis:
  essential | frontend | backend | fullstack | datasql | devops
"@
        }
        "stack" {
            @"
Uso:
  devkit stack <nome> [--dry-run] [--skip-extensions]
"@
        }
        "project" {
            @"
Uso:
  devkit project list
  devkit project <template> <nome> [--output PASTA] [--dry-run]
                 [--force] [--with-devcontainer] [--install-deps]
"@
        }
        "runtime" {
            @"
Uso:
  devkit runtime list
  devkit runtime <runtime> <versao> [--manager auto] [--dry-run]

Runtimes:
  node | python | dotnet | java | php
"@
        }
        "import" {
            @"
Uso:
  devkit import [--lock ARQUIVO] [--dry-run] [--skip-extensions]
"@
        }
        "compare" {
            @"
Uso:
  devkit compare [--lock ARQUIVO]
"@
        }
        "backup" {
            @"
Uso:
  devkit backup <vscode|git>
"@
        }
        "cleanup" {
            @"
Uso:
  devkit cleanup [--apply] [--include-core] [--include-docker]
                 [--extensions-only] [--packages-only]
"@
        }
        "cli" {
            @"
Uso:
  devkit cli install
  devkit cli uninstall
  devkit cli status
"@
        }
        default {
            @"
Super Dev Kit CLI v$(Get-DevKitVersion)

Uso:
  devkit <comando> [opcoes]
  devkit <comando> [opcoes] --json

Comandos:
  setup       Prepara a maquina por perfil
  doctor      Executa o Dev Doctor
  stack       Instala uma stack
  project     Lista ou gera projeto por template
  runtime     Usa adapters de version manager
  state       Mostra o manifesto local
  export      Exporta o ambiente para lock file
  import      Importa um lock file
  compare     Compara lock x maquina
  backup      Backup de VS Code ou Git
  inventory   Gera inventario
  cleanup     Cleanup controlado
  update      Atualiza o Super Dev Kit
  version     Mostra a versao
  commands    Lista os comandos
  cli         Instala/remove o comando global

Globais:
  --json      Emite envelope JSON quando suportado
  -h, --help  Mostra ajuda

Codigos de saida:
  0   sucesso
  1   falha operacional da ferramenta delegada
  2   drift/diferenca/politica nao atendida
  64  uso invalido da CLI
  69  dependencia ou recurso indisponivel
  70  erro interno da CLI
"@
        }
    }
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory)][string]$CommandName,
        [Parameter(Mandatory)][string]$Path,
        [string[]]$ToolArgs = @(),
        [switch]$Json
    )

    if (-not (Test-Path $Path)) {
        if ($Json) {
            Write-JsonEnvelope -Command $CommandName -ExitCode $exitUnavailable -Data @{
                error = "Ferramenta nao encontrada."
                path  = $Path
            }
        }
        else {
            Write-Host "Ferramenta nao encontrada: $Path" -ForegroundColor Red
        }

        return $exitUnavailable
    }

    try {
        if ($Json) {
            $captured = @(
                & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Path @ToolArgs 2>&1 |
                    ForEach-Object { $_.ToString() }
            )
            $code = $LASTEXITCODE

            Write-JsonEnvelope -Command $CommandName -ExitCode $code -Data @{
                delegated_to = $Path
                arguments    = @($ToolArgs)
            } -Output $captured

            return $code
        }

        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Path @ToolArgs
        return $LASTEXITCODE
    }
    catch {
        if ($Json) {
            Write-JsonEnvelope -Command $CommandName -ExitCode $exitInternal -Data @{
                error = $_.Exception.Message
            }
        }
        else {
            Write-Host "Erro interno da CLI: $($_.Exception.Message)" -ForegroundColor Red
        }

        return $exitInternal
    }
}

function Require-NoArguments {
    param([string[]]$Items, [string]$CommandName)

    if ($Items.Count -gt 0) {
        Stop-Usage "O comando '$CommandName' nao aceita estes argumentos: $($Items -join ' ')"
    }
}

[string[]]$cliArgs = @($args)
$json = $false
$filtered = New-Object System.Collections.Generic.List[string]

foreach ($item in $cliArgs) {
    if ($item -eq "--json") {
        $json = $true
    }
    else {
        $filtered.Add([string]$item)
    }
}

$cliArgs = @($filtered)

if ($cliArgs.Count -eq 0) {
    Show-Help
    exit 0
}

if ($cliArgs[0] -in @("-h", "--help")) {
    Show-Help
    exit 0
}

if ($cliArgs[0] -eq "--version") {
    $cliArgs = @("version")
}

$command = $cliArgs[0].ToLowerInvariant()
$rest = @()
if ($cliArgs.Count -gt 1) {
    $rest = @($cliArgs[1..($cliArgs.Count - 1)])
}

if ($command -eq "help") {
    $topic = if ($rest.Count -gt 0) { $rest[0] } else { "" }
    Show-Help -Topic $topic
    exit 0
}

if ($command -eq "version") {
    Require-NoArguments -Items $rest -CommandName "version"
    $version = Get-DevKitVersion

    if ($json) {
        Write-JsonEnvelope -Command "version" -ExitCode 0 -Data @{
            version  = $version
            platform = "windows"
        }
    }
    else {
        Write-Output $version
    }

    exit 0
}

if ($command -eq "commands") {
    Require-NoArguments -Items $rest -CommandName "commands"

    if (-not (Test-Path $commandsFile)) {
        Write-Host "Contrato de comandos nao encontrado: $commandsFile" -ForegroundColor Red
        exit $exitUnavailable
    }

    $data = Get-Content $commandsFile -Raw | ConvertFrom-Json

    if ($json) {
        Write-JsonEnvelope -Command "commands" -ExitCode 0 -Data $data
    }
    else {
        foreach ($property in $data.commands.PSObject.Properties) {
            Write-Host ("{0,-12} {1}" -f $property.Name, $property.Value)
        }
    }

    exit 0
}

if ($command -eq "state" -and $json) {
    Require-NoArguments -Items $rest -CommandName "state"
    $manifest = Join-Path $root ".super-dev-kit\manifest.json"

    if (-not (Test-Path $manifest)) {
        Write-JsonEnvelope -Command "state" -ExitCode 1 -Data @{
            error = "Manifesto local ainda nao existe."
            path  = $manifest
        }
        exit 1
    }

    try {
        $state = Get-Content $manifest -Raw | ConvertFrom-Json
        Write-JsonEnvelope -Command "state" -ExitCode 0 -Data $state
        exit 0
    }
    catch {
        Write-JsonEnvelope -Command "state" -ExitCode $exitInternal -Data @{
            error = "Manifesto invalido: $($_.Exception.Message)"
        }
        exit $exitInternal
    }
}

$tool = ""
$toolArgs = @()

switch ($command) {
    "setup" {
        $tool = Join-Path $root "windows\setup-windows.ps1"
        $profile = "Essential"
        $profileMap = @{
            essential = "Essential"
            frontend  = "Frontend"
            backend   = "Backend"
            fullstack = "FullStack"
            datasql   = "DataSQL"
            devops    = "DevOps"
        }

        $i = 0
        $positionalProfileUsed = $false

        while ($i -lt $rest.Count) {
            $token = $rest[$i]

            switch ($token) {
                "--profile" {
                    if ($i + 1 -ge $rest.Count) { Stop-Usage "--profile exige um valor." }
                    $key = $rest[$i + 1].ToLowerInvariant()
                    if (-not $profileMap.ContainsKey($key)) { Stop-Usage "Perfil invalido: $key" }
                    $profile = $profileMap[$key]
                    $i += 2
                }
                "--dry-run" { $toolArgs += "-DryRun"; $i++ }
                "--docker" { $toolArgs += "-Docker"; $i++ }
                "--wsl" { $toolArgs += "-WSL"; $i++ }
                "--extras" { $toolArgs += "-Extras"; $i++ }
                "--all" { $toolArgs += "-All"; $i++ }
                default {
                    if ($token.StartsWith("-")) { Stop-Usage "Opcao desconhecida em setup: $token" }
                    if ($positionalProfileUsed) { Stop-Usage "Argumento inesperado em setup: $token" }
                    $key = $token.ToLowerInvariant()
                    if (-not $profileMap.ContainsKey($key)) { Stop-Usage "Perfil invalido: $key" }
                    $profile = $profileMap[$key]
                    $positionalProfileUsed = $true
                    $i++
                }
            }
        }

        $toolArgs = @("-Profile", $profile) + $toolArgs
    }

    "doctor" {
        Require-NoArguments -Items $rest -CommandName "doctor"
        $tool = Join-Path $root "diagnostics\dev-doctor.ps1"
    }

    "stack" {
        if ($rest.Count -lt 1) { Stop-Usage "Informe a stack. Ex.: devkit stack react" }
        $stack = $rest[0]
        $tool = Join-Path $root "tools\install-stack.ps1"
        $toolArgs = @("-Stack", $stack)

        foreach ($token in @($rest | Select-Object -Skip 1)) {
            switch ($token) {
                "--dry-run" { $toolArgs += "-DryRun" }
                "--skip-extensions" { $toolArgs += "-SkipExtensions" }
                default { Stop-Usage "Opcao desconhecida em stack: $token" }
            }
        }
    }

    "project" {
        $tool = Join-Path $root "tools\create-project.ps1"

        if ($rest.Count -eq 1 -and $rest[0] -eq "list") {
            $toolArgs = @("-List")
            break
        }

        if ($rest.Count -lt 2) {
            Stop-Usage "Use: devkit project <template> <nome> [opcoes]"
        }

        $toolArgs = @("-Template", $rest[0], "-Name", $rest[1])
        $i = 2

        while ($i -lt $rest.Count) {
            $token = $rest[$i]

            switch ($token) {
                "--output" {
                    if ($i + 1 -ge $rest.Count) { Stop-Usage "--output exige uma pasta." }
                    $toolArgs += @("-OutputPath", $rest[$i + 1])
                    $i += 2
                }
                "--dry-run" { $toolArgs += "-DryRun"; $i++ }
                "--force" { $toolArgs += "-Force"; $i++ }
                "--with-devcontainer" { $toolArgs += "-WithDevContainer"; $i++ }
                "--install-deps" { $toolArgs += "-InstallDependencies"; $i++ }
                default { Stop-Usage "Opcao desconhecida em project: $token" }
            }
        }
    }

    "runtime" {
        $tool = Join-Path $root "tools\runtime-manager.ps1"

        if ($rest.Count -eq 1 -and $rest[0] -eq "list") {
            $toolArgs = @("-List")
            break
        }

        if ($rest.Count -lt 2) {
            Stop-Usage "Use: devkit runtime <runtime> <versao> [--manager auto] [--dry-run]"
        }

        $toolArgs = @("-Runtime", $rest[0], "-Version", $rest[1])
        $i = 2

        while ($i -lt $rest.Count) {
            $token = $rest[$i]

            switch ($token) {
                "--manager" {
                    if ($i + 1 -ge $rest.Count) { Stop-Usage "--manager exige um valor." }
                    $toolArgs += @("-Manager", $rest[$i + 1])
                    $i += 2
                }
                "--dry-run" { $toolArgs += "-DryRun"; $i++ }
                default { Stop-Usage "Opcao desconhecida em runtime: $token" }
            }
        }
    }

    "state" {
        Require-NoArguments -Items $rest -CommandName "state"
        $tool = Join-Path $root "tools\show-state.ps1"
    }

    "export" {
        $tool = Join-Path $root "tools\export-environment.ps1"
        $i = 0

        while ($i -lt $rest.Count) {
            $token = $rest[$i]
            switch ($token) {
                "--output" {
                    if ($i + 1 -ge $rest.Count) { Stop-Usage "--output exige um arquivo." }
                    $toolArgs += @("-OutputPath", $rest[$i + 1])
                    $i += 2
                }
                "--config" {
                    if ($i + 1 -ge $rest.Count) { Stop-Usage "--config exige um arquivo." }
                    $toolArgs += @("-ConfigPath", $rest[$i + 1])
                    $i += 2
                }
                default { Stop-Usage "Opcao desconhecida em export: $token" }
            }
        }
    }

    "import" {
        $tool = Join-Path $root "tools\import-environment.ps1"
        $i = 0

        while ($i -lt $rest.Count) {
            $token = $rest[$i]
            switch ($token) {
                "--lock" {
                    if ($i + 1 -ge $rest.Count) { Stop-Usage "--lock exige um arquivo." }
                    $toolArgs += @("-LockPath", $rest[$i + 1])
                    $i += 2
                }
                "--dry-run" { $toolArgs += "-DryRun"; $i++ }
                "--skip-extensions" { $toolArgs += "-SkipExtensions"; $i++ }
                default { Stop-Usage "Opcao desconhecida em import: $token" }
            }
        }
    }

    "compare" {
        $tool = Join-Path $root "tools\compare-environment.ps1"
        $i = 0

        while ($i -lt $rest.Count) {
            $token = $rest[$i]
            switch ($token) {
                "--lock" {
                    if ($i + 1 -ge $rest.Count) { Stop-Usage "--lock exige um arquivo." }
                    $toolArgs += @("-LockPath", $rest[$i + 1])
                    $i += 2
                }
                default { Stop-Usage "Opcao desconhecida em compare: $token" }
            }
        }
    }

    "backup" {
        if ($rest.Count -ne 1) { Stop-Usage "Use: devkit backup <vscode|git>" }

        switch ($rest[0].ToLowerInvariant()) {
            "vscode" { $tool = Join-Path $root "tools\backup-vscode.ps1" }
            "git" { $tool = Join-Path $root "tools\backup-git.ps1" }
            default { Stop-Usage "Backup invalido: $($rest[0])" }
        }
    }

    "inventory" {
        Require-NoArguments -Items $rest -CommandName "inventory"
        $tool = Join-Path $root "tools\inventory.ps1"
    }

    "cleanup" {
        $tool = Join-Path $root "tools\cleanup.ps1"

        foreach ($token in $rest) {
            switch ($token) {
                "--apply" { $toolArgs += "-Apply" }
                "--include-core" { $toolArgs += "-IncludeCore" }
                "--include-docker" { $toolArgs += "-IncludeDocker" }
                "--extensions-only" { $toolArgs += "-ExtensionsOnly" }
                "--packages-only" { $toolArgs += "-PackagesOnly" }
                default { Stop-Usage "Opcao desconhecida em cleanup: $token" }
            }
        }
    }

    "update" {
        Require-NoArguments -Items $rest -CommandName "update"
        $tool = Join-Path $root "tools\update-devkit.ps1"
    }

    "cli" {
        if ($rest.Count -ne 1) { Stop-Usage "Use: devkit cli <install|uninstall|status>" }

        switch ($rest[0].ToLowerInvariant()) {
            "install" { $tool = Join-Path $root "tools\install-cli.ps1" }
            "uninstall" { $tool = Join-Path $root "tools\uninstall-cli.ps1" }
            "status" {
                $shim = Join-Path $env:LOCALAPPDATA "SuperDevKit\bin\devkit.cmd"
                $present = Test-Path $shim
                $inPath = (($env:PATH -split ';') -contains (Split-Path -Parent $shim))
                $code = if ($present) { 0 } else { 1 }

                if ($json) {
                    Write-JsonEnvelope -Command "cli status" -ExitCode $code -Data @{
                        installed = $present
                        shim      = $shim
                        in_path   = $inPath
                    }
                }
                else {
                    Write-Host "Shim: $shim"
                    Write-Host "Instalado: $present"
                    Write-Host "No PATH da sessao atual: $inPath"
                }

                exit $code
            }
            default { Stop-Usage "Acao de CLI invalida: $($rest[0])" }
        }
    }

    default {
        Stop-Usage "Comando desconhecido: $command"
    }
}

$exitCode = Invoke-Tool -CommandName $command -Path $tool -ToolArgs $toolArgs -Json:$json
exit $exitCode
