disable_rtti()

file(GLOB_RECURSE SOURCES src/*.c include/*.h)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include/mongoose7")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(mongoose7 "${SOURCES}" "")
