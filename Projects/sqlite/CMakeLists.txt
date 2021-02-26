disable_rtti()

set(SOURCES src/sqlite3.c)

if(WIN32)
	list(APPEND SOURCES src/sqlite3.rc)

	add_definitions(-DRC_VERONLY)
endif()

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(sqlite3 "${SOURCES}" "")
if(MSVC)
	new_library_shared(sqlite3 "${SOURCES}" "SQLITE_API=__declspec(dllexport)")
else()
	new_library_shared(sqlite3 "${SOURCES}" "")
endif()
