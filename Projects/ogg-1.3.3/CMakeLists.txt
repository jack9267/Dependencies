file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

new_library_static(ogg "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "")
new_library_shared(ogg "${SOURCES};ogg.def" "${CMAKE_CURRENT_SOURCE_DIR}/include" "")
