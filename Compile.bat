@if [%2] == [] echo Insufficient parameters! && pause && exit

mkdir CMake.%2.tmp
cd CMake.%2.tmp

cmake .. -G %1 -T %2 -DCMAKE_INSTALL_PREFIX="../Build"
if %ERRORLEVEL% neq 0 pause && goto eof
cmake --build . --config Debug --target install
if %ERRORLEVEL% neq 0 pause && goto eof
cmake --build . --config Release --target install
if %ERRORLEVEL% neq 0 pause && goto eof

cd ..
mkdir CMake.%2_static.tmp
cd CMake.%2_static.tmp

cmake .. -G %1 -T %2 -DCMAKE_INSTALL_PREFIX="../Build" -DFORCE_STATIC_VCRT=ON
if %ERRORLEVEL% neq 0 pause && goto eof
cmake --build . --config Debug --target install
if %ERRORLEVEL% neq 0 pause && goto eof
cmake --build . --config Release --target install
if %ERRORLEVEL% neq 0 pause && goto eof
pause

:eof
cd ..
