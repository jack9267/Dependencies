@if [%2] == [] echo Insufficient parameters! && pause && exit

mkdir CMake.tmp
cd CMake.tmp
mkdir %1
cd %1
mkdir %2
cd %2

cmake ../../.. -G %1 -T %2 -DCMAKE_INSTALL_PREFIX="../../../Build" %3

cd ..
mkdir %2_static
cd %2_static

cmake ../../.. -G %1 -T %2 -DCMAKE_INSTALL_PREFIX="../../../Build" -DFORCE_STATIC_VCRT=ON %3
pause

:eof
cd ../../..
