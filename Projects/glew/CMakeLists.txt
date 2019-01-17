disable_rtti()

set(SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/glew.c)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(glew "${SOURCES}" "GLEW_EXPORTS;GLEW_STATIC;GLEW_BUILD")
