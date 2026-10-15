@echo off
setlocal
set AUTOMATION=1
call "%~dp0jbuild\cmake\bat\Clean.bat"
endlocal
if exist "%~dp0include" rmdir /S /Q "%~dp0include"
if exist "%~dp0Lib" rmdir /S /Q "%~dp0Lib"
if not defined AUTOMATION pause
