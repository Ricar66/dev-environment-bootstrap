@echo off
setlocal

set "SCRIPT=%~dp0install-vscode-extensions.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
set "EXITCODE=%ERRORLEVEL%"

endlocal & exit /b %EXITCODE%
