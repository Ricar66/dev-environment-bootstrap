#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$Template,
    [string]$Name,
    [string]$OutputPath = ".",
    [switch]$DryRun,
    [switch]$Force,
    [switch]$WithDevContainer,
    [switch]$InstallDependencies,
    [switch]$List
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$catalogPath = Join-Path $root "templates\catalog.json"

if (-not (Test-Path $catalogPath)) {
    throw "Catálogo de templates não encontrado: $catalogPath"
}

$catalog = Get-Content $catalogPath -Raw | ConvertFrom-Json

function ConvertTo-ProjectSlug {
    param([Parameter(Mandatory)][string]$Value)

    $slug = $Value.Trim().ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^a-z0-9._-]+', '-')
    $slug = [regex]::Replace($slug, '-{2,}', '-')
    $slug = $slug.Trim('-', '.', '_')

    if (-not $slug) {
        throw "Não foi possível gerar um nome de projeto válido."
    }

    return $slug
}

function Show-Templates {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "         SUPER DEV KIT - PROJECT TEMPLATES" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($property in $catalog.templates.PSObject.Properties | Sort-Object Name) {
        $item = $property.Value
        Write-Host "$($property.Name) — $($item.name)"
        Write-Host "  $($item.description)"
        Write-Host ""
    }
}

if ($List) {
    Show-Templates
    exit 0
}

if (-not $Template -or -not $Name) {
    Write-Host "Informe -Template e -Name, ou use -List." -ForegroundColor Yellow
    Write-Host "Exemplo:"
    Write-Host "  .\tools\create-project.ps1 -Template react-vite -Name meu-app -DryRun"
    exit 1
}

$templateProperty = $catalog.templates.PSObject.Properties[$Template]
if (-not $templateProperty) {
    Write-Host "Template não encontrado: $Template" -ForegroundColor Red
    Show-Templates
    exit 1
}

$templateConfig = $templateProperty.Value
$projectSlug = ConvertTo-ProjectSlug -Value $Name
$sourceDir = Join-Path $root ([string]$templateConfig.source)

if (-not (Test-Path $sourceDir)) {
    throw "Pasta do template não encontrada: $sourceDir"
}

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path (Get-Location) $OutputPath
}

$targetDir = Join-Path $OutputPath $projectSlug
$files = @(Get-ChildItem -Path $sourceDir -File -Recurse -Force)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "       SUPER DEV KIT - CREATE PROJECT" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Template:   $($templateConfig.name)"
Write-Host "Nome:       $Name"
Write-Host "Slug:       $projectSlug"
Write-Host "Destino:    $targetDir"
Write-Host "DevContainer: $([bool]$WithDevContainer)"
Write-Host ""

if (Test-Path $targetDir) {
    $existingItems = @(Get-ChildItem -Path $targetDir -Force -ErrorAction SilentlyContinue)

    if ($existingItems.Count -gt 0 -and -not $Force) {
        throw "O destino já existe e não está vazio. Use -Force para permitir sobrescrita controlada."
    }
}

Write-Host "Arquivos:"
foreach ($file in $files) {
    $relative = $file.FullName.Substring($sourceDir.Length).TrimStart([char[]]"\/")
    $relative = $relative.Replace("__PROJECT_NAME__", $projectSlug)
    Write-Host "  - $relative"
}

if ($WithDevContainer) {
    Write-Host "  - .devcontainer\devcontainer.json"
}

Write-Host "  - .devkit-project.json"

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY-RUN] Nenhum arquivo foi criado." -ForegroundColor Green

    if ($InstallDependencies) {
        Write-Host "[DRY-RUN] Dependências seriam instaladas após a geração."
    }

    exit 0
}

New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

foreach ($file in $files) {
    $relative = $file.FullName.Substring($sourceDir.Length).TrimStart([char[]]"\/")
    $relative = $relative.Replace("__PROJECT_NAME__", $projectSlug)
    $destination = Join-Path $targetDir $relative
    $destinationDir = Split-Path -Parent $destination

    if ($destinationDir) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    if ((Test-Path $destination) -and -not $Force) {
        throw "Arquivo já existe: $destination"
    }

    $content = Get-Content -Path $file.FullName -Raw
    $content = $content.Replace("{{PROJECT_NAME}}", $Name)
    $content = $content.Replace("{{PROJECT_SLUG}}", $projectSlug)
    Set-Content -Path $destination -Value $content -Encoding UTF8
}

if ($WithDevContainer) {
    $devContainerDir = Join-Path $targetDir ".devcontainer"
    New-Item -ItemType Directory -Path $devContainerDir -Force | Out-Null

    $devContainer = [ordered]@{
        name  = "$Name Dev Container"
        image = [string]$templateConfig.devcontainer_image
    }

    $devContainer |
        ConvertTo-Json -Depth 5 |
        Set-Content -Path (Join-Path $devContainerDir "devcontainer.json") -Encoding UTF8
}

$metadata = [ordered]@{
    schema_version = 1
    template       = $Template
    project_name   = $Name
    project_slug   = $projectSlug
    generated_at   = (Get-Date).ToUniversalTime().ToString("o")
    generated_by   = "Super Dev Kit"
    devcontainer   = [bool]$WithDevContainer
}

$metadata |
    ConvertTo-Json -Depth 5 |
    Set-Content -Path (Join-Path $targetDir ".devkit-project.json") -Encoding UTF8

if ($InstallDependencies) {
    Push-Location $targetDir

    try {
        switch ($Template) {
            "react-vite" {
                if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw "npm não encontrado." }
                npm install
            }
            "node-nest" {
                if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw "npm não encontrado." }
                npm install
            }
            "dotnet-webapi" {
                if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { throw "dotnet não encontrado." }
                dotnet restore
            }
            "python-api" {
                $python = Get-Command python -ErrorAction SilentlyContinue
                if (-not $python) { $python = Get-Command py -ErrorAction SilentlyContinue }
                if (-not $python) { throw "Python não encontrado." }

                if ($python.Name -eq "py.exe" -or $python.Name -eq "py") {
                    py -m pip install -r requirements.txt
                }
                else {
                    python -m pip install -r requirements.txt
                }
            }
            "docker-compose" {
                Write-Host "Nenhuma dependência local para instalar."
            }
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao instalar dependências."
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "[OK] Projeto criado com sucesso." -ForegroundColor Green
Write-Host "     $targetDir"
