file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

new_library_static(md5 "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "")

if(WIN32)
	list(APPEND SOURCES "md5.def")
endif()

new_library_shared(md5 "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "")
