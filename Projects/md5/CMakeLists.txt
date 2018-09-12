file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(md5 "${SOURCES}" "")

if(WIN32)
	list(APPEND SOURCES "md5.def")
endif()

new_library_shared(md5 "${SOURCES}" "")
