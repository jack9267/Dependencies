
file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)

new_library_static(sqlite "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "")
