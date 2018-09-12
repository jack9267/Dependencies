set(PCRE2_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")

set(PCRE2_SOURCES
  ${PCRE2_SOURCE_DIR}/src/pcre2_auto_possess.c
  ${CMAKE_CURRENT_SOURCE_DIR}/pcre2_chartables.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_compile.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_config.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_context.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_convert.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_dfa_match.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_error.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_extuni.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_find_bracket.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_jit_compile.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_maketables.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_match.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_match_data.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_newline.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_ord2utf.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_pattern_info.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_serialize.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_string_utils.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_study.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_substitute.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_substring.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_tables.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_ucd.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_valid_utf.c
  ${PCRE2_SOURCE_DIR}/src/pcre2_xclass.c
)

include_directories("${PCRE2_SOURCE_DIR}/src")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(pcre2-8 "${PCRE2_SOURCES}" "PCRE2_CODE_UNIT_WIDTH=8;HAVE_CONFIG_H;PCRE2_STATIC")
new_library_shared(pcre2-8 "${PCRE2_SOURCES}" "PCRE2_CODE_UNIT_WIDTH=8;HAVE_CONFIG_H;pcre2_8_EXPORTS")
