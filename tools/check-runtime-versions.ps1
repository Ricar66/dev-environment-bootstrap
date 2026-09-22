#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ConfigPath = ".\config\devkit.config.json",
    [string]$Preset,
    [switch]$UpdateManifest
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$catalogPath = Join-Path $root "versions\catalog.json"
$presetsPath = Join-Path $root "versions\presets.json"
$stateHelper = Join-Path $root "tools\state.ps1"

if (Test-Path $stateHelper) {
    . $stateHelper
}

function ConvertTo-VersionTuple {
    param([Parameter(Mandatory)][string]$VersionText)

    $match = [regex]::Match($VersionText, '\d+(?:\.\d+){0,3}')

    if (-not $match.Success) {
        return $null
    }

    return @($match.Value.Split('.') | ForEach-Object { [int]$_ })
}

function Compare-VersionTuple {
    param(
        [Parameter(Mandatory)][int[]]$Left,
        [Parameter(Mandatory)][int[]]$Right
    )

    $length = [math]::Max($Left.Count, $Right.Count)

    for ($i = 0; $i -lt $length; $i++) {
        $a = if ($i -lt $Left.Count) { $Left[$i] } else { 0 }
        $b = if ($i -lt $Right.Count) { $Right[$i] } else { 0 }

        if ($a -lt $b) { return -1 }
        if ($a -gt $b) { return 1 }
    }

    return 0
}

function Test-VersionConstraint {
    param(
        [Parameter(Mandatory)][string]$Actual,
        [Parameter(Mandatory)][string]$Constraint
    )

    $actualTuple = ConvertTo-VersionTuple -VersionText $Actual

    if (-not $actualTuple) {
        return $false
    }

    if ($Constraint -match '^major:(\d+)$') {
        return $actualTuple[0] -eq [int]$Matches[1]
    }

    if ($Constraint -match '^>=(\d+(?:\.\d+){0,3})$') {
        $targetTuple = ConvertTo-VersionTuple -VersionText $Matches[1]
        return (Compare-VersionTuple -Left $actualTuple -Right $targetTuple) -ge 0
    }

    if ($Constraint -match '^\d+(?:\.\d+){0,3}$') {
        $actualNormalized = ($actualTuple -join '.')
        return $actualNormalized -eq $Constraint -or $actualNormalized.StartsWith("$Constraint.")
    }

    return $false
}

$catalog = Get-Content $catalogPath -Raw | ConvertFrom-Json
$desired = [ordered]@{}

if ($Preset) {
    $presets = Get-Content $presetsPath -Raw | ConvertFrom-Json
    $presetData = $presets.presets.PSObject.Properties[$Preset].Value

    if (-not $presetData) {
        throw "Preset de versões não encontrado: $Preset"
    }

    foreach ($property in $presetData.runtime_versions.PSObject.Properties) {
        $desired[$property.Name] = [string]$property.Value
    }
}
else {
    if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
        $ConfigPath = Join-Path $root $ConfigPath
    }

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Configuração não encontrada: $ConfigPath" -ForegroundColor Yellow
        exit 1
    }

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

    if ($config.runtime_versions) {
        foreach ($property in $config.runtime_versions.PSObject.Properties) {
            if ($property.Value) {
                $desired[$property.Name] = [string]$property.Value
            }
        }
    }
}

if ($desired.Count -eq 0) {
    Write-Host "Nenhuma restrição de runtime configurada."
    exit 0
}

$failures = 0

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "      SUPER DEV KIT - RUNTIME VERSION CHECK" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($runtimeName in $desired.Keys) {
    $runtime = $catalog.runtimes.PSObject.Properties[$runtimeName].Value

    if (-not $runtime) {
        Write-Host "[AVISO] Runtime desconhecido no config: $runtimeName" -ForegroundColor Yellow
        $failures++
        continue
    }

    $commandName = [string]$runtime.windows_command
    $command = Get-Command $commandName -ErrorAction SilentlyContinue
    $constraint = [string]$desired[$runtimeName]

    if (-not $command) {
        Write-Host "[FALHA] $($runtime.name): não encontrado; esperado $constraint" -ForegroundColor Red
        $failures++
        continue
    }

    $args = @($runtime.version_args)
    $output = ""

    if ($runtime.stderr_version -eq $true) {
        $output = (& $commandName @args 2>&1 | Out-String).Trim()
    }
    else {
        $output = (& $commandName @args | Out-String).Trim()
    }

    $tuple = ConvertTo-VersionTuple -VersionText $output
    $actual = if ($tuple) { $tuple -join '.' } else { $output }
    $ok = Test-VersionConstraint -Actual $actual -Constraint $constraint

    if ($ok) {
        Write-Host "[OK]    $($runtime.name): $actual atende $constraint" -ForegroundColor Green
    }
    else {
        Write-Host "[FALHA] $($runtime.name): $actual não atende $constraint" -ForegroundColor Red
        $failures++
    }

    if ($UpdateManifest -and (Get-Command Register-DevKitRuntimeVersion -ErrorAction SilentlyContinue)) {
        Register-DevKitRuntimeVersion -Runtime $runtimeName -Desired $constraint -Actual $actual -Policy "constraint"
    }
}

Write-Host ""
if ($failures -eq 0) {
    Write-Host "[OK] Todas as restrições configuradas foram atendidas." -ForegroundColor Green
    exit 0
}

Write-Host "$failures runtime(s) fora da política desejada." -ForegroundColor Red
exit 2
