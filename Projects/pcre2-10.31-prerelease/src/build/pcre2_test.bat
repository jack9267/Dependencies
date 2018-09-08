@REM This is a generated file.
@echo off
setlocal
SET srcdir="C:\Users\Jack\Downloads\pcre2-10.31"
SET pcre2test="C:\Users\Jack\Downloads\pcre2-10.31\build\DEBUG\pcre2test.exe"
if not [%CMAKE_CONFIG_TYPE%]==[] SET pcre2test="C:\Users\Jack\Downloads\pcre2-10.31\build\%CMAKE_CONFIG_TYPE%\pcre2test.exe"
call %srcdir%\RunTest.Bat
if errorlevel 1 exit /b 1
echo RunTest.bat tests successfully completed
