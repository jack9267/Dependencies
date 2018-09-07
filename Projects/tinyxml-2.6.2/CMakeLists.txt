
file(GLOB_RECURSE TINYXML_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

new_library_static(tinyxml "${TINYXML_SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "")
