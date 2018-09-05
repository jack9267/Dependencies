@echo off
if exist Dependencies.7z rm Dependencies.7z
7za a Dependencies.7z ./Build/*
pause