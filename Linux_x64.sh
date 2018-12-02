#!/bin/bash

mkdir CMake.tmp
cd CMake.tmp
mkdir "Unix Makefiles"
mkdir "Unix Makefiles/x64"
mkdir "Unix Makefiles/x64/Debug"
mkdir "Unix Makefiles/x64/Release"

cd "Unix Makefiles/x64/Debug"
cmake ../../../.. -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="../../../.." -DCMAKE_CXX_COMPILER=g++
cmake --build . --config Debug --target install

cd "../Release"
cmake ../../../.. -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="../../../.." -DCMAKE_CXX_COMPILER=g++
cmake --build . --config Release --target install