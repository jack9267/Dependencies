file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/lib/*.c)
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lib/zip_source_file.c")
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lib/zip_algorithm_bzip2.c")
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lib/zip_crypto_commoncrypto.c")
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lib/zip_crypto_gnutls.c")
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lib/zip_crypto_openssl.c")
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lib/zip_random_unix.c")
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lib/zip_random_uwp.c")
list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/lib/zip_winzip_aes.c")

if(MSVC)
	# function' undefined; assuming extern returning int
	disable_warning(4013)

	# operator' : result of 32-bit shift implicitly converted to 64 bits (was 64-bit shift intended?)
	disable_warning(4334)
endif()

add_definitions(-DZIP_STATIC)
add_definitions(-DHAVE_CONFIG_H)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

new_library_static(zip "${SOURCES}" "")
#new_library_shared(zip "${SOURCES}" "")
