disable_rtti()

if(MSVC)
	# 'function' : format string 'string' requires an argument of type 'type', but variadic argument number has type 'type'
	disable_warning(4477)
endif()

set(RakNet_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)

file(GLOB ALL_HEADER_SRCS ${RakNet_SOURCE_DIR}/Source/*.h)
file(GLOB ALL_CPP_SRCS ${RakNet_SOURCE_DIR}/Source/*.cpp)

include_directories("${RakNet_SOURCE_DIR}/DependentExtensions")
include_directories("${RakNet_SOURCE_DIR}/Source")

install(DIRECTORY "${RakNet_SOURCE_DIR}/Source/" DESTINATION include/RakNet FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp")

new_library_static(RakNet "${ALL_CPP_SRCS};${ALL_HEADER_SRCS}" "_RAKNET_LIB")

if(DEPENDENCIES_SHARED)
	new_library_shared(RakNet "${ALL_CPP_SRCS};${ALL_HEADER_SRCS}" "_RAKNET_DLL")
endif()

if(WIN32 AND DEPENDENCIES_SHARED)
	target_link_libraries(RakNet ws2_32)
endif()
