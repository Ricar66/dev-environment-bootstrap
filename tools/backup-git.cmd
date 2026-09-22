@echo off
setlocal
set "SCRIPT=%~dp0backup-git.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
set "EXITCODE=%ERRORLEVEL%"
endlocal & exit /b %EXITCODE%
