disable_rtti()

if(MSVC)
	# unreferenced local variable
	disable_warning(4101)

	# unreferenced label
	disable_warning(4102)
endif()

set(SOURCES
	src/src/cairo-analysis-surface.c
	src/src/cairo-arc.c
	src/src/cairo-array.c
	src/src/cairo-atomic.c
	src/src/cairo-base64-stream.c
	src/src/cairo-base85-stream.c
	src/src/cairo-bentley-ottmann.c
	src/src/cairo-bentley-ottmann-rectangular.c
	src/src/cairo-bentley-ottmann-rectilinear.c
	src/src/cairo-botor-scan-converter.c
	src/src/cairo-boxes.c
	src/src/cairo-boxes-intersect.c
	src/src/cairo.c
	src/src/cairo-cache.c
	src/src/cairo-clip.c
	src/src/cairo-clip-boxes.c
	src/src/cairo-clip-polygon.c
	src/src/cairo-clip-region.c
	src/src/cairo-clip-surface.c
	src/src/cairo-color.c
	src/src/cairo-composite-rectangles.c
	src/src/cairo-compositor.c
	src/src/cairo-contour.c
	src/src/cairo-damage.c
	src/src/cairo-debug.c
	src/src/cairo-default-context.c
	src/src/cairo-device.c
	src/src/cairo-error.c
	src/src/cairo-fallback-compositor.c
	src/src/cairo-fixed.c
	src/src/cairo-font-face.c
	src/src/cairo-font-face-twin.c
	src/src/cairo-font-face-twin-data.c
	src/src/cairo-font-options.c
	src/src/cairo-freelist.c
	src/src/cairo-freed-pool.c
	src/src/cairo-gstate.c
	src/src/cairo-hash.c
	src/src/cairo-hull.c
	src/src/cairo-image-compositor.c
	src/src/cairo-image-info.c
	src/src/cairo-image-source.c
	src/src/cairo-image-surface.c
	src/src/cairo-line.c
	src/src/cairo-lzw.c
	src/src/cairo-matrix.c
	src/src/cairo-mask-compositor.c
	src/src/cairo-mesh-pattern-rasterizer.c
	src/src/cairo-mempool.c
	src/src/cairo-misc.c
	src/src/cairo-mono-scan-converter.c
	src/src/cairo-mutex.c
	src/src/cairo-no-compositor.c
	src/src/cairo-observer.c
	src/src/cairo-output-stream.c
	src/src/cairo-paginated-surface.c
	src/src/cairo-path-bounds.c
	src/src/cairo-path.c
	src/src/cairo-path-fill.c
	src/src/cairo-path-fixed.c
	src/src/cairo-path-in-fill.c
	src/src/cairo-path-stroke.c
	src/src/cairo-path-stroke-boxes.c
	src/src/cairo-path-stroke-polygon.c
	src/src/cairo-path-stroke-traps.c
	src/src/cairo-path-stroke-tristrip.c
	src/src/cairo-pattern.c
	src/src/cairo-pen.c
	src/src/cairo-polygon.c
	src/src/cairo-polygon-intersect.c
	src/src/cairo-polygon-reduce.c
	src/src/cairo-raster-source-pattern.c
	src/src/cairo-recording-surface.c
	src/src/cairo-rectangle.c
	src/src/cairo-rectangular-scan-converter.c
	src/src/cairo-region.c
	src/src/cairo-rtree.c
	src/src/cairo-scaled-font.c
	src/src/cairo-shape-mask-compositor.c
	src/src/cairo-slope.c
	src/src/cairo-spans.c
	src/src/cairo-spans-compositor.c
	src/src/cairo-spline.c
	src/src/cairo-stroke-dash.c
	src/src/cairo-stroke-style.c
	src/src/cairo-surface.c
	src/src/cairo-surface-clipper.c
	src/src/cairo-surface-fallback.c
	src/src/cairo-surface-observer.c
	src/src/cairo-surface-offset.c
	src/src/cairo-surface-snapshot.c
	src/src/cairo-surface-subsurface.c
	src/src/cairo-surface-wrapper.c
	src/src/cairo-time.c
	src/src/cairo-tor-scan-converter.c
	src/src/cairo-tor22-scan-converter.c
	src/src/cairo-clip-tor-scan-converter.c
	src/src/cairo-tag-attributes.c
	src/src/cairo-tag-stack.c
	src/src/cairo-toy-font-face.c
	src/src/cairo-traps.c
	src/src/cairo-tristrip.c
	src/src/cairo-traps-compositor.c
	src/src/cairo-unicode.c
	src/src/cairo-user-font.c
	src/src/cairo-version.c
	src/src/cairo-wideint.c
	# generic font support
	src/src/cairo-cff-subset.c
	src/src/cairo-scaled-font-subsets.c
	src/src/cairo-truetype-subset.c
	src/src/cairo-type1-fallback.c
	src/src/cairo-type1-glyph-names.c
	src/src/cairo-type1-subset.c
	src/src/cairo-type3-glyph-surface.c
	# pdf
	src/src/cairo-pdf-interchange.c
	src/src/cairo-pdf-operators.c
	src/src/cairo-pdf-shading.c
	src/src/cairo-pdf-surface.c
	# png
	src/src/cairo-png.c
	# ps surface
	src/src/cairo-ps-surface.c
	# deflate source
	src/src/cairo-deflate-stream.c
	# svg surface
	src/src/cairo-svg-surface.c
	# script surface
	src/src/cairo-script-surface.c
	# fontconfig + freetype
	src/src/cairo-ft-font.c
)

if(WIN32)
set(SOURCES
	${SOURCES}
	src/src/win32/cairo-win32-debug.c
	src/src/win32/cairo-win32-device.c
	src/src/win32/cairo-win32-gdi-compositor.c
	src/src/win32/cairo-win32-system.c
	src/src/win32/cairo-win32-surface.c
	src/src/win32/cairo-win32-display-surface.c
	src/src/win32/cairo-win32-printing-surface.c
	src/src/win32/cairo-win32-font.c
)
endif()

# Cairo needs to be told which features of FreeType are availible
add_definitions(
    -DHAVE_FT_GLYPHSLOT_EMBOLDEN=1
    -DHAVE_FT_LIBRARY_SETLCDFILTER=1
    -DHAVE_FT_GLYPHSLOT_OBLIQUE=1
    -DHAVE_FT_LOAD_SFNT_TABLE=1
    -DHAVE_FT_GET_X11_FONT_FORMAT=1)

# additional features for macOS
if((CMAKE_SYSTEM_NAME STREQUAL "Darwin") OR (CMAKE_SYSTEM_NAME STREQUAL "Linux"))
  add_definitions(
      -DHAVE_INTTYPES_H=1
      -DHAVE_STDINT_H=1
      -DHAVE_SYS_TYPES_H=1
      -DHAVE_UINT64_T=1
      -DHAVE_UNISTD_H=1
      -DCAIRO_HAS_PTHREAD=1
      -DCAIRO_HAS_REAL_PTHREAD=1)
endif()

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/src")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(cairo "${SOURCES}" "CAIRO_WIN32_STATIC_BUILD")
new_library_shared(cairo "${SOURCES}" "")

target_link_libraries(cairo msimg32 zlib png freetype pixman_static)
