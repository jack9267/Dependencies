disable_rtti()

set(BZIP2_SOURCES
	${CMAKE_CURRENT_SOURCE_DIR}/src/blocksort.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/bzlib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/compress.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crctable.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/decompress.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/huffman.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/randtable.c
)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src")

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/src/bzlib.h" DESTINATION include)

new_library_static(bzip2 "${BZIP2_SOURCES}" "BZIP2_STATIC")

if(WIN32)
	list(APPEND BZIP2_SOURCES "src/libbz2.def")
	list(APPEND BZIP2_SOURCES "version.rc")
endif()

new_library_shared(bzip2 "${BZIP2_SOURCES}" "BUILD_BZIP2_DLL;BZ_EXPORT")
prefix_lib(bzip2)
