file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Source/Core/*.cpp)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/Include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/Include")

add_definitions(-DRMLUI_VERSION="6.2")
add_definitions(-DRMLUI_FONT_ENGINE_FREETYPE)

new_library_static(rmlui_core "${SOURCES}" "RMLUI_STATIC_LIB")
#new_library_shared(rmlui_core "${SOURCES}" "RMLUI_CORE_EXPORTS")

#target_link_libraries(rmlui_core zlib freetype)

file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Source/Debugger/*.cpp)

new_library_static(rmlui_debugger "${SOURCES}" "RMLUI_STATIC_LIB")
#new_library_shared(rmlui_debugger "${SOURCES}" "RMLUI_DEBUGGER_EXPORTS")

#target_link_libraries(rmlui_debugger rmlui_core)
