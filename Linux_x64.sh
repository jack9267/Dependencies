#!/bin/bash

mkdir CMake.tmp
cd CMake.tmp
mkdir "Unix Makefiles"
mkdir "Unix Makefiles/x64"
mkdir "Unix Makefiles/x64_static"

cd "Unix Makefiles/x64"
cmake ../../.. -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="../../../Build"
cmake --build . --config Debug --target install
cmake --build . --config Release --target install

cd "../x64_static"
cmake ../../.. -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="../../../Build" -DFORCE_STATIC_VCRT=ON
cmake --build . --config Debug --target install
cmake --build . --config Release --target install