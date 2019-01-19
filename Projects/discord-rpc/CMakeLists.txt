disable_rtti()

file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/src/*.cpp)
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/src/dllmain.cpp")
if(NOT WIN32)
FOREACH(item ${SOURCES})
	STRING(REGEX MATCH "_win\\.cpp$" match "${item}")
	IF(match)
		LIST(REMOVE_ITEM SOURCES "${item}")
	ENDIF(match)
ENDFOREACH(item)
else()
FOREACH(item ${SOURCES})
	STRING(REGEX MATCH "_(uni|linu)x\\.cpp$" match "${item}")
	IF(match)
		LIST(REMOVE_ITEM SOURCES "${item}")
	ENDIF(match)
ENDFOREACH(item)
endif()

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

#add_definitions(-DDISCORD_DISABLE_IO_THREAD=1)

new_library_static(discord-rpc "${SOURCES}" "DISCORD_BUILDING_SDK")
