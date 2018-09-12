file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lua.c")
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/luac.c")

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(lua "${SOURCES}" "")

if(WIN32)
	set(DEFINES "LUA_BUILD_AS_DLL")
else()
	set(DEFINES "")
endif()
new_library_shared(lua "${SOURCES}" "${DEFINES}")

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/ DESTINATION include/lua)
