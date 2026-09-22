@echo off
setlocal
set "SCRIPT=%~dp0restore-vscode.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
set "EXITCODE=%ERRORLEVEL%"
endlocal & exit /b %EXITCODE%
