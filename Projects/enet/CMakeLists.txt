disable_rtti()

file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

add_definitions(-DENET_BUILDING_LIB)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

new_library_static(enet "${SOURCES}" "")
new_library_shared(enet "${SOURCES}" "ENET_DLL")

target_link_libraries(enet winmm ws2_32)
