@echo off
setlocal
set "PS=pwsh"
where pwsh >nul 2>nul || set "PS=powershell"
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0jbuild\JBuild.ps1" -BuildSystem premake -VisualStudio 2022 -TargetOs winxp -Build -Configuration All -Platform All
set "RESULT=%ERRORLEVEL%"
if not defined AUTOMATION pause
endlocal & exit /b %RESULT%
