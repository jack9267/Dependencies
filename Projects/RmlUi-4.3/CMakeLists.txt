file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Source/Core/*.cpp)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/Include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/Include")

add_definitions(-DRMLUI_VERSION="4.3")

new_library_static(RmlCore "${SOURCES}" "RMLUI_STATIC_LIB")
new_library_shared(RmlCore "${SOURCES}" "RmlCore_EXPORTS")

target_link_libraries(RmlCore zlib freetype)

file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Source/Debugger/*.cpp)

new_library_static(RmlDebugger "${SOURCES}" "RMLUI_STATIC_LIB")
new_library_shared(RmlDebugger "${SOURCES}" "RmlDebugger_EXPORTS")

target_link_libraries(RmlDebugger RmlCore)
