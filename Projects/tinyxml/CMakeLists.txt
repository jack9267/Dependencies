disable_rtti()

file(GLOB_RECURSE TINYXML_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(tinyxml "${TINYXML_SOURCES}" "")
