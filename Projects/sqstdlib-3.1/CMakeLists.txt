file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

new_library_static(sqstdlib "${SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "")
