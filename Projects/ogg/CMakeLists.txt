disable_rtti()

file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/src/*.c)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")
install_include("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

new_library_static(ogg "${SOURCES}" "")

if(WIN32)
	new_library_shared(ogg "${SOURCES};src/win32/ogg.def" "")
	prefix_lib(ogg)
endif()
