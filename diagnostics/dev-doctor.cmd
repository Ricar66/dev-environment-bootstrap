@echo off
setlocal

set "SCRIPT=%~dp0dev-doctor.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
set "EXITCODE=%ERRORLEVEL%"

endlocal & exit /b %EXITCODE%
