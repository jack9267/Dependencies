
if(MSVC)
	if(MSVC_VERSION LESS 1900)
		# Visual studio 2015 adds support for stdbool.h, add it for older versions
		include_directories("${CMAKE_CURRENT_SOURCE_DIR}/stdbool")
	endif()
endif()

set(PROJECTS "")

list(APPEND PROJECTS "zlib-1.2.11")
list(APPEND PROJECTS "png-1.6.24")
list(APPEND PROJECTS "ogg-1.3.3")
list(APPEND PROJECTS "RakNet-4.081")
list(APPEND PROJECTS "lua-5.3.4")
list(APPEND PROJECTS "freetype-2.8.1")
list(APPEND PROJECTS "squirrel-3.1")
list(APPEND PROJECTS "sqstdlib-3.1")
list(APPEND PROJECTS "tinyxml-2.6.2")
list(APPEND PROJECTS "asmjit-1.0.0")
list(APPEND PROJECTS "discord-rpc-3.3.0")
list(APPEND PROJECTS "libressl-2.6.4")
list(APPEND PROJECTS "libzip-1.5.1")
list(APPEND PROJECTS "rapidjson-1.1.0")

foreach(PROJECT ${PROJECTS})
	include_directories("${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT}/include")
endforeach()

foreach(PROJECT ${PROJECTS})
	add_subdirectory(${PROJECT})
endforeach()
