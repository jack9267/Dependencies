file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

if(MSVC)
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		# operation' : conversion from 'type1' to 'type2' of greater size
		disable_warning(4312)
	endif()
endif()

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(sqstdlib "${SOURCES}" "")
