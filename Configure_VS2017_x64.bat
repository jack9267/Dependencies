@echo off
setlocal
set CMAKE_GENERATOR="Visual Studio 15 2017"
set CMAKE_GENERATOR_PLATFORM=x64
set CMAKE_GENERATOR_TOOLSET=v141
call Configure.bat
set CMAKE_EXTRA_PATH=_static
set CMAKE_EXTRA_ARGS=-DFORCE_STATIC_VCRT=ON
call Configure.bat
endlocal
if not defined AUTOMATION pause