@echo off
rem Double-click to generate this repo's solution. All the logic lives in jbuild (the submodule);
rem this just hands off to it with this repo as the root. Forwards any args.
@call "%~dp0jbuild\JBuild.cmd" %*
