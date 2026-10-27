file(GLOB_RECURSE SOURCES src/*.c include/*.h)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include/mongoose7")

# Buffers in 32 KB steps, 64 KB of a served file queued at a time (default 512 and 1 KB); see premake5.lua.
add_definitions(-DMG_IO_SIZE=32768)

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(mongoose7 "${SOURCES}" "")
