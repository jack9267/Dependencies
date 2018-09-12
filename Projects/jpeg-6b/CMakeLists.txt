
set(JPEG_SOURCES
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcapimin.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcapistd.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jccoefct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jccolor.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcdctmgr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jchuff.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcinit.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcmainct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcmarker.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcmaster.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcomapi.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcparam.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcphuff.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcprepct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jcsample.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jctrans.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdapimin.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdapistd.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdatadst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdatasrc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdcoefct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdcolor.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jddctmgr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdhuff.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdinput.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdmainct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdmarker.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdmaster.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdmerge.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdphuff.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdpostct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdsample.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jdtrans.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jerror.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jfdctflt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jfdctfst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jfdctint.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jidctflt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jidctfst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jidctint.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jidctred.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jmemansi.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jmemmgr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jquant1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jquant2.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/jutils.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/rdbmp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/rdcolmap.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/rdgif.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/rdppm.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/rdrle.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/rdswitch.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/rdtarga.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/transupp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/wrbmp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/wrgif.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/wrppm.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/wrrle.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/wrtarga.c
)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(jpeg "${JPEG_SOURCES}" "")

set(JPEG_HEADERS
	${CMAKE_CURRENT_SOURCE_DIR}/src/jmorecfg.h
	${CMAKE_CURRENT_SOURCE_DIR}/src/jpeglib.h
	${CMAKE_CURRENT_SOURCE_DIR}/src/jerror.h
)

install(FILES ${JPEG_HEADERS} DESTINATION include)
