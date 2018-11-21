cmake_minimum_required(VERSION 3.13)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")

project(Dependencies C CXX)

# Embedded pdb in static libraries
set(EMBEDDED_PDB ON)

include(j-common)
include(j-macros)

add_subdirectory(Projects)
