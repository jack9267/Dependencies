file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(png "${SOURCES}" "")

if(WIN32)
	set(DEFINES "PNG_BUILD_DLL;PNG_DLL")
else()
	set(DEFINES "")
endif()
new_library_shared(png "${SOURCES}" "${DEFINES}")

target_link_libraries(png zlib)
