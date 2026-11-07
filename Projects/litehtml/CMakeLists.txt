cmake_minimum_required(VERSION 3.13)

#add_definitions(-DLITEHTML_UTF8)

set(BUILD_TESTING OFF)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include/litehtml")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/src/gumbo/src")
if(MSVC)
	include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/src/gumbo/visualc/include")
endif()

if(MSVC)
	# macro redefinition
	disable_warning(4005)

	# conversion from 'type1' to 'type2', possible loss of data
	disable_warning(4242)

	# conversion from 'type1' to 'type2', possible loss of data
	disable_warning(4244)

	# conversion from 'size_t' to 'type', possible loss of data
	disable_warning(4267)
endif()

add_subdirectory(src)

set_target_properties(litehtml PROPERTIES PUBLIC_HEADER "")
set_target_properties(gumbo PROPERTIES PUBLIC_HEADER "")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

if(MSVC AND EMBEDDED_PDB)
	# embedd pdb
	set_target_properties(gumbo PROPERTIES COMPILE_OPTIONS "/Z7")
endif()

install_target(gumbo)
if(NOT EMBEDDED_PDB)
	install_static_debug_info(gumbo)
endif()

if(MSVC AND EMBEDDED_PDB)
	# embedd pdb
	set_target_properties(litehtml PROPERTIES COMPILE_OPTIONS "/Z7")
endif()

install_target(litehtml)
if(NOT EMBEDDED_PDB)
	install_static_debug_info(litehtml)
endif()
