disable_rtti()

file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lua.c")
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/luac.c")

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(lua53 "${SOURCES}" "")

if(WIN32)
	set(DEFINES "LUA_BUILD_AS_DLL")
else()
	set(DEFINES "")
endif()

if(DEPENDENCIES_SHARED)
	new_library_shared(lua53 "${SOURCES}" "${DEFINES}")
endif()
