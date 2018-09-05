file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

new_library_static(png "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "")

if(WIN32)
	set(DEFINES "PNG_BUILD_DLL;PNG_DLL")
else()
	set(DEFINES "")
endif()
new_library_shared(png "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "${DEFINES}")

target_link_libraries(png zlib)
