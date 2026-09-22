#requires -Version 5.1

$script:DevKitRoot = Split-Path -Parent $PSScriptRoot
$script:DevKitStateDir = Join-Path $script:DevKitRoot ".super-dev-kit"
$script:DevKitManifestPath = Join-Path $script:DevKitStateDir "manifest.json"
$script:DevKitLogDir = Join-Path $script:DevKitStateDir "logs"
$script:DevKitEventLog = Join-Path $script:DevKitLogDir "events.jsonl"

function Save-DevKitState {
    param([Parameter(Mandatory)]$State)

    $State.updated_at = (Get-Date).ToUniversalTime().ToString("o")
    $State | ConvertTo-Json -Depth 10 | Set-Content -Path $script:DevKitManifestPath -Encoding UTF8
}

function Upgrade-DevKitState {
    param([Parameter(Mandatory)]$State)

    $changed = $false

    foreach ($property in @(
        @{ Name = "profiles"; Value = @() },
        @{ Name = "stacks"; Value = @() },
        @{ Name = "modules"; Value = @() },
        @{ Name = "runtime_versions"; Value = [pscustomobject]@{} },
        @{ Name = "packages"; Value = @() },
        @{ Name = "vscode_extensions"; Value = @() },
        @{ Name = "features"; Value = @() }
    )) {
        if (-not ($State.PSObject.Properties.Name -contains $property.Name)) {
            $State | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
            $changed = $true
        }
    }

    if (-not ($State.PSObject.Properties.Name -contains "schema_version") -or $State.schema_version -lt 2) {
        $State.schema_version = 2
        $changed = $true
    }

    if ($changed) {
        Save-DevKitState -State $State
    }

    return $State
}

function Initialize-DevKitState {
    param([string]$Platform = "windows")

    New-Item -ItemType Directory -Path $script:DevKitStateDir -Force | Out-Null
    New-Item -ItemType Directory -Path $script:DevKitLogDir -Force | Out-Null

    if (-not (Test-Path $script:DevKitManifestPath)) {
        $now = (Get-Date).ToUniversalTime().ToString("o")

        $state = [pscustomobject]@{
            schema_version    = 2
            platform          = $Platform
            host              = $env:COMPUTERNAME
            created_at        = $now
            updated_at        = $now
            profiles          = @()
            stacks            = @()
            modules           = @()
            runtime_versions  = [pscustomobject]@{}
            packages          = @()
            vscode_extensions = @()
            features          = @()
        }

        Save-DevKitState -State $state
        return
    }

    $state = Get-Content $script:DevKitManifestPath -Raw | ConvertFrom-Json
    [void](Upgrade-DevKitState -State $state)
}

function Get-DevKitState {
    Initialize-DevKitState
    $state = Get-Content $script:DevKitManifestPath -Raw | ConvertFrom-Json
    return (Upgrade-DevKitState -State $state)
}

function Add-DevKitProfile {
    param([Parameter(Mandatory)][string]$Profile)

    $state = Get-DevKitState
    $items = @($state.profiles)

    if ($items -notcontains $Profile) {
        $state.profiles = @($items + $Profile)
        Save-DevKitState -State $state
    }
}

function Add-DevKitStack {
    param([Parameter(Mandatory)][string]$Stack)

    $state = Get-DevKitState
    $items = @($state.stacks)

    if ($items -notcontains $Stack) {
        $state.stacks = @($items + $Stack)
        Save-DevKitState -State $state
    }
}

function Add-DevKitModule {
    param([Parameter(Mandatory)][string]$Module)

    $state = Get-DevKitState
    $items = @($state.modules)

    if ($items -notcontains $Module) {
        $state.modules = @($items + $Module)
        Save-DevKitState -State $state
    }
}

function Register-DevKitRuntimeVersion {
    param(
        [Parameter(Mandatory)][string]$Runtime,
        [string]$Desired,
        [string]$Actual,
        [string]$Policy = "informational"
    )

    $state = Get-DevKitState
    $value = [pscustomobject]@{
        desired      = $Desired
        actual       = $Actual
        policy       = $Policy
        last_seen_at = (Get-Date).ToUniversalTime().ToString("o")
    }

    if ($state.runtime_versions.PSObject.Properties.Name -contains $Runtime) {
        $state.runtime_versions.$Runtime = $value
    }
    else {
        $state.runtime_versions | Add-Member -NotePropertyName $Runtime -NotePropertyValue $value
    }

    Save-DevKitState -State $state
}

function Register-DevKitPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Manager,
        [Parameter(Mandatory)][bool]$Preexisting,
        [Parameter(Mandatory)][bool]$PresentAfter
    )

    $state = Get-DevKitState
    $packages = @($state.packages)
    $existing = $packages |
        Where-Object { $_.id -eq $Id -and $_.manager -eq $Manager } |
        Select-Object -First 1

    $installedByDevKit = (-not $Preexisting) -and $PresentAfter

    if ($existing) {
        if ($existing.installed_by_devkit -eq $true) {
            $installedByDevKit = $true
        }

        $packages = @(
            $packages |
                Where-Object { -not ($_.id -eq $Id -and $_.manager -eq $Manager) }
        )
    }

    $packages += [pscustomobject]@{
        id                  = $Id
        name                = $Name
        manager             = $Manager
        preexisting         = $Preexisting
        installed_by_devkit = $installedByDevKit
        present             = $PresentAfter
        last_seen_at        = (Get-Date).ToUniversalTime().ToString("o")
    }

    $state.packages = $packages
    Save-DevKitState -State $state
}

function Register-DevKitExtension {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][bool]$Preexisting,
        [Parameter(Mandatory)][bool]$PresentAfter
    )

    $state = Get-DevKitState
    $items = @($state.vscode_extensions)
    $existing = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
    $installedByDevKit = (-not $Preexisting) -and $PresentAfter

    if ($existing) {
        if ($existing.installed_by_devkit -eq $true) {
            $installedByDevKit = $true
        }

        $items = @($items | Where-Object { $_.id -ne $Id })
    }

    $items += [pscustomobject]@{
        id                  = $Id
        preexisting         = $Preexisting
        installed_by_devkit = $installedByDevKit
        present             = $PresentAfter
        last_seen_at        = (Get-Date).ToUniversalTime().ToString("o")
    }

    $state.vscode_extensions = $items
    Save-DevKitState -State $state
}

function Register-DevKitFeature {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][bool]$Preexisting,
        [Parameter(Mandatory)][bool]$PresentAfter
    )

    $state = Get-DevKitState
    $items = @($state.features)
    $existing = $items | Where-Object { $_.name -eq $Name } | Select-Object -First 1
    $enabledByDevKit = (-not $Preexisting) -and $PresentAfter

    if ($existing) {
        if ($existing.enabled_by_devkit -eq $true) {
            $enabledByDevKit = $true
        }

        $items = @($items | Where-Object { $_.name -ne $Name })
    }

    $items += [pscustomobject]@{
        name              = $Name
        preexisting       = $Preexisting
        enabled_by_devkit = $enabledByDevKit
        present           = $PresentAfter
        last_seen_at      = (Get-Date).ToUniversalTime().ToString("o")
    }

    $state.features = $items
    Save-DevKitState -State $state
}

function Write-DevKitEvent {
    param(
        [Parameter(Mandatory)][string]$Event,
        [ValidateSet("info", "warning", "error")]
        [string]$Level = "info",
        [hashtable]$Data = @{}
    )

    Initialize-DevKitState

    $entry = [ordered]@{
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        level     = $Level
        event     = $Event
        data      = $Data
    }

    Add-Content -Path $script:DevKitEventLog -Value ($entry | ConvertTo-Json -Compress -Depth 8)
}
