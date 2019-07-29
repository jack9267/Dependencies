disable_rtti()

set(SOURCES
	src/pixman/pixman.c
	src/pixman/pixman-access.c
	src/pixman/pixman-access-accessors.c
	src/pixman/pixman-bits-image.c
	src/pixman/pixman-combine32.c
	src/pixman/pixman-combine-float.c
	src/pixman/pixman-conical-gradient.c
	src/pixman/pixman-filter.c
	src/pixman/pixman-x86.c
	src/pixman/pixman-mips.c
	src/pixman/pixman-arm.c
	src/pixman/pixman-ppc.c
	src/pixman/pixman-edge.c
	src/pixman/pixman-edge-accessors.c
	src/pixman/pixman-fast-path.c
	src/pixman/pixman-glyph.c
	src/pixman/pixman-general.c
	src/pixman/pixman-gradient-walker.c
	src/pixman/pixman-image.c
	src/pixman/pixman-implementation.c
	src/pixman/pixman-linear-gradient.c
	src/pixman/pixman-matrix.c
	src/pixman/pixman-noop.c
	src/pixman/pixman-radial-gradient.c
	src/pixman/pixman-region16.c
	src/pixman/pixman-region32.c
	src/pixman/pixman-solid-fill.c
	src/pixman/pixman-timer.c
	src/pixman/pixman-trap.c
	src/pixman/pixman-utils.c
)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/pixman")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

# pixman requires the three PACKAGE* definitions in order to compile.
set(PIXMAN_DEFS 
    PRIVATE
    PACKAGE="pixman"
    PACKAGE_VERSION="0.38.0"
    PACKAGE_BUGREPORT=""
)

add_definitions(-DPIXMAN_NO_TLS)

new_library_static(pixman "${SOURCES}" "")

target_compile_definitions(pixman_static ${PIXMAN_DEFS})
