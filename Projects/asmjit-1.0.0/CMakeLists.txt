file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/src/*.cpp)

if(MSVC)
	# conversion' : truncation of constant value
	disable_warning(4309)

	# enumerator' : enumerator value 'value' cannot be represented as 'type', value is 'new_value'
	disable_warning(4369)

	# operation' : unsafe use of type 'bool' in operation
	disable_warning(4804)
endif()

new_library_static(asmjit "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/src/src" "ASMJIT_STATIC")
