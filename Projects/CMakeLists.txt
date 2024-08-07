
if(WIN32)
	set(DEPENDENCIES_SHARED ON)
else()
	set(DEPENDENCIES_SHARED OFF)
endif()

# To prefix libs with lib on windows
macro(prefix_lib NAME)
	if(WIN32)
		set_target_properties(${NAME} PROPERTIES RUNTIME_OUTPUT_NAME_DEBUG "lib${NAME}${RUNTIME_DEBUG_POSTFIX}")
		set_target_properties(${NAME} PROPERTIES RUNTIME_OUTPUT_NAME_RELEASE "lib${NAME}${RUNTIME_RELEASE_POSTFIX}")
	endif()
endmacro()

if(MSVC)
	# no deprecated warnings for winsock
	add_definitions(-D_WINSOCK_DEPRECATED_NO_WARNINGS)

	# macro redefinition
	disable_warning(4005)

	# signed/unsigned mismatch
	disable_warning(4018)

	# different 'modifier' qualifiers
	disable_warning(4090)

	# ignored on left of 'type' when no variable is declared
	disable_warning(4091)

	# unary minus operator applied to unsigned type, result still unsigned
	disable_warning(4146)

	# conversion from 'type1' to 'type2', possible loss of data
	disable_warning(4242)

	# conversion from 'type1' to 'type2', possible loss of data
	disable_warning(4244)

	# conversion from 'type1' to 'type2', signed/unsigned mismatch
	disable_warning(4245)

	# conversion from 'size_t' to 'type', possible loss of data
	disable_warning(4267)

	# operator' : result of 32-bit shift implicitly converted to 64 bits (was 64-bit shift intended?)
	disable_warning(4334)

	# signed/unsigned mismatch
	disable_warning(4389)

	# conversion from 'type_1' to 'type_2' requires a narrowing conversion
	disable_warning(4838)

	# 64-bit specific warnings
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		# operation' : conversion from 'type1' to 'type2' of greater size
		disable_warning(4312)
	endif()
endif()

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/zlib/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/png/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/ogg/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/freetype/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/squirrel/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/sqstdlib/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/tinyxml/include")
if(MSVC)
	include_directories("${CMAKE_CURRENT_SOURCE_DIR}/libressl/src/include")
endif()
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/libzip/src/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/rapidjson/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/pixman/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/cairo/include")
if(WIN32)
	include_directories("${CMAKE_CURRENT_SOURCE_DIR}/SDL/src/include")
endif()

add_subdirectory(zlib)
add_subdirectory(png)
if(WIN32)
add_subdirectory(ogg)
add_subdirectory(vorbis)
add_subdirectory(flac)
add_subdirectory(theora)
endif()
add_subdirectory(RakNet)
add_subdirectory(lua5.3)
add_subdirectory(lua5.4)
if(WIN32)
add_subdirectory(freetype)
add_subdirectory(harfbuzz)
endif()
add_subdirectory(squirrel)
add_subdirectory(sqstdlib)
add_subdirectory(tinyxml)
if(WIN32)
add_subdirectory(asmjit)
if(MSVC)
	add_subdirectory(discord-rpc)
	add_subdirectory(libressl)
endif()
add_subdirectory(libzip)
add_subdirectory(rapidjson)
endif()
if(WIN32)
	add_subdirectory(curl)
	add_subdirectory(SDL)
	add_subdirectory(MinHook)
endif()
add_subdirectory(mongoose6)
add_subdirectory(mongoose7)
add_subdirectory(sqlite)
add_subdirectory(enet)
if(WIN32)
#add_subdirectory(lzma)
add_subdirectory(bass)
add_subdirectory(fmod)
add_subdirectory(jpeg)
add_subdirectory(pcre2)
add_subdirectory(glew)
add_subdirectory(bzip2)
add_subdirectory(bsdiff)
endif()
if(WIN32)
add_subdirectory(pixman)
add_subdirectory(cairo)
add_subdirectory(litehtml)
add_subdirectory(RmlUi)
endif()
