
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/zlib-1.2.11/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/png-1.6.24/include")

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/ogg-1.3.3/include")

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/RakNet-4.081/include")

add_subdirectory(zlib-1.2.11)
add_subdirectory(png-1.6.24)

add_subdirectory(ogg-1.3.3)

add_subdirectory(RakNet-4.081)
