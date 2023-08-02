cmake_minimum_required(VERSION 3.15...3.26)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")

project(Dependencies C CXX)

# Embedded pdb in static libraries
set(EMBEDDED_PDB OFF)

# Warning level 3
set(CUSTOM_MSVC_WARNING_LEVEL 3)

if(WIN32)
	# Find NASM
	enable_language(ASM_NASM)
endif()

include(j-common)
include(j-macros)

add_subdirectory(Projects)
