disable_rtti()

# libdivsufsort
function(add_libdivsufsort)
    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
    set(BUILD_EXAMPLES OFF)
    set(BUILD_DIVSUFSORT64 ON)
    set(BUILD_SHARED_LIBS OFF)
    add_subdirectory(src/3rdparty/libdivsufsort)
endfunction()

add_libdivsufsort()

install_target(divsufsort)
install_target(divsufsort64)

set(BSDIFF_SOURCES src/source/bsdiff_private.h
    src/source/misc.c
    src/source/stream_file.c
    src/source/stream_memory.c
    src/source/stream_sub.c
    src/source/compressor_bz2.c
    src/source/decompressor_bz2.c
    src/source/patch_packer_bz2.c
    src/source/bsdiff.c
    src/source/bspatch.c)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../bzip2/src")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")
include_directories("${CMAKE_CURRENT_BINARY_DIR}/src/3rdparty/libdivsufsort/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

new_library_static(bsdiff "${BSDIFF_SOURCES}" "")
