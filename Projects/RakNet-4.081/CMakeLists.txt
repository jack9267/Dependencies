if(MSVC)
	# 'function' : format string 'string' requires an argument of type 'type', but variadic argument number has type 'type'
	disable_warning(4477)
endif()

set(RakNet_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

file(GLOB ALL_HEADER_SRCS ${RakNet_SOURCE_DIR}/Source/*.h)
file(GLOB ALL_CPP_SRCS ${RakNet_SOURCE_DIR}/Source/*.cpp)

if(WIN32)
	set(DEFINES "_WINSOCK_DEPRECATED_NO_WARNINGS;_RAKNET_LIB")
else()
	set(DEFINES "")
endif()

new_library_static(RakNet "${ALL_CPP_SRCS};${ALL_HEADER_SRCS}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "${DEFINES}")
