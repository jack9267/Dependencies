disable_rtti()

set(LIB7Z_SOURCES
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/7zAlloc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/7zArcIn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/7zBuf.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/7zCrc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/7zCrcOpt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/7zDec.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/7zFile.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/7zStream.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/Bcj2.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/Bra.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/Bra86.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/BraIA64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/CpuArch.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/Delta.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/Lzma2Dec.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/LzmaDec.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/Ppmd7.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/C/Ppmd7Dec.c
)

if(WIN32)
	add_definitions(-DUNICODE)
	add_definitions(-D_UNICODE)
endif()

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/C")

new_library_static(7z "${LIB7Z_SOURCES}" "")

if(WIN32)
	list(APPEND LIB7Z_SOURCES "7z.def")
	list(APPEND LIB7Z_SOURCES "resource.rc")
endif()

new_library_shared(7z "${LIB7Z_SOURCES}" "")

file(GLOB LIB7Z_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/src/C/7z*.h")

list(APPEND LIB7Z_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/src/C/Compiler.h")
list(APPEND LIB7Z_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/src/C/CpuArch.h")

install(FILES ${LIB7Z_HEADERS} DESTINATION include)
