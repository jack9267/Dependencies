disable_rtti()

option(CURL_STATIC_LINK_SSL "Static link ssl into curl" OFF)
option(CURL_STATIC_LINK_ZLIB "Static link zlib into curl" OFF)

file(GLOB_RECURSE SOURCES
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/*.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/vauth/*.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/vquic/*.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/vssh/*.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/vtls/*.c)

if(WIN32)
	file(GLOB_RECURSE VERSION_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/lib/*.rc)
endif()

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/lib")

add_definitions(-DUNICODE -D_UNICODE)

add_definitions(-DBUILDING_LIBCURL)

# Strip out what we won't use
add_definitions(-DCURL_DISABLE_LDAP=1)
add_definitions(-DCURL_DISABLE_LDAPS=1)
add_definitions(-DCURL_DISABLE_FILE=1)
add_definitions(-DCURL_DISABLE_POP3=1)
add_definitions(-DCURL_DISABLE_IMAP=1)
add_definitions(-DCURL_DISABLE_SMTP=1)

add_definitions(-DUSE_WEBSOCKETS=1)

# Disable auto load of /etc/ssl/openssl.cnf
add_definitions(-DCURL_DISABLE_OPENSSL_AUTO_LOAD_CONFIG)

if(WIN32)
	add_definitions(-DHAVE_WINDOWS_H)
	add_definitions(-DHAVE_WINSOCK_H)
	add_definitions(-DHAVE_WS2TCPIP_H)
	add_definitions(-DHAVE_WINSOCK2_H)
endif()

add_definitions(-DHAVE_ZLIB_H)
add_definitions(-DHAVE_ZLIB)
add_definitions(-DHAVE_LIBZ)

if(NOT WIN32 AND NOT APPLE)
	add_definitions(-DHAVE_CONFIG_H)
endif()

add_definitions(-DUSE_IPV6)

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

new_library_static(curl "${SOURCES}" "CURL_STATICLIB;USE_SSLEAY;USE_OPENSSL")
if(WIN32)
	new_library_static(curl_sspi "${SOURCES}" "CURL_STATICLIB;USE_WINDOWS_SSPI;USE_SCHANNEL")
endif()
new_library_shared(curl "${SOURCES};${VERSION_SOURCES}" "USE_SSLEAY;USE_OPENSSL")
prefix_lib(curl)

if(WIN32)
	target_link_libraries(curl wldap32 ws2_32 crypt32)
endif()

if(CURL_STATIC_LINK_SSL)
	target_link_libraries(curl ssl_static crypto_static)
else()
	target_link_libraries(curl ssl crypto)
endif()

if(CURL_STATIC_LINK_ZLIB)
	target_link_libraries(curl zlib_static)
else()
	target_link_libraries(curl zlib)
endif()
