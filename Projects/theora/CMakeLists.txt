disable_rtti()

set(THEORA_SOURCES
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/cpu.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/analyze.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/encapiwrapper.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/encfrag.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/encinfo.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/encode.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/enquant.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fdct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/huffenc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/mathops.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/mcenc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/rate.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/tokenize.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/x86_vc/mmxencfrag.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/x86_vc/mmxfdct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/x86_vc/x86enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/apiwrapper.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/bitpack.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/decapiwrapper.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/decinfo.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/decode.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/dequant.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fragment.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/huffdec.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/idct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/info.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/internal.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/quant.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/state.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/decode.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/decode.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/decode.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/decode.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/x86_vc/mmxfrag.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/x86_vc/mmxidct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/x86_vc/mmxstate.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/lib/x86_vc/x86state.c
)

if(MSVC)
	# operator' : check operator precedence for possible error; use parentheses to clarify precedence
	disable_warning(4554)

	# uninitialized local variable 'name' used
	disable_warning(4700)
endif()

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/lib")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

new_library_static(theora "${THEORA_SOURCES}" "")

if(WIN32)
	list(APPEND THEORA_SOURCES "libtheora.def")
endif()

new_library_shared(theora "${THEORA_SOURCES}" "LIBTHEORA_EXPORTS")
prefix_lib(theora)

target_link_libraries(theora ogg)
