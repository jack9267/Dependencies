# Install script for directory: C:/Users/Jack/Downloads/pcre2-10.31

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "C:/Program Files (x86)/PCRE2")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Debug/pcre2-8d.lib")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Release/pcre2-8.lib")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/MinSizeRel/pcre2-8.lib")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/RelWithDebInfo/pcre2-8.lib")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Debug/pcre2-8d.dll")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Release/pcre2-8.dll")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/MinSizeRel/pcre2-8.dll")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/RelWithDebInfo/pcre2-8.dll")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Debug/pcre2-posixd.lib")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Release/pcre2-posix.lib")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/MinSizeRel/pcre2-posix.lib")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/RelWithDebInfo/pcre2-posix.lib")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Debug/pcre2-posixd.dll")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Release/pcre2-posix.dll")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/MinSizeRel/pcre2-posix.dll")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/RelWithDebInfo/pcre2-posix.dll")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Debug/pcre2test.exe")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/Release/pcre2test.exe")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/MinSizeRel/pcre2test.exe")
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE EXECUTABLE FILES "C:/Users/Jack/Downloads/pcre2-10.31/build/RelWithDebInfo/pcre2test.exe")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include" TYPE FILE FILES
    "C:/Users/Jack/Downloads/pcre2-10.31/build/pcre2.h"
    "C:/Users/Jack/Downloads/pcre2-10.31/src/pcre2posix.h"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/man/man1" TYPE FILE FILES
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2-config.1"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2grep.1"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2test.1"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/man/man3" TYPE FILE FILES
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_callout_enumerate.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_code_copy.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_code_copy_with_tables.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_code_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_compile.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_compile_context_copy.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_compile_context_create.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_compile_context_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_config.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_convert_context_copy.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_convert_context_create.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_convert_context_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_converted_pattern_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_dfa_match.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_general_context_copy.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_general_context_create.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_general_context_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_get_error_message.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_get_mark.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_get_ovector_count.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_get_ovector_pointer.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_get_startchar.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_jit_compile.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_jit_free_unused_memory.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_jit_match.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_jit_stack_assign.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_jit_stack_create.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_jit_stack_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_maketables.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_match.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_match_context_copy.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_match_context_create.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_match_context_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_match_data_create.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_match_data_create_from_pattern.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_match_data_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_pattern_convert.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_pattern_info.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_serialize_decode.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_serialize_encode.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_serialize_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_serialize_get_number_of_codes.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_bsr.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_callout.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_character_tables.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_compile_extra_options.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_compile_recursion_guard.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_depth_limit.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_glob_escape.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_glob_separator.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_heap_limit.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_match_limit.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_max_pattern_length.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_newline.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_offset_limit.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_parens_nest_limit.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_recursion_limit.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_set_recursion_memory_management.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substitute.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_copy_byname.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_copy_bynumber.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_get_byname.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_get_bynumber.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_length_byname.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_length_bynumber.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_list_free.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_list_get.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_nametable_scan.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2_substring_number_from_name.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2api.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2build.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2callout.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2compat.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2convert.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2demo.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2jit.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2limits.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2matching.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2partial.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2pattern.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2perform.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2posix.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2sample.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2serialize.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2syntax.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2unicode.3"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/pcre2unicode.3"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/share/doc/pcre2/html" TYPE FILE FILES
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/index.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2-config.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_callout_enumerate.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_code_copy.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_code_copy_with_tables.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_code_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_compile.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_compile_context_copy.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_compile_context_create.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_compile_context_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_config.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_convert_context_copy.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_convert_context_create.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_convert_context_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_converted_pattern_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_dfa_match.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_general_context_copy.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_general_context_create.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_general_context_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_get_error_message.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_get_mark.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_get_ovector_count.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_get_ovector_pointer.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_get_startchar.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_jit_compile.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_jit_free_unused_memory.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_jit_match.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_jit_stack_assign.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_jit_stack_create.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_jit_stack_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_maketables.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_match.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_match_context_copy.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_match_context_create.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_match_context_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_match_data_create.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_match_data_create_from_pattern.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_match_data_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_pattern_convert.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_pattern_info.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_serialize_decode.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_serialize_encode.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_serialize_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_serialize_get_number_of_codes.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_bsr.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_callout.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_character_tables.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_compile_extra_options.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_compile_recursion_guard.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_depth_limit.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_glob_escape.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_glob_separator.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_heap_limit.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_match_limit.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_max_pattern_length.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_newline.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_offset_limit.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_parens_nest_limit.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_recursion_limit.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_set_recursion_memory_management.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substitute.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_copy_byname.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_copy_bynumber.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_get_byname.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_get_bynumber.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_length_byname.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_length_bynumber.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_list_free.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_list_get.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_nametable_scan.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2_substring_number_from_name.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2api.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2build.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2callout.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2compat.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2convert.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2demo.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2grep.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2jit.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2limits.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2matching.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2partial.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2pattern.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2perform.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2posix.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2sample.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2serialize.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2syntax.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2test.html"
    "C:/Users/Jack/Downloads/pcre2-10.31/doc/html/pcre2unicode.html"
    )
endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "C:/Users/Jack/Downloads/pcre2-10.31/build/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
