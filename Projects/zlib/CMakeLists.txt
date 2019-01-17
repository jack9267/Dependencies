disable_rtti()

file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

define_debug(ZLIB_DEBUG=1)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(zlib "${SOURCES}" "")
new_library_shared(zlib "${SOURCES}" "ZLIB_DLL")
