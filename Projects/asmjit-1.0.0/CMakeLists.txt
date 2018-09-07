file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/src/*.cpp)

if(MSVC)
	# operation' : unsafe use of type 'bool' in operation
	disable_warning(4804)
endif()

new_library_static(asmjit "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/src/src" "ASMJIT_STATIC")
