disable_rtti()

file(GLOB_RECURSE SOURCES src/*.c include/*.h)
file(GLOB_RECURSE DLL_SOURCES dll_resources/*.rc dll_resources/*.def)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(MinHook "${SOURCES}" "")
new_library_shared(MinHook "${SOURCES};${DLL_SOURCES}" "")
