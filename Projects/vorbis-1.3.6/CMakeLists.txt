
set(VORBIS_SOURCES
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/analysis.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/bitrate.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/block.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/codebook.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/envelope.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/floor0.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/floor1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/info.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/lookup.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/lpc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/lsp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/mapping0.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/mdct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/psy.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/registry.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/res0.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/sharedbook.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/smallft.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/synthesis.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/vorbisenc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/window.c
)

set(VORBISFILE_SOURCES
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/vorbisfile.c
)

if(MSVC)
	# identifier' : unreferenced local variable
	disable_warning(4101)

	# conversion' conversion from 'type1' to 'type2', possible loss of data
	disable_warning(4244)

	# identifier' : truncation from 'type1' to 'type2'
	disable_warning(4305)
endif()

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/lib")

new_library_static(vorbis "${VORBIS_SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/src/include" "")

if(WIN32)
	list(APPEND VORBIS_SOURCES "src/win32/vorbis.def")
endif()

new_library_shared(vorbis "${VORBIS_SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/src/include" "LIBVORBIS_EXPORTS")

target_link_libraries(vorbis ogg)

new_library_static(vorbisfile "${VORBISFILE_SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/src/include" "")

if(WIN32)
	list(APPEND VORBISFILE_SOURCES "src/win32/vorbisfile.def")
endif()

new_library_shared(vorbisfile "${VORBISFILE_SOURCES}" "${CMAKE_CURRENT_SOURCE_DIR}/src/include" "LIBVORBISFILE_EXPORTS")

target_link_libraries(vorbisfile ogg vorbis)
