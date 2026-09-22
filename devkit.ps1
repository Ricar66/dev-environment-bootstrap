#requires -Version 5.1
& (Join-Path $PSScriptRoot "tools\devkit.ps1") @args
exit $LASTEXITCODE
