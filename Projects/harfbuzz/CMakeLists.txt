disable_rtti()

add_definitions(-DHAVE_FREETYPE=1)

## Functions and headers
include (CheckFunctionExists)
include (CheckIncludeFile)
macro (check_funcs) # Similar to AC_CHECK_FUNCS of autotools
  foreach (func_name ${ARGN})
    string(TOUPPER ${func_name} definition_to_add)
    check_function_exists(${func_name} HAVE_${definition_to_add})
    if (${HAVE_${definition_to_add}})
      add_definitions(-DHAVE_${definition_to_add})
    endif ()
  endforeach ()
endmacro ()
if (UNIX)
  list(APPEND CMAKE_REQUIRED_LIBRARIES m)
endif ()
check_funcs(atexit mprotect sysconf getpagesize mmap isatty roundf)
check_include_file(unistd.h HAVE_UNISTD_H)
if (${HAVE_UNISTD_H})
  add_definitions(-DHAVE_UNISTD_H)
endif ()
check_include_file(sys/mman.h HAVE_SYS_MMAN_H)
if (${HAVE_SYS_MMAN_H})
  add_definitions(-DHAVE_SYS_MMAN_H)
endif ()
check_include_file(stdbool.h HAVE_STDBOOL_H)
if (${HAVE_STDBOOL_H})
  add_definitions(-DHAVE_STDBOOL_H)
endif ()

set(project_sources src/harfbuzz.cc) # use amalgam source
set(subset_project_sources
  src/hb-number.cc
  src/hb-ot-cff1-table.cc
  src/hb-ot-cff2-table.cc
  src/hb-static.cc
  src/hb-subset.cc
  src/hb-subset-cff1.cc
  src/hb-subset-cff2.cc
  src/hb-subset-cff-common.cc
  src/hb-subset-input.cc
  src/hb-subset-plan.cc
)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src")

new_library_static(harfbuzz "${project_sources}" "")
new_library_shared(harfbuzz "${project_sources}" "HB_DLL_EXPORT")

target_link_libraries(harfbuzz zlib freetype)

new_library_static(harfbuzz-subset "${subset_project_sources}" "")
new_library_shared(harfbuzz-subset "${subset_project_sources}" "HB_DLL_EXPORT")

target_link_libraries(harfbuzz-subset harfbuzz zlib freetype)
