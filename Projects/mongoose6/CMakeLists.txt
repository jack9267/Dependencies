file(GLOB_RECURSE SOURCES src/*.c include/*.h)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include/mongoose6")

# 64 KB per socket read/write and of a served file kept queued (defaults 1460 and 1024); see premake5.lua.
add_definitions(-DMG_TCP_IO_SIZE=65536 -DMG_MAX_HTTP_SEND_MBUF=65536)

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(mongoose6 "${SOURCES}" "")
