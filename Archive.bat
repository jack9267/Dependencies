@echo off
if exist Dependencies.7z del Dependencies.7z
7za a Dependencies.7z ./include ./Lib
pause