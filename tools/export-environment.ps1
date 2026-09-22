#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$OutputPath = ".\.super-dev-kit\devkit.lock.json",
    [string]$ConfigPath = ".\config\devkit.config.json"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$manifestPath = Join-Path $root ".super-dev-kit\manifest.json"
$versionPath = Join-Path $root "VERSION"

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $root $OutputPath
}

if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path $root $ConfigPath
}

if (-not (Test-Path $manifestPath)) {
    Write-Host "Manifesto não encontrado: $manifestPath" -ForegroundColor Yellow
    Write-Host "Execute uma instalação do Super Dev Kit antes de exportar."
    exit 1
}

$state = Get-Content $manifestPath -Raw | ConvertFrom-Json
$devKitVersion = if (Test-Path $versionPath) { (Get-Content $versionPath -Raw).Trim() } else { "dev" }

$desired = @{}
if (Test-Path $ConfigPath) {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    if ($config.runtime_versions) {
        foreach ($property in $config.runtime_versions.PSObject.Properties) {
            if ($property.Value) {
                $desired[$property.Name] = [string]$property.Value
            }
        }
    }
}

function Get-VersionNumber {
    param([string]$Text)

    $match = [regex]::Match($Text, '\d+(?:\.\d+){0,3}')
    if ($match.Success) { return $match.Value }
    return ""
}

function Get-RuntimeVersion {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [switch]$Stderr
    )

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        return ""
    }

    try {
        if ($Stderr) {
            return Get-VersionNumber -Text ((& $Command @Arguments 2>&1 | Out-String).Trim())
        }

        return Get-VersionNumber -Text ((& $Command @Arguments | Out-String).Trim())
    }
    catch {
        return ""
    }
}

function Get-DefaultConstraint {
    param(
        [string]$Runtime,
        [string]$Actual
    )

    if (-not $Actual) { return "" }

    $parts = $Actual.Split('.')

    switch ($Runtime) {
        "python" {
            if ($parts.Count -ge 2) { return "$($parts[0]).$($parts[1])" }
        }
        "php" {
            if ($parts.Count -ge 2) { return "$($parts[0]).$($parts[1])" }
        }
        default {
            return "major:$($parts[0])"
        }
    }

    return "major:$($parts[0])"
}

$runtimeSpecs = [ordered]@{
    node   = @{ Command = "node";   Args = @("--version"); Stderr = $false }
    python = @{ Command = "python"; Args = @("--version"); Stderr = $false }
    dotnet = @{ Command = "dotnet"; Args = @("--version"); Stderr = $false }
    java   = @{ Command = "java";   Args = @("-version");  Stderr = $true }
    php    = @{ Command = "php";    Args = @("--version"); Stderr = $false }
}

$runtimes = [ordered]@{}

foreach ($name in $runtimeSpecs.Keys) {
    $spec = $runtimeSpecs[$name]
    $actual = Get-RuntimeVersion -Command $spec.Command -Arguments $spec.Args -Stderr:$spec.Stderr

    if (-not $actual) {
        continue
    }

    $constraint = if ($desired.ContainsKey($name)) {
        [string]$desired[$name]
    }
    else {
        Get-DefaultConstraint -Runtime $name -Actual $actual
    }

    $runtimes[$name] = [ordered]@{
        actual     = $actual
        constraint = $constraint
    }
}

$packages = @(
    $state.packages |
        Where-Object {
            $_.manager -eq "winget" -and
            $_.installed_by_devkit -eq $true -and
            $_.present -eq $true
        } |
        ForEach-Object { [string]$_.id } |
        Sort-Object -Unique
)

$extensions = @(
    $state.vscode_extensions |
        Where-Object {
            $_.installed_by_devkit -eq $true -and
            $_.present -eq $true
        } |
        ForEach-Object { [string]$_.id } |
        Sort-Object -Unique
)

$lock = [ordered]@{
    schema_version    = 1
    generated_at      = (Get-Date).ToUniversalTime().ToString("o")
    devkit_version    = $devKitVersion
    source_platform   = "windows"
    profiles          = @($state.profiles)
    stacks            = @($state.stacks)
    modules           = @($state.modules)
    runtime_versions  = $runtimes
    packages          = [ordered]@{
        windows = $packages
        linux   = @()
    }
    vscode_extensions = $extensions
}

$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

$lock | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

Write-Host "[OK] Ambiente exportado:" -ForegroundColor Green
Write-Host "     $OutputPath"
Write-Host ""
Write-Host "O lock file não contém senhas, tokens, chaves privadas ou conteúdo de certificados."
