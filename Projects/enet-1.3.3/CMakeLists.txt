file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

add_definitions(-DENET_BUILDING_LIB)

new_library_static(enet "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/src/include" "")
new_library_shared(enet "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/src/include" "ENET_DLL")

target_link_libraries(enet winmm ws2_32)
