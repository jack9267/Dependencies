disable_rtti()

set(BSDIFF_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/bsdiff.c)
set(BSPATCH_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/bspatch.c)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src")

new_library_static(bsdiff "${BSDIFF_SOURCES}" "")
new_library_static(bspatch "${BSPATCH_SOURCES}" "")
