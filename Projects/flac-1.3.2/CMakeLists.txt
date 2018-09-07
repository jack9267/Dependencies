cmake_policy(SET CMP0005 NEW) # do not escape preprocessor defines

enable_language(ASM_NASM)

if(MSVC)
	# var' : conversion from 'size_t' to 'type', possible loss of data
	disable_warning(4267)

	# The compiler encountered a deprecated declaration.
	disable_warning(4996)
endif()

file(GLOB LIBFLAC_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/src/libFLAC/*.c)

if(WIN32)
	list(APPEND LIBFLAC_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/src/share/win_utf8_io/win_utf8_io.c)
else()
	list(FILTER LIBFLAC_SOURCES EXCLUDE REGEX "windows[^/]*$")

	file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/config.h "#include <inttypes.h>")
	include_directories(${CMAKE_CURRENT_BINARY_DIR})
	add_definitions(-DHAVE_CONFIG_H)
endif()

file(GLOB LIBFLACXX_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/src/libFLAC++/*.cpp)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/src/libFLAC/include")

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(LIBFLAC_ARCHITECTURE "x64")
else()
	set(LIBFLAC_ARCHITECTURE "x86")
endif()

if(NOT LIBFLAC_ARCHITECTURE MATCHES arm)
    add_definitions(-DFLAC__SSE_OS)
    add_definitions(-DFLAC__HAS_X86INTRIN)
endif()

if(LIBFLAC_ARCHITECTURE MATCHES x86)
    add_definitions(-DFLAC__CPU_IA32)
    add_definitions(-DFLAC__HAS_NASM)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/nasm)
    foreach(ASM_SOURCE cpu_asm fixed_asm lpc_asm)
        execute_process(COMMAND ${CMAKE_ASM_NASM_COMPILER} "-i${CMAKE_CURRENT_SOURCE_DIR}/src/src/libFLAC/ia32/" -f win32 -d OBJ_FORMAT_win32 -f win32 
            -o "${CMAKE_BINARY_DIR}/nasm/${ASM_SOURCE}.obj" "${CMAKE_CURRENT_SOURCE_DIR}/src/src/libFLAC/ia32/${ASM_SOURCE}.nasm"
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
        list(APPEND LIBFLAC_SOURCES ${CMAKE_BINARY_DIR}/nasm/${ASM_SOURCE}.obj)
    endforeach()
elseif(LIBFLAC_ARCHITECTURE MATCHES x64)
    add_definitions(-DFLAC__CPU_X86_64)
    add_definitions(-DENABLE_64_BIT_WORDS)
endif()

if(CMAKE_BUILD_TYPE MATCHES Debug)
    add_definitions(-DFLAC__OVERFLOW_DETECT)
endif()

add_definitions(-DPACKAGE_VERSION="1.3.2")
add_definitions(-DFLAC__HAS_OGG)
add_definitions(-DFLAC__ALIGN_MALLOC_DATA) # 32 byte boundary
add_definitions(-DHAVE_LROUND)
add_definitions(-D_CRT_SECURE_NO_WARNINGS)
add_definitions(-D_CRT_NONSTDC_NO_WARNINGS)

new_library_static(FLAC "${LIBFLAC_SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "FLAC__NO_DLL")
new_library_shared(FLAC "${LIBFLAC_SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "FLAC_API_EXPORTS")

new_library_static(FLAC++ "${LIBFLACXX_SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "FLAC__NO_DLL")
new_library_shared(FLAC++ "${LIBFLACXX_SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/include" "FLACPP_API_EXPORTS")

target_link_libraries(FLAC ogg)
target_link_libraries(FLAC++ FLAC)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/include/FLAC/ DESTINATION include/FLAC FILES_MATCHING PATTERN "*.h*")

