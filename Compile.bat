@if [%2] == [] echo Insufficient parameters! && pause && exit

mkdir CMake.tmp
cd CMake.tmp
mkdir %1
cd %1
mkdir %2
cd %2

cmake ../../.. -G %1 -T %2 -DCMAKE_INSTALL_PREFIX="../../../Build"
if %ERRORLEVEL% neq 0 pause && goto eof
cmake --build . --config Debug --target install
if %ERRORLEVEL% neq 0 pause && goto eof
cmake --build . --config Release --target install
if %ERRORLEVEL% neq 0 pause && goto eof

cd ..
mkdir %2_static
cd %2_static

cmake ../../.. -G %1 -T %2 -DCMAKE_INSTALL_PREFIX="../../../Build" -DFORCE_STATIC_VCRT=ON
if %ERRORLEVEL% neq 0 pause && goto eof
cmake --build . --config Debug --target install
if %ERRORLEVEL% neq 0 pause && goto eof
cmake --build . --config Release --target install
if %ERRORLEVEL% neq 0 pause && goto eof
pause

:eof
cd ../../..
