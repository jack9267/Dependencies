file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

define_debug(ZLIB_DEBUG=1)

new_library_static(zlib "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "")
new_library_shared(zlib "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "ZLIB_DLL")
