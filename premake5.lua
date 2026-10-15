-- Dependencies: the vendored third-party libraries, built with premake as an alternative to the
-- CMake build. A single file (no per-project scripts), using the shared jbuild/premake utils.
--
--     premake5 vs2022        (run from the repository root)
--
-- Output mirrors the CMake build so the same consumers link unchanged: each static library lands in
--   Lib\<arch>\<toolset>_static\<Debug|Release>\<name>_static.lib
-- via common_project()'s targetdir - so NO per-library install step is needed, only the headers,
-- which the "headers" project below assembles into include\ the way install_include() did.
--
-- NOTE: this is being ported in batches. The cross-platform core libraries are done; the Win32-only
-- and heavier libraries (SDL, curl, freetype, harfbuzz, cairo, pixman, litehtml, RmlUi, libressl,
-- asmjit, discord-rpc, libzip, rapidjson, glew, jpeg, pcre2, bsdiff, bass, fmod, MinHook, ogg,
-- vorbis, flac, theora) are still to add - see the TODO at the bottom.

include "jbuild/premake/Common.lua"
include "jbuild/premake/Warnings.lua"

-- AFTER Common.lua (overrides its support_winxp()).
include "jbuild/premake/XP.lua"

common_options("v143")
warnings_options()

-- SUPPORT_WINXP links YY-Thunks for the Win32 APIs XP lacks. The CRT is jbuild's default - msvcrt.dll
-- (VC-LTL5) in Release, the static UCRT in Debug - matching the cmake presets' msvcrt default, so the two
-- build systems agree. These are the libraries the XP-targeting engine links.
xp_options { supportWinXP = "on" }

workspace "Dependencies"
	location ".jbuild"
	configurations { "Debug", "Release" }
	platforms (common_platforms())   -- --architecture (x86,x64,arm,arm64 / all); default x86,x64
	warnings "Default"

	-- ORDER IS LOAD-BEARING - see Common.lua. We ARE the dependency tree, so there is no
	-- dependencies_workspace()/galactic_workspace() here.
	common_workspace()
	xp_workspace()
	warnings_workspace()

-- --------------------------------------------------------------------------------------------
-- dep(name, opts) - one vendored static library. Produces <name>_static.lib (the name consumers
-- link), warnings off (third-party), into Lib\ via common_project(). opts:
--   dir          source root under the repo (default "Projects/<name>")
--   lang         "C" (default) or "C++"
--   ext          source extension to glob when `files` is not given (default "c")
--   files        explicit source list (overrides the glob)
--   removefiles  files to drop from the glob (e.g. a standalone main)
--   includedirs  compile include dirs (default { "<dir>/include" })
--   defines      preprocessor defines (all configurations)
--   debugdefines preprocessor defines, Debug only
--   systems      the targets it is built for (os.target(): windows, macosx, ios, android, linux, bsd);
--                every one when not given. Windows builds the solution; the rest are the Makefile's,
--                from the fragments `premake5 --os=<target> jbuildmake` writes (Make/<target>.mk).
local function dep(name, opts)
	opts = opts or {}
	if opts.systems and not table.contains(opts.systems, os.target()) then return end
	local dir = opts.dir or ("Projects/" .. name)

	-- The body shared by the static project and any shared (DLL) variant: sources, includes, defines,
	-- opts.extra(). A shared variant can override or extend the static source list (overrideFiles /
	-- addFiles - some DLLs build extra sources, a .def or an exports stub), and swap the static-only
	-- toggle for the export define: dropDefines removes entries from opts.defines (e.g. SDL2_STATIC,
	-- ASMJIT_STATIC), extraDefines adds the export macro. The shared build keeps every other define
	-- the static has, since those are the library's own build macros, needed by both.
	local function apply_body(overrideFiles, addFiles, extraDefines, dropDefines)
		location ".jbuild/Projects"
		common_project()
		warnings "Off"
		language(opts.lang or "C")

		includedirs(opts.includedirs or { dir .. "/include" })

		local baseFiles = overrideFiles or opts.files
		if baseFiles then
			files(baseFiles)
		else
			files { dir .. "/src/**." .. (opts.ext or "c") }
		end
		if addFiles then files(addFiles) end

		if opts.removefiles then removefiles(opts.removefiles) end

		if opts.defines then
			if dropDefines then
				local keep = {}
				for _, d in ipairs(opts.defines) do
					local drop = false
					for _, x in ipairs(dropDefines) do if d == x then drop = true break end end
					if not drop then keep[#keep + 1] = d end
				end
				defines(keep)
			else
				defines(opts.defines)
			end
		end
		if extraDefines then defines(extraDefines) end

		if opts.debugdefines then
			filter "configurations:Debug"
				defines(opts.debugdefines)
			filter {}
		end

		if opts.buildoptions then buildoptions(opts.buildoptions) end
		if opts.forceincludes then forceincludes(opts.forceincludes) end

		-- opts.extra(): a function run inside the project scope for anything the fields above do not
		-- cover (per-architecture flags, extra filters). It must reset its own filters.
		if opts.extra then opts.extra() end

		filter {}
	end

	-- Static library: project name "<name>_static" (what consumers link); opts.projname overrides it
	-- for the few libraries the tree links under a bare name (litehtml, gumbo).
	project(opts.projname or (name .. "_static"))
		kind "StaticLib"
		apply_body(nil, nil, nil)

	-- Shared (DLL) variant(s), matching the CMake build's new_library_shared. opts.shared is either a
	-- single export define (string) for a DLL built from the same sources as the static, or a list of
	-- specs { name=, defines=, dropdefines=, files=, addfiles=, extra= } for DLLs whose name or
	-- sources diverge from the static (FLAC/FLAC++, crypto/ssl, harfbuzz/harfbuzz-subset,
	-- vorbis/vorbisfile). YY-Thunks, the Windows subsystem and /OPT:REF come from xp_workspace()'s
	-- "not StaticLib" filter automatically. The DLL and its import library land in LINK_LIBRARIES
	-- beside the static libs. Windows' alone: the Makefile builds static libraries.
	if opts.shared and os.target() == "windows" then
		local specs = opts.shared
		if type(specs) == "string" then specs = { { defines = { specs } } } end
		for _, s in ipairs(specs) do
			project(s.name or name)
				kind "SharedLib"
				targetdir (LINK_LIBRARIES)
				apply_body(s.files, s.addfiles, s.defines, s.dropdefines)
				if s.extra then s.extra() end
				filter {}
		end
	end
end

-- "<dir>/<name>.<ext>" for each basename - keeps the long explicit source lists readable.
local function srcs(dir, names, ext)
	ext = ext or "c"
	local t = {}
	for _, n in ipairs(names) do t[#t + 1] = dir .. "/" .. n .. "." .. ext end
	return t
end

-- Where a library is built, for dep()'s systems. GUI: where there is a renderer to draw with.
local WINDOWS = { "windows" }
local GUI     = { "windows", "macosx", "ios", "android" }
local WINDOWS_TARGET = os.target() == "windows"
local IOS_TARGET = os.target() == "ios"

-- iOS has no system(); lua's os.execute and squirrel's system lib are its only callers here. A
-- force-included shim turns just those calls into a no-op ("no shell"), leaving everything else - and
-- the vendored source - untouched.
local IOS_NO_SYSTEM = IOS_TARGET and { "jbuild/make/support/ios_compat_shim.h" } or nil

-- --------------------------------------------------------------------------------------------
-- Cross-platform core libraries (the ones not behind if(WIN32) in Projects/CMakeLists.txt).

dep("zlib", { debugdefines = { "ZLIB_DEBUG=1" }, shared = "ZLIB_DLL" })

dep("bzip2", {
	includedirs = { "Projects/bzip2/src" },
	defines     = { "BZIP2_STATIC" },
	shared      = { { defines = { "BUILD_BZIP2_DLL", "BZ_EXPORT" }, dropdefines = { "BZIP2_STATIC" } } },
	files = {
		"Projects/bzip2/src/blocksort.c",
		"Projects/bzip2/src/bzlib.c",
		"Projects/bzip2/src/compress.c",
		"Projects/bzip2/src/crctable.c",
		"Projects/bzip2/src/decompress.c",
		"Projects/bzip2/src/huffman.c",
		"Projects/bzip2/src/randtable.c",
	},
})

-- png needs zlib's headers to compile, and the SSE2 path (x86/x64 both take the Intel branch).
-- The DLL is named libpng16 (CMake's RUNTIME_OUTPUT_NAME), keeping png.lib as its import library,
-- and compiles the version .rc. It links zlib's import library. Elsewhere pure C (no SSE/NEON
-- sources), so one compile works on any architecture, a universal arm64 + x86_64 Apple build included;
-- the optimisations are off by libpng's own documented macros.
local PNG_SOURCES = srcs("Projects/png/src", {
	"png", "pngerror", "pngget", "pngmem", "pngpread", "pngread", "pngrio", "pngrtran", "pngrutil",
	"pngset", "pngtrans", "pngwio", "pngwrite", "pngwtran", "pngwutil" })
if WINDOWS_TARGET then
	PNG_SOURCES[#PNG_SOURCES + 1] = "Projects/png/src/intel/intel_init.c"
	PNG_SOURCES[#PNG_SOURCES + 1] = "Projects/png/src/intel/filter_sse2_intrinsics.c"
end

dep("png", {
	includedirs = { "Projects/png/include", "Projects/png/src", "Projects/zlib/include" },
	defines     = WINDOWS_TARGET and { "PNG_INTEL_SSE_OPT=1" } or { "PNG_INTEL_SSE_OPT=0", "PNG_ARM_NEON_OPT=0" },
	shared = { {
		defines  = { "PNG_BUILD_DLL", "PNG_DLL" },
		addfiles = { "Projects/png/src/scripts/pngwin.rc" },
		extra    = function()
			targetname "libpng16"   -- DLL base name; targetsuffix still adds _d in Debug
			implibname "png"        -- consumers link png.lib (import library keeps the target name)
			links { "zlib" }
		end,
	} },
	files = PNG_SOURCES,
})

dep("tinyxml", { lang = "C++", ext = "cpp" })

dep("lua53", { dir = "Projects/lua5.3", shared = "LUA_BUILD_AS_DLL", forceincludes = IOS_NO_SYSTEM,
	removefiles = { "Projects/lua5.3/src/lua.c", "Projects/lua5.3/src/luac.c" } })

dep("lua54", { dir = "Projects/lua5.4", shared = "LUA_BUILD_AS_DLL", forceincludes = IOS_NO_SYSTEM,
	removefiles = { "Projects/lua5.4/src/lua.c", "Projects/lua5.4/src/luac.c" } })

-- squirrel/sqstdlib: UNICODE/_UNICODE already come from common_workspace()'s characterset "Unicode".
dep("squirrel", { lang = "C++", ext = "cpp" })
dep("sqstdlib", { lang = "C++", ext = "cpp", forceincludes = IOS_NO_SYSTEM,
	includedirs = { "Projects/sqstdlib/include", "Projects/squirrel/include" } })

dep("mongoose6", { includedirs = { "Projects/mongoose6/include/mongoose6" } })
dep("mongoose7", { includedirs = { "Projects/mongoose7/include/mongoose7" } })

-- sqlite: one translation unit. The version .rc is for the DLL only (RC_VERONLY gates it); a static
-- lib needs neither.
dep("sqlite3", { dir = "Projects/sqlite", files = { "Projects/sqlite/src/sqlite3.c" },
	shared = { {
		defines  = { "SQLITE_API=__declspec(dllexport)", "RC_VERONLY" },
		addfiles = { "Projects/sqlite/src/sqlite3.rc" },
	} } })

dep("enet", {
	includedirs = { "Projects/enet/src/include" },
	defines     = { "ENET_BUILDING_LIB", "HAS_SOCKLEN_T" },
	shared      = "ENET_DLL",
})

dep("RakNet", {
	lang        = "C++",
	includedirs = { "Projects/RakNet/src/DependentExtensions", "Projects/RakNet/src/Source" },
	defines     = { "_RAKNET_LIB" },
	shared      = { { defines = { "_RAKNET_DLL" }, dropdefines = { "_RAKNET_LIB" } } },
	files       = { "Projects/RakNet/src/Source/*.cpp", "Projects/RakNet/src/Source/*.h" },
})

-- --------------------------------------------------------------------------------------------
-- Media + font + misc libraries (the if(WIN32) set in Projects/CMakeLists.txt). This premake build
-- is Windows-only, so no per-library platform guard is needed - the Linux build is the Makefile.


-- ogg exports through its checked-in .def (no __declspec in the headers), and the DLL is named
-- libogg (CMake's prefix_lib), keeping ogg.lib as the import library.
-- ogg's os_types.h names the <stdint.h> types on Apple without including it, hence the forced include -
-- in vorbis too, which includes it.
local OGG_FORCEINCLUDES = not WINDOWS_TARGET and { "stdint.h" } or nil
dep("ogg", {
	includedirs = { "Projects/ogg/include", "Projects/ogg/src/include" },
	forceincludes = OGG_FORCEINCLUDES,
	files       = { "Projects/ogg/src/src/**.c" },
	shared = { { extra = function()
		targetname "libogg"
		implibname "ogg"
		linkoptions { '/DEF:"$(SolutionDir)..\\Projects\\ogg\\src\\win32\\ogg.def"' }
	end } },
})

dep("vorbis", {
	includedirs = { "Projects/vorbis/src/include", "Projects/vorbis/src/lib",
		"Projects/ogg/include", "Projects/ogg/src/include" },
	forceincludes = OGG_FORCEINCLUDES,
	-- Exports through its checked-in .def, as ogg (no __declspec in the headers).
	shared = { { defines = { "LIBVORBIS_EXPORTS" }, extra = function()
		links { "ogg" }
		linkoptions { '/DEF:"$(SolutionDir)..\\Projects\\vorbis\\src\\win32\\vorbis.def"' }
	end } },
	files = srcs("Projects/vorbis/src/lib", {
		"analysis", "bitrate", "block", "codebook", "envelope", "floor0", "floor1", "info",
		"lookup", "lpc", "lsp", "mapping0", "mdct", "psy", "registry", "res0", "sharedbook",
		"smallft", "synthesis", "vorbisenc", "window" }),
})

dep("vorbisfile", {
	includedirs = { "Projects/vorbis/src/include", "Projects/vorbis/src/lib",
		"Projects/ogg/include", "Projects/ogg/src/include" },
	forceincludes = OGG_FORCEINCLUDES,
	shared = { { defines = { "LIBVORBISFILE_EXPORTS" }, extra = function()
		links { "ogg", "vorbis" }
		linkoptions { '/DEF:"$(SolutionDir)..\\Projects\\vorbis\\src\\win32\\vorbisfile.def"' }
	end } },
	files = { "Projects/vorbis/src/lib/vorbisfile.c" },
})

dep("theora", {
	systems = WINDOWS,
	includedirs = { "Projects/theora/src/include", "Projects/theora/src/lib",
		"Projects/ogg/include", "Projects/ogg/src/include" },
	shared = { { defines = { "LIBTHEORA_EXPORTS" }, extra = function()
		links { "ogg" }
		linkoptions { '/DEF:"$(SolutionDir)..\\Projects\\theora\\libtheora.def"' }
	end } },
	files = (function()
		local t = srcs("Projects/theora/src/lib", {
			"cpu", "analyze", "encapiwrapper", "encfrag", "encinfo", "encode", "enquant", "fdct",
			"huffenc", "mathops", "mcenc", "rate", "tokenize", "apiwrapper", "bitpack",
			"decapiwrapper", "decinfo", "decode", "dequant", "fragment", "huffdec", "idct", "info",
			"internal", "quant", "state" })
		-- x86_vc MMX paths - internally #if-guarded (OC_X86_ASM), so they compile to nothing on x64.
		for _, f in ipairs(srcs("Projects/theora/src/lib/x86_vc", {
			"mmxencfrag", "mmxfdct", "x86enc", "mmxfrag", "mmxidct", "mmxstate", "x86state" })) do
			t[#t + 1] = f
		end
		return t
	end)(),
})

dep("freetype", {
	defines      = { "FT2_BUILD_LIBRARY" },
	debugdefines = { "FT_DEBUG_LEVEL_ERROR", "FT_DEBUG_LEVEL_TRACE" },
	-- Elsewhere bzip2's header too: SYSTEM_ZLIB and the bzip2 module are on in its ftoption.h.
	includedirs  = WINDOWS_TARGET and { "Projects/freetype/include", "Projects/png/include", "Projects/zlib/include" }
		or { "Projects/freetype/include", "Projects/zlib/include", "Projects/png/include", "Projects/bzip2/src" },
	-- CMake shared adds DLL_EXPORT to FT2_BUILD_LIBRARY; the DLL links png + zlib.
	shared       = { { defines = { "DLL_EXPORT" }, extra = function() links { "png", "zlib" } end } },
	files = (function()
		local t = srcs("Projects/freetype/src", {
			"autofit/autofit", "base/ftbase", "base/ftbbox", "base/ftbdf", "base/ftbitmap",
			"base/ftcid", "base/ftfstype", "base/ftgasp", "base/ftglyph", "base/ftgxval",
			"base/ftinit", "base/ftmm", "base/ftotval", "base/ftpatent", "base/ftpfr",
			"base/ftstroke", "base/ftsynth", "base/fttype1", "base/ftwinfnt", "bdf/bdf",
			"bzip2/ftbzip2", "cache/ftcache", "cff/cff", "cid/type1cid", "gzip/ftgzip",
			"lzw/ftlzw", "pcf/pcf", "pfr/pfr", "psaux/psaux", "pshinter/pshinter",
			"psnames/psnames", "raster/raster", "sdf/sdf", "sfnt/sfnt", "smooth/smooth",
			"svg/svg", "truetype/truetype", "type1/type1", "type42/type42", "winfonts/winfnt" })
		-- The system and debug backends: Windows' own, else the portable ones in src/base.
		local backend = WINDOWS_TARGET and "Projects/freetype/builds/windows/" or "Projects/freetype/src/base/"
		t[#t + 1] = backend .. "ftsystem.c"
		t[#t + 1] = backend .. "ftdebug.c"
		return t
	end)(),
})

-- harfbuzz uses its single amalgamated .cc; subset is its own library.
dep("harfbuzz", {
	systems = WINDOWS,
	lang        = "C++",
	defines     = { "HAVE_FREETYPE=1" },
	includedirs = { "Projects/harfbuzz/src", "Projects/freetype/include" },
	shared      = { { defines = { "HB_DLL_EXPORT" }, extra = function() links { "zlib", "freetype" } end } },
	files       = { "Projects/harfbuzz/src/harfbuzz.cc" },
})

dep("harfbuzz-subset", {
	systems = WINDOWS,
	lang        = "C++",
	defines     = { "HAVE_FREETYPE=1" },
	includedirs = { "Projects/harfbuzz/src", "Projects/freetype/include" },
	shared      = { { defines = { "HB_DLL_EXPORT" },
		extra = function() links { "harfbuzz", "zlib", "freetype" } end } },
	files = srcs("Projects/harfbuzz/src", {
		"hb-number", "hb-ot-cff1-table", "hb-ot-cff2-table", "hb-static", "hb-subset",
		"hb-subset-cff1", "hb-subset-cff2", "hb-subset-cff-common", "hb-subset-input",
		"hb-subset-plan" }, "cc"),
})

dep("glew", {
	systems = WINDOWS,
	defines = { "GLEW_EXPORTS", "GLEW_STATIC", "GLEW_BUILD" },
	files   = { "Projects/glew/src/glew.c" },
})

dep("jpeg", {
	systems = WINDOWS,
	includedirs = { "Projects/jpeg/include", "Projects/jpeg/src" },
	files = srcs("Projects/jpeg/src", {
		"jcapimin", "jcapistd", "jccoefct", "jccolor", "jcdctmgr", "jchuff", "jcinit", "jcmainct",
		"jcmarker", "jcmaster", "jcomapi", "jcparam", "jcphuff", "jcprepct", "jcsample", "jctrans",
		"jdapimin", "jdapistd", "jdatadst", "jdatasrc", "jdcoefct", "jdcolor", "jddctmgr", "jdhuff",
		"jdinput", "jdmainct", "jdmarker", "jdmaster", "jdmerge", "jdphuff", "jdpostct", "jdsample",
		"jdtrans", "jerror", "jfdctflt", "jfdctfst", "jfdctint", "jidctflt", "jidctfst", "jidctint",
		"jidctred", "jmemansi", "jmemmgr", "jquant1", "jquant2", "jutils", "rdbmp", "rdcolmap",
		"rdgif", "rdppm", "rdrle", "rdswitch", "rdtarga", "transupp", "wrbmp", "wrgif", "wrppm",
		"wrrle", "wrtarga" }),
})

dep("pcre2-8", {
	systems = WINDOWS,
	defines     = { "PCRE2_CODE_UNIT_WIDTH=8", "HAVE_CONFIG_H", "PCRE2_STATIC" },
	includedirs = { "Projects/pcre2/src/src", "Projects/pcre2", "Projects/pcre2/include" },
	shared      = { { defines = { "pcre2_8_EXPORTS" }, dropdefines = { "PCRE2_STATIC" } } },
	files = (function()
		local t = srcs("Projects/pcre2/src/src", {
			"pcre2_auto_possess", "pcre2_compile", "pcre2_config", "pcre2_context", "pcre2_convert",
			"pcre2_dfa_match", "pcre2_error", "pcre2_extuni", "pcre2_find_bracket", "pcre2_jit_compile",
			"pcre2_maketables", "pcre2_match", "pcre2_match_data", "pcre2_newline", "pcre2_ord2utf",
			"pcre2_pattern_info", "pcre2_serialize", "pcre2_string_utils", "pcre2_study",
			"pcre2_substitute", "pcre2_substring", "pcre2_tables", "pcre2_ucd", "pcre2_valid_utf",
			"pcre2_xclass" })
		t[#t + 1] = "Projects/pcre2/pcre2_chartables.c"
		return t
	end)(),
})

-- MinHook exports through its checked-in .def; the DLL also compiles its version .rc.
dep("MinHook", {
	systems = WINDOWS,
	shared = { {
		addfiles = { "Projects/MinHook/dll_resources/MinHook.rc" },
		extra = function()
			linkoptions { '/DEF:"$(SolutionDir)..\\Projects\\MinHook\\dll_resources\\MinHook.def"' }
		end,
	} },
})

dep("asmjit", {
	systems = WINDOWS,
	lang        = "C++",
	defines     = { "ASMJIT_STATIC" },
	includedirs = { "Projects/asmjit/src/src" },
	shared      = { { defines = { "ASMJIT_EXPORTS" }, dropdefines = { "ASMJIT_STATIC" } } },
	files       = { "Projects/asmjit/src/src/**.cpp" },
})

dep("discord-rpc", {
	systems = WINDOWS,
	lang        = "C++",
	defines     = { "DISCORD_BUILDING_SDK" },
	includedirs = { "Projects/discord-rpc/src/include", "Projects/rapidjson/include" },
	files       = { "Projects/discord-rpc/src/src/**.cpp" },
	removefiles = {
		"Projects/discord-rpc/src/src/dllmain.cpp",
		"Projects/discord-rpc/src/src/*_unix.cpp",
		"Projects/discord-rpc/src/src/*_linux.cpp",
	},
})

dep("zip", {
	systems = WINDOWS,
	defines     = { "ZIP_STATIC", "HAVE_CONFIG_H" },
	includedirs = { "Projects/libzip/src/include", "Projects/libzip", "Projects/zlib/include" },
	files       = { "Projects/libzip/src/lib/**.c" },
	removefiles = {
		"Projects/libzip/src/lib/zip_source_file.c",
		"Projects/libzip/src/lib/zip_algorithm_bzip2.c",
		"Projects/libzip/src/lib/zip_crypto_commoncrypto.c",
		"Projects/libzip/src/lib/zip_crypto_gnutls.c",
		"Projects/libzip/src/lib/zip_crypto_openssl.c",
		"Projects/libzip/src/lib/zip_random_unix.c",
		"Projects/libzip/src/lib/zip_random_uwp.c",
		"Projects/libzip/src/lib/zip_winzip_aes.c",
	},
})

-- SDL2: no config generation needed on Windows - the shipped SDL_config.h selects
-- SDL_config_windows.h on __WIN32__. Source root is src/src/; the general subsystem globs plus the
-- Windows backends, matching SDL/CMakeLists.txt. The EXTRA_LIBS (dinput8, ole32, ...) are the DLL's
-- link, which a consumer of the static lib provides itself.
-- On macOS SDL needs no configure either - SDL_config.h selects SDL_config_macosx.h. The cross-platform
-- core (NOT the blanket render/*/*.c, which would pull in Direct3D) plus the Cocoa / CoreAudio / Metal /
-- IOKit backends (.m is Objective-C). A consumer links the usual frameworks (jbuild/make/galactic.mk).
-- The shipped SDL_config_macosx.h enables EGL (for the ANGLE build); a native macOS SDL uses CGL/Metal,
-- so EGL is off (the config's #ifndef lets the define win).
local SDL_MAC = "Projects/SDL/src/src/"
dep("SDL2", {
	systems     = { "macosx" },
	dir         = "Projects/SDL",
	defines     = { "SDL2_BUILDING", "SDL2_STATIC", "HAVE_LIBC", "SDL_VIDEO_OPENGL_EGL=0", "SDL_VIDEO_RENDER_OGL_ES2=0" },
	includedirs = { "Projects/SDL/src/include" },
	files = srcs("Projects/SDL/src/src", {
		"*", "atomic/*", "audio/*", "cpuinfo/*", "dynapi/*", "events/*", "file/*", "haptic/*", "hidapi/*",
		"joystick/*", "libm/*", "locale/*", "misc/*", "power/*", "render/*", "sensor/*", "stdlib/*",
		"thread/*", "timer/*", "video/*", "video/yuv2rgb/*", "audio/dummy/*", "audio/disk/*",
		"joystick/virtual/*", "video/dummy/*", "video/offscreen/*", "sensor/dummy/*", "render/opengl/*",
		"render/software/*", "joystick/darwin/*", "joystick/hidapi/*", "haptic/darwin/*",
		"power/macosx/*", "timer/unix/*", "loadso/dlopen/*", "thread/pthread/*", "core/unix/*",
		"hidapi/mac/*" }),
	extra = function()
		files(srcs("Projects/SDL/src/src", {
			"audio/coreaudio/*", "video/cocoa/*", "render/metal/*", "joystick/iphoneos/*", "file/cocoa/*",
			"filesystem/cocoa/*", "locale/macosx/*", "misc/macosx/*" }, "m"))
		removefiles { SDL_MAC .. "video/SDL_egl.c", SDL_MAC .. "video/cocoa/SDL_cocoaopengles.m" }
	end,
})

dep("SDL2", {
	systems     = WINDOWS,
	dir         = "Projects/SDL",
	defines     = { "SDL2_BUILDING", "SDL2_STATIC", "HAVE_LIBC", "_WIN32_WINNT=_WIN32_WINNT_WINXP" },
	includedirs = { "Projects/SDL/src/include" },
	-- The DLL drops SDL2_STATIC for DLL_EXPORT, compiles the version .rc, and links the Win32 libraries
	-- the static lib's consumer would otherwise provide (SDL/CMakeLists.txt's EXTRA_LIBS).
	shared = { {
		defines     = { "DLL_EXPORT" },
		dropdefines = { "SDL2_STATIC" },
		addfiles    = { "Projects/SDL/src/src/main/windows/version.rc" },
		extra = function()
			links { "dinput8", "user32", "gdi32", "winmm", "imm32", "ole32", "oleaut32",
				"version", "uuid", "advapi32", "setupapi", "shell32" }
		end,
	} },
	files = {
		-- general (non-recursive globs, as in the CMake build)
		"Projects/SDL/src/src/*.c",
		"Projects/SDL/src/src/atomic/*.c", "Projects/SDL/src/src/audio/*.c",
		"Projects/SDL/src/src/cpuinfo/*.c", "Projects/SDL/src/src/dynapi/*.c",
		"Projects/SDL/src/src/events/*.c", "Projects/SDL/src/src/file/*.c",
		"Projects/SDL/src/src/joystick/*.c", "Projects/SDL/src/src/haptic/*.c",
		"Projects/SDL/src/src/hidapi/*.c", "Projects/SDL/src/src/libm/*.c",
		"Projects/SDL/src/src/locale/*.c", "Projects/SDL/src/src/misc/*.c",
		"Projects/SDL/src/src/power/*.c", "Projects/SDL/src/src/render/*.c",
		"Projects/SDL/src/src/render/*/*.c", "Projects/SDL/src/src/sensor/*.c",
		"Projects/SDL/src/src/stdlib/*.c", "Projects/SDL/src/src/thread/*.c",
		"Projects/SDL/src/src/timer/*.c", "Projects/SDL/src/src/video/*.c",
		"Projects/SDL/src/src/video/yuv2rgb/*.c",
		"Projects/SDL/src/src/audio/dummy/*.c", "Projects/SDL/src/src/audio/disk/*.c",
		"Projects/SDL/src/src/joystick/virtual/*.c",
		"Projects/SDL/src/src/video/dummy/*.c", "Projects/SDL/src/src/video/offscreen/*.c",
		-- Windows backends
		"Projects/SDL/src/src/core/windows/*.c", "Projects/SDL/src/src/misc/windows/*.c",
		"Projects/SDL/src/src/audio/winmm/*.c", "Projects/SDL/src/src/audio/directsound/*.c",
		"Projects/SDL/src/src/audio/wasapi/*.c", "Projects/SDL/src/src/video/windows/*.c",
		"Projects/SDL/src/src/thread/generic/SDL_syscond.c",
		"Projects/SDL/src/src/thread/windows/SDL_syscond_cv.c",
		"Projects/SDL/src/src/thread/windows/SDL_sysmutex.c",
		"Projects/SDL/src/src/thread/windows/SDL_syssem.c",
		"Projects/SDL/src/src/thread/windows/SDL_systhread.c",
		"Projects/SDL/src/src/thread/windows/SDL_systls.c",
		"Projects/SDL/src/src/sensor/windows/*.c",
		"Projects/SDL/src/src/power/windows/SDL_syspower.c",
		"Projects/SDL/src/src/locale/windows/*.c", "Projects/SDL/src/src/filesystem/windows/*.c",
		"Projects/SDL/src/src/timer/windows/*.c", "Projects/SDL/src/src/loadso/windows/*.c",
		"Projects/SDL/src/src/joystick/windows/*.c", "Projects/SDL/src/src/haptic/windows/*.c",
		-- HIDAPI's joystick drivers (CheckHIDAPI); hidapi/windows/hid.c is #included by SDL_hidapi.c.
		"Projects/SDL/src/src/joystick/hidapi/*.c",
	},
})

-- rapidjson is header-only (no library) - its headers are copied in the "headers" project below.

-- --------------------------------------------------------------------------------------------
-- headers: assemble include\ from each library's own headers, the way install_include() did under
-- CMake (consumers add $(jdependencies_home)\include and its mongoose6/lua5.3 subdirs). No library
-- install step is needed - common_project() already wrote the .lib into Lib\. Windows copies it all;
-- elsewhere the core set, and where there is a renderer SDL's (for the engine's input types, even
-- where SDL itself is not built), libressl's, RmlUi's and curl's.
headers_project {
	{ dir = "Projects/zlib/include" },
	{ file = "Projects/bzip2/src/bzlib.h" },
	{ dir = "Projects/png/include" },
	{ dir = "Projects/tinyxml/include" },
	{ dir = "Projects/lua5.3/include" },
	{ dir = "Projects/lua5.4/include" },
	{ dir = "Projects/squirrel/include" },
	{ dir = "Projects/sqstdlib/include" },
	{ dir = "Projects/mongoose6/include" },
	{ dir = "Projects/mongoose7/include" },
	{ dir = "Projects/sqlite/include" },
	{ dir = "Projects/enet/src/include" },
	{ files = "Projects/RakNet/src/Source/*.h", to = "RakNet" },
	-- media + font + misc
	{ dir = "Projects/ogg/include", systems = WINDOWS },
	{ dir = "Projects/ogg/src/include", systems = WINDOWS },
	{ dir = "Projects/vorbis/src/include", systems = WINDOWS },
	{ dir = "Projects/theora/src/include", systems = WINDOWS },
	{ dir = "Projects/freetype/include", systems = WINDOWS },
	{ dir = "Projects/glew/include", systems = WINDOWS },
	{ dir = "Projects/pcre2/include", systems = WINDOWS },
	{ files = "Projects/harfbuzz/src/*.h", systems = WINDOWS },
	{ dir = "Projects/jpeg/include", systems = WINDOWS },
	{ file = "Projects/jpeg/src/jmorecfg.h", systems = WINDOWS },
	{ file = "Projects/jpeg/src/jpeglib.h", systems = WINDOWS },
	{ file = "Projects/jpeg/src/jerror.h", systems = WINDOWS },
	-- misc
	{ dir = "Projects/MinHook/include", systems = WINDOWS },
	{ files = "Projects/asmjit/src/src/*.h", recursive = true, systems = WINDOWS },
	{ dir = "Projects/discord-rpc/src/include", systems = WINDOWS },
	{ dir = "Projects/libzip/src/include", systems = WINDOWS },
	{ dir = "Projects/rapidjson/include", systems = WINDOWS },
	{ dir = "Projects/SDL/src/include", systems = GUI },
	{ dir = "Projects/libressl/src/include", systems = GUI },
	-- graphics / network / UI
	{ dir = "Projects/curl/src/include", systems = GUI },
	{ dir = "Projects/pixman/include", systems = WINDOWS },
	{ dir = "Projects/cairo/include", systems = WINDOWS },
	{ dir = "Projects/litehtml/litehtml/include", systems = WINDOWS },
	{ dir = "Projects/litehtml/litehtml/src/gumbo/include", systems = WINDOWS },
	{ dir = "Projects/RmlUi/Include", systems = GUI },
	{ dir = "Projects/flac/src/include/FLAC", to = "FLAC", systems = WINDOWS },
	{ dir = "Projects/flac/src/include/FLAC++", to = "FLAC++", systems = WINDOWS },
	-- bsdiff + prebuilt bass/fmod headers
	{ dir = "Projects/bsdiff/src/include", systems = WINDOWS },
	{ file = "Projects/bass/src/c/bass.h", systems = WINDOWS },
	{ files = "Projects/fmod/src/inc/*.h*", systems = WINDOWS },
}
-- --------------------------------------------------------------------------------------------
-- The remaining Win32 / heavier libraries follow below (SDL, libressl, curl, cairo, pixman,
-- litehtml + gumbo, RmlUi, flac, bsdiff + libdivsufsort, and the prebuilt bass/fmod). Only lzma is
-- omitted - it is commented out in Projects/CMakeLists.txt.

-- --------------------------------------------------------------------------------------------
-- libressl: crypto + ssl (no tls lib). OPENSSL_NO_ASM, so no assembly, and the Windows build
-- needs no generated headers. crypto has an explicit 561-file list (extracted from the CMake);
-- ssl is a recursive glob. The shared builds export through a generated .def (libressl_def below);
-- static libs need none of that.
local libressl_defines = WINDOWS_TARGET and {
	"LIBRESSL_INTERNAL", "OPENSSL_NO_HW_PADLOCK", "__BEGIN_HIDDEN_DECLS=", "__END_HIDDEN_DECLS=",
	"_CRT_DEPRECATED_NO_WARNINGS", "_REENTRANT", "_POSIX_THREAD_SAFE_FUNCTIONS",
	"WIN32_LEAN_AND_MEAN", "_WIN32_WINNT=0x0501", "CPPFLAGS", "OPENSSL_NO_SPEED", "NO_SYSLOG",
	"NO_CRYPT", "inline=__inline", "HAVE_STRNLEN", "OPENSSL_NO_ASM", "SIZEOF_TIME_T=8",
} or {
	-- The libc of macOS, iOS and Android has these, so the compat headers use the system's.
	"LIBRESSL_INTERNAL", "OPENSSL_NO_HW_PADLOCK", "__BEGIN_HIDDEN_DECLS=", "__END_HIDDEN_DECLS=",
	"OPENSSL_NO_ASM", "SIZEOF_TIME_T=8",
	"HAVE_ASPRINTF", "HAVE_GETPAGESIZE", "HAVE_STRCASECMP", "HAVE_STRLCAT",
	"HAVE_STRLCPY", "HAVE_STRNDUP", "HAVE_STRNLEN", "HAVE_STRSEP", "HAVE_TIMEGM",
	"HAVE_ARC4RANDOM_BUF", "HAVE_GETENTROPY", "HAVE_TIMINGSAFE_BCMP",
	"HAVE_CLOCK_GETTIME", "HAVE_D_NAMLEN", "HAVE_D_TYPE", "HAVE_ERR_H", "HAVE_MEMMEM", "HAVE_POLL",
	"HAVE_READPASSPHRASE_H", "HAVE_STRTONUM",
}
-- crypto's platform sources: Windows' compat for what its CRT lacks, else the POSIX ones.
local LIBRESSL_PLATFORM_CRYPTO = srcs("Projects/libressl/src/crypto", WINDOWS_TARGET and {
	"bio/b_win", "ui/ui_openssl_win", "compat/posix_win", "compat/bsd-asprintf",
	"compat/getpagesize", "compat/strcasecmp", "compat/strlcat", "compat/strlcpy", "compat/strndup",
	"compat/strsep", "compat/timegm", "compat/explicit_bzero_win", "compat/arc4random",
	"compat/arc4random_uniform", "compat/getentropy_win", "compat/timingsafe_bcmp",
} or { "bio/b_posix", "ui/ui_openssl", "compat/explicit_bzero" })
local libressl_includes = {
	"Projects/libressl/src/include", "Projects/libressl/src/crypto",
	"Projects/libressl/src/include/compat", "Projects/libressl/src/crypto/asn1",
	"Projects/libressl/src/crypto/bn", "Projects/libressl/src/crypto/dsa",
	"Projects/libressl/src/crypto/evp", "Projects/libressl/src/crypto/modes",
	"Projects/libressl/src/ssl",
}

-- Mirrors the CMake export_symbol macro on Windows: build a module-definition (.def) from a libressl
-- .sym (newline-separated symbol names) as "EXPORTS\n" + the names, and feed it to /DEF. removeSyms
-- drops entries (crypto's CRYPTO_UNEXPORT), extraSyms are appended sorted (crypto's EXTRA_EXPORT).
-- The .def is written under .jbuild/gen (gitignored) each generate; returns an absolute path for /DEF.
local function libressl_def(name, symRelPath, removeSyms, extraSyms)
	local syms = {}
	for line in io.lines(path.getabsolute(symRelPath)) do
		local s = line:gsub("%s+$", "")
		if s ~= "" then
			local drop = false
			if removeSyms then
				for _, r in ipairs(removeSyms) do if s == r then drop = true break end end
			end
			if not drop then syms[#syms + 1] = s end
		end
	end
	if extraSyms then
		local ex = {}
		for _, e in ipairs(extraSyms) do ex[#ex + 1] = e end
		table.sort(ex)
		for _, e in ipairs(ex) do syms[#syms + 1] = e end
	end
	os.mkdir(path.getabsolute(".jbuild/gen"))
	local defPath = path.getabsolute(".jbuild/gen/" .. name .. ".def")
	local f = io.open(defPath, "w")
	f:write("EXPORTS\n")
	for _, s in ipairs(syms) do f:write(s .. "\n") end
	f:close()
	return defPath
end

-- crypto's symbol list minus BIO_s_log, plus the Windows compat exports the CMake appends.
local crypto_extra_export = {
	"gettimeofday", "posix_perror", "posix_fopen", "posix_fgets", "posix_open", "posix_rename",
	"posix_connect", "posix_close", "posix_read", "posix_write", "posix_getsockopt",
	"posix_setsockopt", "sleep", "asprintf", "vasprintf", "freezero", "reallocarray",
	"recallocarray", "strcasecmp", "strlcat", "strlcpy", "strndup", "strnlen", "strsep", "timegm",
	"explicit_bzero", "arc4random", "arc4random_buf", "arc4random_uniform", "getentropy",
	"timingsafe_bcmp", "timingsafe_memcmp",
}

dep("crypto", {
	systems     = GUI,
	defines     = libressl_defines,
	includedirs = libressl_includes,
	-- DLL is crypto-43 (major version from src/crypto/VERSION), import library crypto.lib. Exports via
	-- the generated .def; links the Win32 libs the CMake build names (ws2_32 is workspace-scope).
	shared = { { extra = function()
		targetname "crypto-43"
		implibname "crypto"
		links { "shell32", "comdlg32" }
		linkoptions { '/DEF:"' .. libressl_def("crypto",
			"Projects/libressl/src/crypto/crypto.sym", { "BIO_s_log" }, crypto_extra_export) .. '"' }
	end } },
	files = table.join({
		"Projects/libressl/src/crypto/aes/aes_cbc.c",
		"Projects/libressl/src/crypto/aes/aes_core.c",
		"Projects/libressl/src/crypto/camellia/camellia.c",
		"Projects/libressl/src/crypto/camellia/cmll_cbc.c",
		"Projects/libressl/src/crypto/rc4/rc4_enc.c",
		"Projects/libressl/src/crypto/rc4/rc4_skey.c",
		"Projects/libressl/src/crypto/whrlpool/wp_block.c",
		"Projects/libressl/src/crypto/cpt_err.c",
		"Projects/libressl/src/crypto/cryptlib.c",
		"Projects/libressl/src/crypto/crypto_init.c",
		"Projects/libressl/src/crypto/cversion.c",
		"Projects/libressl/src/crypto/ex_data.c",
		"Projects/libressl/src/crypto/malloc-wrapper.c",
		"Projects/libressl/src/crypto/mem_clr.c",
		"Projects/libressl/src/crypto/mem_dbg.c",
		"Projects/libressl/src/crypto/o_init.c",
		"Projects/libressl/src/crypto/o_str.c",
		"Projects/libressl/src/crypto/o_time.c",
		"Projects/libressl/src/crypto/aes/aes_cfb.c",
		"Projects/libressl/src/crypto/aes/aes_ctr.c",
		"Projects/libressl/src/crypto/aes/aes_ecb.c",
		"Projects/libressl/src/crypto/aes/aes_ige.c",
		"Projects/libressl/src/crypto/aes/aes_misc.c",
		"Projects/libressl/src/crypto/aes/aes_ofb.c",
		"Projects/libressl/src/crypto/aes/aes_wrap.c",
		"Projects/libressl/src/crypto/asn1/a_bitstr.c",
		"Projects/libressl/src/crypto/asn1/a_bool.c",
		"Projects/libressl/src/crypto/asn1/a_bytes.c",
		"Projects/libressl/src/crypto/asn1/a_d2i_fp.c",
		"Projects/libressl/src/crypto/asn1/a_digest.c",
		"Projects/libressl/src/crypto/asn1/a_dup.c",
		"Projects/libressl/src/crypto/asn1/a_enum.c",
		"Projects/libressl/src/crypto/asn1/a_i2d_fp.c",
		"Projects/libressl/src/crypto/asn1/a_int.c",
		"Projects/libressl/src/crypto/asn1/a_mbstr.c",
		"Projects/libressl/src/crypto/asn1/a_object.c",
		"Projects/libressl/src/crypto/asn1/a_octet.c",
		"Projects/libressl/src/crypto/asn1/a_print.c",
		"Projects/libressl/src/crypto/asn1/a_set.c",
		"Projects/libressl/src/crypto/asn1/a_sign.c",
		"Projects/libressl/src/crypto/asn1/a_strex.c",
		"Projects/libressl/src/crypto/asn1/a_strnid.c",
		"Projects/libressl/src/crypto/asn1/a_time.c",
		"Projects/libressl/src/crypto/asn1/a_time_tm.c",
		"Projects/libressl/src/crypto/asn1/a_type.c",
		"Projects/libressl/src/crypto/asn1/a_utf8.c",
		"Projects/libressl/src/crypto/asn1/a_verify.c",
		"Projects/libressl/src/crypto/asn1/ameth_lib.c",
		"Projects/libressl/src/crypto/asn1/asn1_err.c",
		"Projects/libressl/src/crypto/asn1/asn1_gen.c",
		"Projects/libressl/src/crypto/asn1/asn1_lib.c",
		"Projects/libressl/src/crypto/asn1/asn1_par.c",
		"Projects/libressl/src/crypto/asn1/asn_mime.c",
		"Projects/libressl/src/crypto/asn1/asn_moid.c",
		"Projects/libressl/src/crypto/asn1/asn_pack.c",
		"Projects/libressl/src/crypto/asn1/bio_asn1.c",
		"Projects/libressl/src/crypto/asn1/bio_ndef.c",
		"Projects/libressl/src/crypto/asn1/d2i_pr.c",
		"Projects/libressl/src/crypto/asn1/d2i_pu.c",
		"Projects/libressl/src/crypto/asn1/evp_asn1.c",
		"Projects/libressl/src/crypto/asn1/f_enum.c",
		"Projects/libressl/src/crypto/asn1/f_int.c",
		"Projects/libressl/src/crypto/asn1/f_string.c",
		"Projects/libressl/src/crypto/asn1/i2d_pr.c",
		"Projects/libressl/src/crypto/asn1/i2d_pu.c",
		"Projects/libressl/src/crypto/asn1/n_pkey.c",
		"Projects/libressl/src/crypto/asn1/nsseq.c",
		"Projects/libressl/src/crypto/asn1/p5_pbe.c",
		"Projects/libressl/src/crypto/asn1/p5_pbev2.c",
		"Projects/libressl/src/crypto/asn1/p8_pkey.c",
		"Projects/libressl/src/crypto/asn1/t_bitst.c",
		"Projects/libressl/src/crypto/asn1/t_crl.c",
		"Projects/libressl/src/crypto/asn1/t_pkey.c",
		"Projects/libressl/src/crypto/asn1/t_req.c",
		"Projects/libressl/src/crypto/asn1/t_spki.c",
		"Projects/libressl/src/crypto/asn1/t_x509.c",
		"Projects/libressl/src/crypto/asn1/t_x509a.c",
		"Projects/libressl/src/crypto/asn1/tasn_dec.c",
		"Projects/libressl/src/crypto/asn1/tasn_enc.c",
		"Projects/libressl/src/crypto/asn1/tasn_fre.c",
		"Projects/libressl/src/crypto/asn1/tasn_new.c",
		"Projects/libressl/src/crypto/asn1/tasn_prn.c",
		"Projects/libressl/src/crypto/asn1/tasn_typ.c",
		"Projects/libressl/src/crypto/asn1/tasn_utl.c",
		"Projects/libressl/src/crypto/asn1/x_algor.c",
		"Projects/libressl/src/crypto/asn1/x_attrib.c",
		"Projects/libressl/src/crypto/asn1/x_bignum.c",
		"Projects/libressl/src/crypto/asn1/x_crl.c",
		"Projects/libressl/src/crypto/asn1/x_exten.c",
		"Projects/libressl/src/crypto/asn1/x_info.c",
		"Projects/libressl/src/crypto/asn1/x_long.c",
		"Projects/libressl/src/crypto/asn1/x_name.c",
		"Projects/libressl/src/crypto/asn1/x_nx509.c",
		"Projects/libressl/src/crypto/asn1/x_pkey.c",
		"Projects/libressl/src/crypto/asn1/x_pubkey.c",
		"Projects/libressl/src/crypto/asn1/x_req.c",
		"Projects/libressl/src/crypto/asn1/x_sig.c",
		"Projects/libressl/src/crypto/asn1/x_spki.c",
		"Projects/libressl/src/crypto/asn1/x_val.c",
		"Projects/libressl/src/crypto/asn1/x_x509.c",
		"Projects/libressl/src/crypto/asn1/x_x509a.c",
		"Projects/libressl/src/crypto/bf/bf_cfb64.c",
		"Projects/libressl/src/crypto/bf/bf_ecb.c",
		"Projects/libressl/src/crypto/bf/bf_enc.c",
		"Projects/libressl/src/crypto/bf/bf_ofb64.c",
		"Projects/libressl/src/crypto/bf/bf_skey.c",
		"Projects/libressl/src/crypto/bio/b_dump.c",
		"Projects/libressl/src/crypto/bio/b_print.c",
		"Projects/libressl/src/crypto/bio/b_sock.c",
		"Projects/libressl/src/crypto/bio/bf_buff.c",
		"Projects/libressl/src/crypto/bio/bf_nbio.c",
		"Projects/libressl/src/crypto/bio/bf_null.c",
		"Projects/libressl/src/crypto/bio/bio_cb.c",
		"Projects/libressl/src/crypto/bio/bio_err.c",
		"Projects/libressl/src/crypto/bio/bio_lib.c",
		"Projects/libressl/src/crypto/bio/bio_meth.c",
		"Projects/libressl/src/crypto/bio/bss_acpt.c",
		"Projects/libressl/src/crypto/bio/bss_bio.c",
		"Projects/libressl/src/crypto/bio/bss_conn.c",
		"Projects/libressl/src/crypto/bio/bss_dgram.c",
		"Projects/libressl/src/crypto/bio/bss_fd.c",
		"Projects/libressl/src/crypto/bio/bss_file.c",
		"Projects/libressl/src/crypto/bio/bss_mem.c",
		"Projects/libressl/src/crypto/bio/bss_null.c",
		"Projects/libressl/src/crypto/bio/bss_sock.c",
		"Projects/libressl/src/crypto/bn/bn_add.c",
		"Projects/libressl/src/crypto/bn/bn_asm.c",
		"Projects/libressl/src/crypto/bn/bn_blind.c",
		"Projects/libressl/src/crypto/bn/bn_const.c",
		"Projects/libressl/src/crypto/bn/bn_ctx.c",
		"Projects/libressl/src/crypto/bn/bn_depr.c",
		"Projects/libressl/src/crypto/bn/bn_div.c",
		"Projects/libressl/src/crypto/bn/bn_err.c",
		"Projects/libressl/src/crypto/bn/bn_exp.c",
		"Projects/libressl/src/crypto/bn/bn_exp2.c",
		"Projects/libressl/src/crypto/bn/bn_gcd.c",
		"Projects/libressl/src/crypto/bn/bn_gf2m.c",
		"Projects/libressl/src/crypto/bn/bn_kron.c",
		"Projects/libressl/src/crypto/bn/bn_lib.c",
		"Projects/libressl/src/crypto/bn/bn_mod.c",
		"Projects/libressl/src/crypto/bn/bn_mont.c",
		"Projects/libressl/src/crypto/bn/bn_mpi.c",
		"Projects/libressl/src/crypto/bn/bn_mul.c",
		"Projects/libressl/src/crypto/bn/bn_nist.c",
		"Projects/libressl/src/crypto/bn/bn_prime.c",
		"Projects/libressl/src/crypto/bn/bn_print.c",
		"Projects/libressl/src/crypto/bn/bn_rand.c",
		"Projects/libressl/src/crypto/bn/bn_recp.c",
		"Projects/libressl/src/crypto/bn/bn_shift.c",
		"Projects/libressl/src/crypto/bn/bn_sqr.c",
		"Projects/libressl/src/crypto/bn/bn_sqrt.c",
		"Projects/libressl/src/crypto/bn/bn_word.c",
		"Projects/libressl/src/crypto/bn/bn_x931p.c",
		"Projects/libressl/src/crypto/buffer/buf_err.c",
		"Projects/libressl/src/crypto/buffer/buf_str.c",
		"Projects/libressl/src/crypto/buffer/buffer.c",
		"Projects/libressl/src/crypto/camellia/cmll_cfb.c",
		"Projects/libressl/src/crypto/camellia/cmll_ctr.c",
		"Projects/libressl/src/crypto/camellia/cmll_ecb.c",
		"Projects/libressl/src/crypto/camellia/cmll_misc.c",
		"Projects/libressl/src/crypto/camellia/cmll_ofb.c",
		"Projects/libressl/src/crypto/cast/c_cfb64.c",
		"Projects/libressl/src/crypto/cast/c_ecb.c",
		"Projects/libressl/src/crypto/cast/c_enc.c",
		"Projects/libressl/src/crypto/cast/c_ofb64.c",
		"Projects/libressl/src/crypto/cast/c_skey.c",
		"Projects/libressl/src/crypto/chacha/chacha.c",
		"Projects/libressl/src/crypto/cmac/cm_ameth.c",
		"Projects/libressl/src/crypto/cmac/cm_pmeth.c",
		"Projects/libressl/src/crypto/cmac/cmac.c",
		"Projects/libressl/src/crypto/comp/c_rle.c",
		"Projects/libressl/src/crypto/comp/c_zlib.c",
		"Projects/libressl/src/crypto/comp/comp_err.c",
		"Projects/libressl/src/crypto/comp/comp_lib.c",
		"Projects/libressl/src/crypto/conf/conf_api.c",
		"Projects/libressl/src/crypto/conf/conf_def.c",
		"Projects/libressl/src/crypto/conf/conf_err.c",
		"Projects/libressl/src/crypto/conf/conf_lib.c",
		"Projects/libressl/src/crypto/conf/conf_mall.c",
		"Projects/libressl/src/crypto/conf/conf_mod.c",
		"Projects/libressl/src/crypto/conf/conf_sap.c",
		"Projects/libressl/src/crypto/curve25519/curve25519-generic.c",
		"Projects/libressl/src/crypto/curve25519/curve25519.c",
		"Projects/libressl/src/crypto/des/cbc_cksm.c",
		"Projects/libressl/src/crypto/des/cbc_enc.c",
		"Projects/libressl/src/crypto/des/cfb64ede.c",
		"Projects/libressl/src/crypto/des/cfb64enc.c",
		"Projects/libressl/src/crypto/des/cfb_enc.c",
		"Projects/libressl/src/crypto/des/des_enc.c",
		"Projects/libressl/src/crypto/des/ecb3_enc.c",
		"Projects/libressl/src/crypto/des/ecb_enc.c",
		"Projects/libressl/src/crypto/des/ede_cbcm_enc.c",
		"Projects/libressl/src/crypto/des/enc_read.c",
		"Projects/libressl/src/crypto/des/enc_writ.c",
		"Projects/libressl/src/crypto/des/fcrypt.c",
		"Projects/libressl/src/crypto/des/fcrypt_b.c",
		"Projects/libressl/src/crypto/des/ofb64ede.c",
		"Projects/libressl/src/crypto/des/ofb64enc.c",
		"Projects/libressl/src/crypto/des/ofb_enc.c",
		"Projects/libressl/src/crypto/des/pcbc_enc.c",
		"Projects/libressl/src/crypto/des/qud_cksm.c",
		"Projects/libressl/src/crypto/des/rand_key.c",
		"Projects/libressl/src/crypto/des/set_key.c",
		"Projects/libressl/src/crypto/des/str2key.c",
		"Projects/libressl/src/crypto/des/xcbc_enc.c",
		"Projects/libressl/src/crypto/dh/dh_ameth.c",
		"Projects/libressl/src/crypto/dh/dh_asn1.c",
		"Projects/libressl/src/crypto/dh/dh_check.c",
		"Projects/libressl/src/crypto/dh/dh_depr.c",
		"Projects/libressl/src/crypto/dh/dh_err.c",
		"Projects/libressl/src/crypto/dh/dh_gen.c",
		"Projects/libressl/src/crypto/dh/dh_key.c",
		"Projects/libressl/src/crypto/dh/dh_lib.c",
		"Projects/libressl/src/crypto/dh/dh_pmeth.c",
		"Projects/libressl/src/crypto/dh/dh_prn.c",
		"Projects/libressl/src/crypto/dsa/dsa_ameth.c",
		"Projects/libressl/src/crypto/dsa/dsa_asn1.c",
		"Projects/libressl/src/crypto/dsa/dsa_depr.c",
		"Projects/libressl/src/crypto/dsa/dsa_err.c",
		"Projects/libressl/src/crypto/dsa/dsa_gen.c",
		"Projects/libressl/src/crypto/dsa/dsa_key.c",
		"Projects/libressl/src/crypto/dsa/dsa_lib.c",
		"Projects/libressl/src/crypto/dsa/dsa_meth.c",
		"Projects/libressl/src/crypto/dsa/dsa_ossl.c",
		"Projects/libressl/src/crypto/dsa/dsa_pmeth.c",
		"Projects/libressl/src/crypto/dsa/dsa_prn.c",
		"Projects/libressl/src/crypto/dsa/dsa_sign.c",
		"Projects/libressl/src/crypto/dsa/dsa_vrf.c",
		"Projects/libressl/src/crypto/dso/dso_dlfcn.c",
		"Projects/libressl/src/crypto/dso/dso_err.c",
		"Projects/libressl/src/crypto/dso/dso_lib.c",
		"Projects/libressl/src/crypto/dso/dso_null.c",
		"Projects/libressl/src/crypto/dso/dso_openssl.c",
		"Projects/libressl/src/crypto/ec/ec2_mult.c",
		"Projects/libressl/src/crypto/ec/ec2_oct.c",
		"Projects/libressl/src/crypto/ec/ec2_smpl.c",
		"Projects/libressl/src/crypto/ec/ec_ameth.c",
		"Projects/libressl/src/crypto/ec/ec_asn1.c",
		"Projects/libressl/src/crypto/ec/ec_check.c",
		"Projects/libressl/src/crypto/ec/ec_curve.c",
		"Projects/libressl/src/crypto/ec/ec_cvt.c",
		"Projects/libressl/src/crypto/ec/ec_err.c",
		"Projects/libressl/src/crypto/ec/ec_key.c",
		"Projects/libressl/src/crypto/ec/ec_lib.c",
		"Projects/libressl/src/crypto/ec/ec_mult.c",
		"Projects/libressl/src/crypto/ec/ec_oct.c",
		"Projects/libressl/src/crypto/ec/ec_pmeth.c",
		"Projects/libressl/src/crypto/ec/ec_print.c",
		"Projects/libressl/src/crypto/ec/eck_prn.c",
		"Projects/libressl/src/crypto/ec/ecp_mont.c",
		"Projects/libressl/src/crypto/ec/ecp_nist.c",
		"Projects/libressl/src/crypto/ec/ecp_oct.c",
		"Projects/libressl/src/crypto/ec/ecp_smpl.c",
		"Projects/libressl/src/crypto/ecdh/ech_err.c",
		"Projects/libressl/src/crypto/ecdh/ech_key.c",
		"Projects/libressl/src/crypto/ecdh/ech_lib.c",
		"Projects/libressl/src/crypto/ecdsa/ecs_asn1.c",
		"Projects/libressl/src/crypto/ecdsa/ecs_err.c",
		"Projects/libressl/src/crypto/ecdsa/ecs_lib.c",
		"Projects/libressl/src/crypto/ecdsa/ecs_ossl.c",
		"Projects/libressl/src/crypto/ecdsa/ecs_sign.c",
		"Projects/libressl/src/crypto/ecdsa/ecs_vrf.c",
		"Projects/libressl/src/crypto/engine/eng_all.c",
		"Projects/libressl/src/crypto/engine/eng_cnf.c",
		"Projects/libressl/src/crypto/engine/eng_ctrl.c",
		"Projects/libressl/src/crypto/engine/eng_dyn.c",
		"Projects/libressl/src/crypto/engine/eng_err.c",
		"Projects/libressl/src/crypto/engine/eng_fat.c",
		"Projects/libressl/src/crypto/engine/eng_init.c",
		"Projects/libressl/src/crypto/engine/eng_lib.c",
		"Projects/libressl/src/crypto/engine/eng_list.c",
		"Projects/libressl/src/crypto/engine/eng_openssl.c",
		"Projects/libressl/src/crypto/engine/eng_pkey.c",
		"Projects/libressl/src/crypto/engine/eng_table.c",
		"Projects/libressl/src/crypto/engine/tb_asnmth.c",
		"Projects/libressl/src/crypto/engine/tb_cipher.c",
		"Projects/libressl/src/crypto/engine/tb_dh.c",
		"Projects/libressl/src/crypto/engine/tb_digest.c",
		"Projects/libressl/src/crypto/engine/tb_dsa.c",
		"Projects/libressl/src/crypto/engine/tb_ecdh.c",
		"Projects/libressl/src/crypto/engine/tb_ecdsa.c",
		"Projects/libressl/src/crypto/engine/tb_pkmeth.c",
		"Projects/libressl/src/crypto/engine/tb_rand.c",
		"Projects/libressl/src/crypto/engine/tb_rsa.c",
		"Projects/libressl/src/crypto/engine/tb_store.c",
		"Projects/libressl/src/crypto/err/err.c",
		"Projects/libressl/src/crypto/err/err_all.c",
		"Projects/libressl/src/crypto/err/err_prn.c",
		"Projects/libressl/src/crypto/evp/bio_b64.c",
		"Projects/libressl/src/crypto/evp/bio_enc.c",
		"Projects/libressl/src/crypto/evp/bio_md.c",
		"Projects/libressl/src/crypto/evp/c_all.c",
		"Projects/libressl/src/crypto/evp/digest.c",
		"Projects/libressl/src/crypto/evp/e_aes.c",
		"Projects/libressl/src/crypto/evp/e_aes_cbc_hmac_sha1.c",
		"Projects/libressl/src/crypto/evp/e_bf.c",
		"Projects/libressl/src/crypto/evp/e_camellia.c",
		"Projects/libressl/src/crypto/evp/e_cast.c",
		"Projects/libressl/src/crypto/evp/e_chacha.c",
		"Projects/libressl/src/crypto/evp/e_chacha20poly1305.c",
		"Projects/libressl/src/crypto/evp/e_des.c",
		"Projects/libressl/src/crypto/evp/e_des3.c",
		"Projects/libressl/src/crypto/evp/e_gost2814789.c",
		"Projects/libressl/src/crypto/evp/e_idea.c",
		"Projects/libressl/src/crypto/evp/e_null.c",
		"Projects/libressl/src/crypto/evp/e_old.c",
		"Projects/libressl/src/crypto/evp/e_rc2.c",
		"Projects/libressl/src/crypto/evp/e_rc4.c",
		"Projects/libressl/src/crypto/evp/e_rc4_hmac_md5.c",
		"Projects/libressl/src/crypto/evp/e_xcbc_d.c",
		"Projects/libressl/src/crypto/evp/encode.c",
		"Projects/libressl/src/crypto/evp/evp_aead.c",
		"Projects/libressl/src/crypto/evp/evp_enc.c",
		"Projects/libressl/src/crypto/evp/evp_err.c",
		"Projects/libressl/src/crypto/evp/evp_key.c",
		"Projects/libressl/src/crypto/evp/evp_lib.c",
		"Projects/libressl/src/crypto/evp/evp_pbe.c",
		"Projects/libressl/src/crypto/evp/evp_pkey.c",
		"Projects/libressl/src/crypto/evp/m_dss.c",
		"Projects/libressl/src/crypto/evp/m_dss1.c",
		"Projects/libressl/src/crypto/evp/m_ecdsa.c",
		"Projects/libressl/src/crypto/evp/m_gost2814789.c",
		"Projects/libressl/src/crypto/evp/m_gostr341194.c",
		"Projects/libressl/src/crypto/evp/m_md4.c",
		"Projects/libressl/src/crypto/evp/m_md5.c",
		"Projects/libressl/src/crypto/evp/m_md5_sha1.c",
		"Projects/libressl/src/crypto/evp/m_null.c",
		"Projects/libressl/src/crypto/evp/m_ripemd.c",
		"Projects/libressl/src/crypto/evp/m_sha1.c",
		"Projects/libressl/src/crypto/evp/m_sigver.c",
		"Projects/libressl/src/crypto/evp/m_streebog.c",
		"Projects/libressl/src/crypto/evp/m_wp.c",
		"Projects/libressl/src/crypto/evp/names.c",
		"Projects/libressl/src/crypto/evp/p5_crpt.c",
		"Projects/libressl/src/crypto/evp/p5_crpt2.c",
		"Projects/libressl/src/crypto/evp/p_dec.c",
		"Projects/libressl/src/crypto/evp/p_enc.c",
		"Projects/libressl/src/crypto/evp/p_lib.c",
		"Projects/libressl/src/crypto/evp/p_open.c",
		"Projects/libressl/src/crypto/evp/p_seal.c",
		"Projects/libressl/src/crypto/evp/p_sign.c",
		"Projects/libressl/src/crypto/evp/p_verify.c",
		"Projects/libressl/src/crypto/evp/pmeth_fn.c",
		"Projects/libressl/src/crypto/evp/pmeth_gn.c",
		"Projects/libressl/src/crypto/evp/pmeth_lib.c",
		"Projects/libressl/src/crypto/gost/gost2814789.c",
		"Projects/libressl/src/crypto/gost/gost89_keywrap.c",
		"Projects/libressl/src/crypto/gost/gost89_params.c",
		"Projects/libressl/src/crypto/gost/gost89imit_ameth.c",
		"Projects/libressl/src/crypto/gost/gost89imit_pmeth.c",
		"Projects/libressl/src/crypto/gost/gost_asn1.c",
		"Projects/libressl/src/crypto/gost/gost_err.c",
		"Projects/libressl/src/crypto/gost/gostr341001.c",
		"Projects/libressl/src/crypto/gost/gostr341001_ameth.c",
		"Projects/libressl/src/crypto/gost/gostr341001_key.c",
		"Projects/libressl/src/crypto/gost/gostr341001_params.c",
		"Projects/libressl/src/crypto/gost/gostr341001_pmeth.c",
		"Projects/libressl/src/crypto/gost/gostr341194.c",
		"Projects/libressl/src/crypto/gost/streebog.c",
		"Projects/libressl/src/crypto/hkdf/hkdf.c",
		"Projects/libressl/src/crypto/hmac/hm_ameth.c",
		"Projects/libressl/src/crypto/hmac/hm_pmeth.c",
		"Projects/libressl/src/crypto/hmac/hmac.c",
		"Projects/libressl/src/crypto/idea/i_cbc.c",
		"Projects/libressl/src/crypto/idea/i_cfb64.c",
		"Projects/libressl/src/crypto/idea/i_ecb.c",
		"Projects/libressl/src/crypto/idea/i_ofb64.c",
		"Projects/libressl/src/crypto/idea/i_skey.c",
		"Projects/libressl/src/crypto/lhash/lh_stats.c",
		"Projects/libressl/src/crypto/lhash/lhash.c",
		"Projects/libressl/src/crypto/md4/md4_dgst.c",
		"Projects/libressl/src/crypto/md4/md4_one.c",
		"Projects/libressl/src/crypto/md5/md5_dgst.c",
		"Projects/libressl/src/crypto/md5/md5_one.c",
		"Projects/libressl/src/crypto/modes/cbc128.c",
		"Projects/libressl/src/crypto/modes/ccm128.c",
		"Projects/libressl/src/crypto/modes/cfb128.c",
		"Projects/libressl/src/crypto/modes/ctr128.c",
		"Projects/libressl/src/crypto/modes/cts128.c",
		"Projects/libressl/src/crypto/modes/gcm128.c",
		"Projects/libressl/src/crypto/modes/ofb128.c",
		"Projects/libressl/src/crypto/modes/xts128.c",
		"Projects/libressl/src/crypto/objects/o_names.c",
		"Projects/libressl/src/crypto/objects/obj_dat.c",
		"Projects/libressl/src/crypto/objects/obj_err.c",
		"Projects/libressl/src/crypto/objects/obj_lib.c",
		"Projects/libressl/src/crypto/objects/obj_xref.c",
		"Projects/libressl/src/crypto/ocsp/ocsp_asn.c",
		"Projects/libressl/src/crypto/ocsp/ocsp_cl.c",
		"Projects/libressl/src/crypto/ocsp/ocsp_err.c",
		"Projects/libressl/src/crypto/ocsp/ocsp_ext.c",
		"Projects/libressl/src/crypto/ocsp/ocsp_ht.c",
		"Projects/libressl/src/crypto/ocsp/ocsp_lib.c",
		"Projects/libressl/src/crypto/ocsp/ocsp_prn.c",
		"Projects/libressl/src/crypto/ocsp/ocsp_srv.c",
		"Projects/libressl/src/crypto/ocsp/ocsp_vfy.c",
		"Projects/libressl/src/crypto/pem/pem_all.c",
		"Projects/libressl/src/crypto/pem/pem_err.c",
		"Projects/libressl/src/crypto/pem/pem_info.c",
		"Projects/libressl/src/crypto/pem/pem_lib.c",
		"Projects/libressl/src/crypto/pem/pem_oth.c",
		"Projects/libressl/src/crypto/pem/pem_pk8.c",
		"Projects/libressl/src/crypto/pem/pem_pkey.c",
		"Projects/libressl/src/crypto/pem/pem_seal.c",
		"Projects/libressl/src/crypto/pem/pem_sign.c",
		"Projects/libressl/src/crypto/pem/pem_x509.c",
		"Projects/libressl/src/crypto/pem/pem_xaux.c",
		"Projects/libressl/src/crypto/pem/pvkfmt.c",
		"Projects/libressl/src/crypto/pkcs12/p12_add.c",
		"Projects/libressl/src/crypto/pkcs12/p12_asn.c",
		"Projects/libressl/src/crypto/pkcs12/p12_attr.c",
		"Projects/libressl/src/crypto/pkcs12/p12_crpt.c",
		"Projects/libressl/src/crypto/pkcs12/p12_crt.c",
		"Projects/libressl/src/crypto/pkcs12/p12_decr.c",
		"Projects/libressl/src/crypto/pkcs12/p12_init.c",
		"Projects/libressl/src/crypto/pkcs12/p12_key.c",
		"Projects/libressl/src/crypto/pkcs12/p12_kiss.c",
		"Projects/libressl/src/crypto/pkcs12/p12_mutl.c",
		"Projects/libressl/src/crypto/pkcs12/p12_npas.c",
		"Projects/libressl/src/crypto/pkcs12/p12_p8d.c",
		"Projects/libressl/src/crypto/pkcs12/p12_p8e.c",
		"Projects/libressl/src/crypto/pkcs12/p12_utl.c",
		"Projects/libressl/src/crypto/pkcs12/pk12err.c",
		"Projects/libressl/src/crypto/pkcs7/bio_pk7.c",
		"Projects/libressl/src/crypto/pkcs7/pk7_asn1.c",
		"Projects/libressl/src/crypto/pkcs7/pk7_attr.c",
		"Projects/libressl/src/crypto/pkcs7/pk7_doit.c",
		"Projects/libressl/src/crypto/pkcs7/pk7_lib.c",
		"Projects/libressl/src/crypto/pkcs7/pk7_mime.c",
		"Projects/libressl/src/crypto/pkcs7/pk7_smime.c",
		"Projects/libressl/src/crypto/pkcs7/pkcs7err.c",
		"Projects/libressl/src/crypto/poly1305/poly1305.c",
		"Projects/libressl/src/crypto/rand/rand_err.c",
		"Projects/libressl/src/crypto/rand/rand_lib.c",
		"Projects/libressl/src/crypto/rand/randfile.c",
		"Projects/libressl/src/crypto/rc2/rc2_cbc.c",
		"Projects/libressl/src/crypto/rc2/rc2_ecb.c",
		"Projects/libressl/src/crypto/rc2/rc2_skey.c",
		"Projects/libressl/src/crypto/rc2/rc2cfb64.c",
		"Projects/libressl/src/crypto/rc2/rc2ofb64.c",
		"Projects/libressl/src/crypto/ripemd/rmd_dgst.c",
		"Projects/libressl/src/crypto/ripemd/rmd_one.c",
		"Projects/libressl/src/crypto/rsa/rsa_ameth.c",
		"Projects/libressl/src/crypto/rsa/rsa_asn1.c",
		"Projects/libressl/src/crypto/rsa/rsa_chk.c",
		"Projects/libressl/src/crypto/rsa/rsa_crpt.c",
		"Projects/libressl/src/crypto/rsa/rsa_depr.c",
		"Projects/libressl/src/crypto/rsa/rsa_eay.c",
		"Projects/libressl/src/crypto/rsa/rsa_err.c",
		"Projects/libressl/src/crypto/rsa/rsa_gen.c",
		"Projects/libressl/src/crypto/rsa/rsa_lib.c",
		"Projects/libressl/src/crypto/rsa/rsa_meth.c",
		"Projects/libressl/src/crypto/rsa/rsa_none.c",
		"Projects/libressl/src/crypto/rsa/rsa_oaep.c",
		"Projects/libressl/src/crypto/rsa/rsa_pk1.c",
		"Projects/libressl/src/crypto/rsa/rsa_pmeth.c",
		"Projects/libressl/src/crypto/rsa/rsa_prn.c",
		"Projects/libressl/src/crypto/rsa/rsa_pss.c",
		"Projects/libressl/src/crypto/rsa/rsa_saos.c",
		"Projects/libressl/src/crypto/rsa/rsa_sign.c",
		"Projects/libressl/src/crypto/rsa/rsa_x931.c",
		"Projects/libressl/src/crypto/sha/sha1_one.c",
		"Projects/libressl/src/crypto/sha/sha1dgst.c",
		"Projects/libressl/src/crypto/sha/sha256.c",
		"Projects/libressl/src/crypto/sha/sha512.c",
		"Projects/libressl/src/crypto/stack/stack.c",
		"Projects/libressl/src/crypto/ts/ts_asn1.c",
		"Projects/libressl/src/crypto/ts/ts_conf.c",
		"Projects/libressl/src/crypto/ts/ts_err.c",
		"Projects/libressl/src/crypto/ts/ts_lib.c",
		"Projects/libressl/src/crypto/ts/ts_req_print.c",
		"Projects/libressl/src/crypto/ts/ts_req_utils.c",
		"Projects/libressl/src/crypto/ts/ts_rsp_print.c",
		"Projects/libressl/src/crypto/ts/ts_rsp_sign.c",
		"Projects/libressl/src/crypto/ts/ts_rsp_utils.c",
		"Projects/libressl/src/crypto/ts/ts_rsp_verify.c",
		"Projects/libressl/src/crypto/ts/ts_verify_ctx.c",
		"Projects/libressl/src/crypto/txt_db/txt_db.c",
		"Projects/libressl/src/crypto/ui/ui_err.c",
		"Projects/libressl/src/crypto/ui/ui_lib.c",
		"Projects/libressl/src/crypto/ui/ui_util.c",
		"Projects/libressl/src/crypto/whrlpool/wp_dgst.c",
		"Projects/libressl/src/crypto/x509/by_dir.c",
		"Projects/libressl/src/crypto/x509/by_file.c",
		"Projects/libressl/src/crypto/x509/by_mem.c",
		"Projects/libressl/src/crypto/x509/x509_att.c",
		"Projects/libressl/src/crypto/x509/x509_cmp.c",
		"Projects/libressl/src/crypto/x509/x509_d2.c",
		"Projects/libressl/src/crypto/x509/x509_def.c",
		"Projects/libressl/src/crypto/x509/x509_err.c",
		"Projects/libressl/src/crypto/x509/x509_ext.c",
		"Projects/libressl/src/crypto/x509/x509_lu.c",
		"Projects/libressl/src/crypto/x509/x509_obj.c",
		"Projects/libressl/src/crypto/x509/x509_r2x.c",
		"Projects/libressl/src/crypto/x509/x509_req.c",
		"Projects/libressl/src/crypto/x509/x509_set.c",
		"Projects/libressl/src/crypto/x509/x509_trs.c",
		"Projects/libressl/src/crypto/x509/x509_txt.c",
		"Projects/libressl/src/crypto/x509/x509_v3.c",
		"Projects/libressl/src/crypto/x509/x509_vfy.c",
		"Projects/libressl/src/crypto/x509/x509_vpm.c",
		"Projects/libressl/src/crypto/x509/x509cset.c",
		"Projects/libressl/src/crypto/x509/x509name.c",
		"Projects/libressl/src/crypto/x509/x509rset.c",
		"Projects/libressl/src/crypto/x509/x509spki.c",
		"Projects/libressl/src/crypto/x509/x509type.c",
		"Projects/libressl/src/crypto/x509/x_all.c",
		"Projects/libressl/src/crypto/x509v3/pcy_cache.c",
		"Projects/libressl/src/crypto/x509v3/pcy_data.c",
		"Projects/libressl/src/crypto/x509v3/pcy_lib.c",
		"Projects/libressl/src/crypto/x509v3/pcy_map.c",
		"Projects/libressl/src/crypto/x509v3/pcy_node.c",
		"Projects/libressl/src/crypto/x509v3/pcy_tree.c",
		"Projects/libressl/src/crypto/x509v3/v3_akey.c",
		"Projects/libressl/src/crypto/x509v3/v3_akeya.c",
		"Projects/libressl/src/crypto/x509v3/v3_alt.c",
		"Projects/libressl/src/crypto/x509v3/v3_bcons.c",
		"Projects/libressl/src/crypto/x509v3/v3_bitst.c",
		"Projects/libressl/src/crypto/x509v3/v3_conf.c",
		"Projects/libressl/src/crypto/x509v3/v3_cpols.c",
		"Projects/libressl/src/crypto/x509v3/v3_crld.c",
		"Projects/libressl/src/crypto/x509v3/v3_enum.c",
		"Projects/libressl/src/crypto/x509v3/v3_extku.c",
		"Projects/libressl/src/crypto/x509v3/v3_genn.c",
		"Projects/libressl/src/crypto/x509v3/v3_ia5.c",
		"Projects/libressl/src/crypto/x509v3/v3_info.c",
		"Projects/libressl/src/crypto/x509v3/v3_int.c",
		"Projects/libressl/src/crypto/x509v3/v3_lib.c",
		"Projects/libressl/src/crypto/x509v3/v3_ncons.c",
		"Projects/libressl/src/crypto/x509v3/v3_ocsp.c",
		"Projects/libressl/src/crypto/x509v3/v3_pci.c",
		"Projects/libressl/src/crypto/x509v3/v3_pcia.c",
		"Projects/libressl/src/crypto/x509v3/v3_pcons.c",
		"Projects/libressl/src/crypto/x509v3/v3_pku.c",
		"Projects/libressl/src/crypto/x509v3/v3_pmaps.c",
		"Projects/libressl/src/crypto/x509v3/v3_prn.c",
		"Projects/libressl/src/crypto/x509v3/v3_purp.c",
		"Projects/libressl/src/crypto/x509v3/v3_skey.c",
		"Projects/libressl/src/crypto/x509v3/v3_sxnet.c",
		"Projects/libressl/src/crypto/x509v3/v3_utl.c",
		"Projects/libressl/src/crypto/x509v3/v3err.c",
		"Projects/libressl/src/crypto/compat/freezero.c",
		"Projects/libressl/src/crypto/compat/reallocarray.c",
		"Projects/libressl/src/crypto/compat/recallocarray.c",
		"Projects/libressl/src/crypto/compat/timingsafe_memcmp.c",
	}, LIBRESSL_PLATFORM_CRYPTO),
})

dep("ssl", {
	systems     = GUI,
	defines     = libressl_defines,
	includedirs = libressl_includes,
	-- DLL is ssl-45 (src/ssl/VERSION), import library ssl.lib; exports via the generated .def and
	-- links the crypto DLL (ssl is layered on it) plus the CMake's Win32 libs.
	shared = { { extra = function()
		targetname "ssl-45"
		implibname "ssl"
		links { "crypto", "shell32", "comdlg32" }
		linkoptions { '/DEF:"' .. libressl_def("ssl", "Projects/libressl/src/ssl/ssl.sym") .. '"' }
	end } },
	files       = { "Projects/libressl/src/ssl/**.c" },
})

-- --------------------------------------------------------------------------------------------
-- Remaining from-source libraries: graphics / network / UI. Windows needs no generated headers.

-- macOS links the libcurl its SDK has; iOS has none, so there it is built from the vendored source, on
-- LibreSSL as here. curl takes its platform from a configure-made curl_config.h; Projects/curl/apple's
-- is one made by curl's own CMake on macOS (the two share a libc), with nothing in it about TLS or zlib -
-- those are the defines.
dep("curl", {
	systems = { "windows", "ios" },
	defines = not WINDOWS_TARGET and {
		"HAVE_CONFIG_H", "BUILDING_LIBCURL", "CURL_STATICLIB", "USE_OPENSSL", "HAVE_LIBZ", "HAVE_ZLIB_H",
		"CURL_DISABLE_FILE=1", "CURL_DISABLE_POP3=1", "CURL_DISABLE_IMAP=1", "CURL_DISABLE_SMTP=1",
		"CURL_DISABLE_OPENSSL_AUTO_LOAD_CONFIG",
	} or {
		"BUILDING_LIBCURL", "CURL_DISABLE_LDAP=1", "CURL_DISABLE_LDAPS=1", "CURL_DISABLE_FILE=1",
		"CURL_DISABLE_POP3=1", "CURL_DISABLE_IMAP=1", "CURL_DISABLE_SMTP=1", "USE_WEBSOCKETS=1",
		"CURL_DISABLE_OPENSSL_AUTO_LOAD_CONFIG", "HAVE_WINDOWS_H", "HAVE_WINSOCK_H",
		"HAVE_WS2TCPIP_H", "HAVE_WINSOCK2_H", "HAVE_ZLIB_H", "HAVE_ZLIB", "HAVE_LIBZ", "USE_IPV6",
		"CURL_STATICLIB", "USE_SSLEAY", "USE_OPENSSL",
	},
	includedirs = table.join(not WINDOWS_TARGET and { "Projects/curl/apple" } or {},
		{ "Projects/curl/src/include", "Projects/curl/src/lib",
		"Projects/libressl/src/include", "Projects/zlib/include" }),
	-- The DLL drops CURL_STATICLIB, compiles the version .rc, and links the ssl/crypto/zlib DLLs
	-- (wldap32/ws2_32/crypt32 are already workspace-scope).
	shared = { {
		dropdefines = { "CURL_STATICLIB" },
		addfiles    = { "Projects/curl/src/lib/**.rc" },
		extra       = function() links { "ssl", "crypto", "zlib" } end,
	} },
	files = WINDOWS_TARGET and { "Projects/curl/src/lib/**.c" } or {
		"Projects/curl/src/lib/*.c", "Projects/curl/src/lib/vauth/*.c", "Projects/curl/src/lib/vquic/*.c",
		"Projects/curl/src/lib/vssh/*.c", "Projects/curl/src/lib/vtls/*.c" },
})

dep("pixman", {
	systems = WINDOWS,
	includedirs = { "Projects/pixman/include", "Projects/pixman/src/pixman" },
	defines = { "PIXMAN_NO_TLS", "PACKAGE=\"pixman\"", "PACKAGE_VERSION=\"0.38.0\"", "PACKAGE_BUGREPORT=\"\"" },
	files = {
		"Projects/pixman/src/pixman/pixman.c",
		"Projects/pixman/src/pixman/pixman-access.c",
		"Projects/pixman/src/pixman/pixman-access-accessors.c",
		"Projects/pixman/src/pixman/pixman-bits-image.c",
		"Projects/pixman/src/pixman/pixman-combine32.c",
		"Projects/pixman/src/pixman/pixman-combine-float.c",
		"Projects/pixman/src/pixman/pixman-conical-gradient.c",
		"Projects/pixman/src/pixman/pixman-filter.c",
		"Projects/pixman/src/pixman/pixman-x86.c",
		"Projects/pixman/src/pixman/pixman-mips.c",
		"Projects/pixman/src/pixman/pixman-arm.c",
		"Projects/pixman/src/pixman/pixman-ppc.c",
		"Projects/pixman/src/pixman/pixman-edge.c",
		"Projects/pixman/src/pixman/pixman-edge-accessors.c",
		"Projects/pixman/src/pixman/pixman-fast-path.c",
		"Projects/pixman/src/pixman/pixman-glyph.c",
		"Projects/pixman/src/pixman/pixman-general.c",
		"Projects/pixman/src/pixman/pixman-gradient-walker.c",
		"Projects/pixman/src/pixman/pixman-image.c",
		"Projects/pixman/src/pixman/pixman-implementation.c",
		"Projects/pixman/src/pixman/pixman-linear-gradient.c",
		"Projects/pixman/src/pixman/pixman-matrix.c",
		"Projects/pixman/src/pixman/pixman-noop.c",
		"Projects/pixman/src/pixman/pixman-radial-gradient.c",
		"Projects/pixman/src/pixman/pixman-region16.c",
		"Projects/pixman/src/pixman/pixman-region32.c",
		"Projects/pixman/src/pixman/pixman-solid-fill.c",
		"Projects/pixman/src/pixman/pixman-timer.c",
		"Projects/pixman/src/pixman/pixman-trap.c",
		"Projects/pixman/src/pixman/pixman-utils.c",
	},
})

dep("cairo", {
	systems = WINDOWS,
	defines = { "CAIRO_WIN32_STATIC_BUILD", "HAVE_FT_GLYPHSLOT_EMBOLDEN=1",
		"HAVE_FT_LIBRARY_SETLCDFILTER=1", "HAVE_FT_GLYPHSLOT_OBLIQUE=1", "HAVE_FT_LOAD_SFNT_TABLE=1",
		"HAVE_FT_GET_X11_FONT_FORMAT=1" },
	includedirs = { "Projects/cairo/include", "Projects/cairo/src/src", "Projects/pixman/include",
		"Projects/pixman/src/pixman", "Projects/freetype/include", "Projects/png/include",
		"Projects/zlib/include" },
	-- The DLL drops the static-build toggle; cairo's headers then export. It links msimg32, the
	-- zlib/png/freetype DLLs and the pixman static lib (pixman has no shared build).
	shared = { { dropdefines = { "CAIRO_WIN32_STATIC_BUILD" },
		extra = function() links { "msimg32", "zlib", "png", "freetype", "pixman_static" } end } },
	files = {
		"Projects/cairo/src/src/cairo-analysis-surface.c",
		"Projects/cairo/src/src/cairo-arc.c",
		"Projects/cairo/src/src/cairo-array.c",
		"Projects/cairo/src/src/cairo-atomic.c",
		"Projects/cairo/src/src/cairo-base64-stream.c",
		"Projects/cairo/src/src/cairo-base85-stream.c",
		"Projects/cairo/src/src/cairo-bentley-ottmann.c",
		"Projects/cairo/src/src/cairo-bentley-ottmann-rectangular.c",
		"Projects/cairo/src/src/cairo-bentley-ottmann-rectilinear.c",
		"Projects/cairo/src/src/cairo-botor-scan-converter.c",
		"Projects/cairo/src/src/cairo-boxes.c",
		"Projects/cairo/src/src/cairo-boxes-intersect.c",
		"Projects/cairo/src/src/cairo.c",
		"Projects/cairo/src/src/cairo-cache.c",
		"Projects/cairo/src/src/cairo-clip.c",
		"Projects/cairo/src/src/cairo-clip-boxes.c",
		"Projects/cairo/src/src/cairo-clip-polygon.c",
		"Projects/cairo/src/src/cairo-clip-region.c",
		"Projects/cairo/src/src/cairo-clip-surface.c",
		"Projects/cairo/src/src/cairo-color.c",
		"Projects/cairo/src/src/cairo-composite-rectangles.c",
		"Projects/cairo/src/src/cairo-compositor.c",
		"Projects/cairo/src/src/cairo-contour.c",
		"Projects/cairo/src/src/cairo-damage.c",
		"Projects/cairo/src/src/cairo-debug.c",
		"Projects/cairo/src/src/cairo-default-context.c",
		"Projects/cairo/src/src/cairo-device.c",
		"Projects/cairo/src/src/cairo-error.c",
		"Projects/cairo/src/src/cairo-fallback-compositor.c",
		"Projects/cairo/src/src/cairo-fixed.c",
		"Projects/cairo/src/src/cairo-font-face.c",
		"Projects/cairo/src/src/cairo-font-face-twin.c",
		"Projects/cairo/src/src/cairo-font-face-twin-data.c",
		"Projects/cairo/src/src/cairo-font-options.c",
		"Projects/cairo/src/src/cairo-freelist.c",
		"Projects/cairo/src/src/cairo-freed-pool.c",
		"Projects/cairo/src/src/cairo-gstate.c",
		"Projects/cairo/src/src/cairo-hash.c",
		"Projects/cairo/src/src/cairo-hull.c",
		"Projects/cairo/src/src/cairo-image-compositor.c",
		"Projects/cairo/src/src/cairo-image-info.c",
		"Projects/cairo/src/src/cairo-image-source.c",
		"Projects/cairo/src/src/cairo-image-surface.c",
		"Projects/cairo/src/src/cairo-line.c",
		"Projects/cairo/src/src/cairo-lzw.c",
		"Projects/cairo/src/src/cairo-matrix.c",
		"Projects/cairo/src/src/cairo-mask-compositor.c",
		"Projects/cairo/src/src/cairo-mesh-pattern-rasterizer.c",
		"Projects/cairo/src/src/cairo-mempool.c",
		"Projects/cairo/src/src/cairo-misc.c",
		"Projects/cairo/src/src/cairo-mono-scan-converter.c",
		"Projects/cairo/src/src/cairo-mutex.c",
		"Projects/cairo/src/src/cairo-no-compositor.c",
		"Projects/cairo/src/src/cairo-observer.c",
		"Projects/cairo/src/src/cairo-output-stream.c",
		"Projects/cairo/src/src/cairo-paginated-surface.c",
		"Projects/cairo/src/src/cairo-path-bounds.c",
		"Projects/cairo/src/src/cairo-path.c",
		"Projects/cairo/src/src/cairo-path-fill.c",
		"Projects/cairo/src/src/cairo-path-fixed.c",
		"Projects/cairo/src/src/cairo-path-in-fill.c",
		"Projects/cairo/src/src/cairo-path-stroke.c",
		"Projects/cairo/src/src/cairo-path-stroke-boxes.c",
		"Projects/cairo/src/src/cairo-path-stroke-polygon.c",
		"Projects/cairo/src/src/cairo-path-stroke-traps.c",
		"Projects/cairo/src/src/cairo-path-stroke-tristrip.c",
		"Projects/cairo/src/src/cairo-pattern.c",
		"Projects/cairo/src/src/cairo-pen.c",
		"Projects/cairo/src/src/cairo-polygon.c",
		"Projects/cairo/src/src/cairo-polygon-intersect.c",
		"Projects/cairo/src/src/cairo-polygon-reduce.c",
		"Projects/cairo/src/src/cairo-raster-source-pattern.c",
		"Projects/cairo/src/src/cairo-recording-surface.c",
		"Projects/cairo/src/src/cairo-rectangle.c",
		"Projects/cairo/src/src/cairo-rectangular-scan-converter.c",
		"Projects/cairo/src/src/cairo-region.c",
		"Projects/cairo/src/src/cairo-rtree.c",
		"Projects/cairo/src/src/cairo-scaled-font.c",
		"Projects/cairo/src/src/cairo-shape-mask-compositor.c",
		"Projects/cairo/src/src/cairo-slope.c",
		"Projects/cairo/src/src/cairo-spans.c",
		"Projects/cairo/src/src/cairo-spans-compositor.c",
		"Projects/cairo/src/src/cairo-spline.c",
		"Projects/cairo/src/src/cairo-stroke-dash.c",
		"Projects/cairo/src/src/cairo-stroke-style.c",
		"Projects/cairo/src/src/cairo-surface.c",
		"Projects/cairo/src/src/cairo-surface-clipper.c",
		"Projects/cairo/src/src/cairo-surface-fallback.c",
		"Projects/cairo/src/src/cairo-surface-observer.c",
		"Projects/cairo/src/src/cairo-surface-offset.c",
		"Projects/cairo/src/src/cairo-surface-snapshot.c",
		"Projects/cairo/src/src/cairo-surface-subsurface.c",
		"Projects/cairo/src/src/cairo-surface-wrapper.c",
		"Projects/cairo/src/src/cairo-time.c",
		"Projects/cairo/src/src/cairo-tor-scan-converter.c",
		"Projects/cairo/src/src/cairo-tor22-scan-converter.c",
		"Projects/cairo/src/src/cairo-clip-tor-scan-converter.c",
		"Projects/cairo/src/src/cairo-tag-attributes.c",
		"Projects/cairo/src/src/cairo-tag-stack.c",
		"Projects/cairo/src/src/cairo-toy-font-face.c",
		"Projects/cairo/src/src/cairo-traps.c",
		"Projects/cairo/src/src/cairo-tristrip.c",
		"Projects/cairo/src/src/cairo-traps-compositor.c",
		"Projects/cairo/src/src/cairo-unicode.c",
		"Projects/cairo/src/src/cairo-user-font.c",
		"Projects/cairo/src/src/cairo-version.c",
		"Projects/cairo/src/src/cairo-wideint.c",
		"Projects/cairo/src/src/cairo-cff-subset.c",
		"Projects/cairo/src/src/cairo-scaled-font-subsets.c",
		"Projects/cairo/src/src/cairo-truetype-subset.c",
		"Projects/cairo/src/src/cairo-type1-fallback.c",
		"Projects/cairo/src/src/cairo-type1-glyph-names.c",
		"Projects/cairo/src/src/cairo-type1-subset.c",
		"Projects/cairo/src/src/cairo-type3-glyph-surface.c",
		"Projects/cairo/src/src/cairo-pdf-interchange.c",
		"Projects/cairo/src/src/cairo-pdf-operators.c",
		"Projects/cairo/src/src/cairo-pdf-shading.c",
		"Projects/cairo/src/src/cairo-pdf-surface.c",
		"Projects/cairo/src/src/cairo-png.c",
		"Projects/cairo/src/src/cairo-ps-surface.c",
		"Projects/cairo/src/src/cairo-deflate-stream.c",
		"Projects/cairo/src/src/cairo-svg-surface.c",
		"Projects/cairo/src/src/cairo-script-surface.c",
		"Projects/cairo/src/src/cairo-ft-font.c",
		"Projects/cairo/src/src/win32/cairo-win32-debug.c",
		"Projects/cairo/src/src/win32/cairo-win32-device.c",
		"Projects/cairo/src/src/win32/cairo-win32-gdi-compositor.c",
		"Projects/cairo/src/src/win32/cairo-win32-system.c",
		"Projects/cairo/src/src/win32/cairo-win32-surface.c",
		"Projects/cairo/src/src/win32/cairo-win32-display-surface.c",
		"Projects/cairo/src/src/win32/cairo-win32-printing-surface.c",
		"Projects/cairo/src/src/win32/cairo-win32-font.c",
	},
})

dep("litehtml", {
	systems = WINDOWS,
	projname = "litehtml", lang = "C++",
	includedirs = { "Projects/litehtml/litehtml/include",
		"Projects/litehtml/litehtml/include/litehtml",
		"Projects/litehtml/litehtml/src/gumbo/include",
		"Projects/litehtml/litehtml/src/gumbo/visualc/include" },
	files = { "Projects/litehtml/litehtml/src/*.cpp" },
})

dep("gumbo", {
	systems = WINDOWS,
	projname = "gumbo",
	includedirs = { "Projects/litehtml/litehtml/src/gumbo",
		"Projects/litehtml/litehtml/src/gumbo/include",
		"Projects/litehtml/litehtml/src/gumbo/include/gumbo",
		"Projects/litehtml/litehtml/src/gumbo/visualc/include" },
	files = { "Projects/litehtml/litehtml/src/gumbo/*.c" },
})

dep("rmlui_core", {
	systems = GUI,
	lang = "C++",
	defines = { "RMLUI_VERSION=\"6.2\"", "RMLUI_FONT_ENGINE_FREETYPE", "RMLUI_STATIC_LIB" },
	includedirs = { "Projects/RmlUi/Include", "Projects/freetype/include" },
	files = { "Projects/RmlUi/Source/Core/**.cpp" },
})

dep("rmlui_debugger", {
	systems = GUI,
	lang = "C++",
	defines = { "RMLUI_VERSION=\"6.2\"", "RMLUI_FONT_ENGINE_FREETYPE", "RMLUI_STATIC_LIB" },
	includedirs = { "Projects/RmlUi/Include", "Projects/freetype/include" },
	files = { "Projects/RmlUi/Source/Debugger/**.cpp" },
})

-- NASM, for flac's x86 assembly: on the PATH, else where its installer puts it (as CMake finds it).
local function nasm_path()
	local found = os.pathsearch("nasm.exe", os.getenv("PATH"))
	if found then return path.join(found, "nasm.exe") end
	for _, var in ipairs({ "ProgramFiles", "ProgramW6432", "LOCALAPPDATA" }) do
		local dir = os.getenv(var)
		local candidate = dir and path.join(dir, var == "LOCALAPPDATA" and "bin/NASM/nasm.exe" or "NASM/nasm.exe")
		if candidate and os.isfile(candidate) then return candidate end
	end
	return "nasm.exe"
end

-- flac: C + x86 intrinsics (FLAC__HAS_X86INTRIN), and on x86 the ia32 .nasm assembly too, as the CMake
-- build had it - this flac's cpu.c calls FLAC__cpu_info_asm_ia32 on x86 whether or not it has NASM.
dep("FLAC", {
	systems = WINDOWS,
	defines = { "FLAC__NO_DLL", "PACKAGE_VERSION=\"1.3.2\"", "FLAC__HAS_OGG", "FLAC__ALIGN_MALLOC_DATA",
		"HAVE_LROUND", "FLAC__SSE_OS", "FLAC__HAS_X86INTRIN" },
	debugdefines = { "FLAC__OVERFLOW_DETECT" },
	includedirs = { "Projects/flac/src/include", "Projects/flac/src/src/libFLAC/include",
		"Projects/ogg/include", "Projects/ogg/src/include" },
	shared = { { defines = { "FLAC_API_EXPORTS" }, dropdefines = { "FLAC__NO_DLL" },
		extra = function() links { "ogg" } end } },
	files = { "Projects/flac/src/src/libFLAC/*.c",
		"Projects/flac/src/src/share/win_utf8_io/win_utf8_io.c" },
	extra = function()
		filter "architecture:x86"
			defines { "FLAC__CPU_IA32", "FLAC__HAS_NASM" }
			files { "Projects/flac/src/src/libFLAC/ia32/cpu_asm.nasm",
				"Projects/flac/src/src/libFLAC/ia32/fixed_asm.nasm",
				"Projects/flac/src/src/libFLAC/ia32/lpc_asm.nasm" }
		filter { "architecture:x86", "files:**.nasm" }
			buildmessage "%{file.name}"
			buildcommands { '"' .. nasm_path() .. '" -i"%{file.directory}/" -f win32 -d OBJ_FORMAT_win32 -o "%{cfg.objdir}/%{file.basename}.obj" "%{file.relpath}"' }
			buildoutputs { "%{cfg.objdir}/%{file.basename}.obj" }
		filter "architecture:x86_64"
			defines { "FLAC__CPU_X86_64", "ENABLE_64_BIT_WORDS" }
		filter {}
	end,
})

dep("FLAC++", {
	systems = WINDOWS,
	lang = "C++",
	defines = { "FLAC__NO_DLL" },
	includedirs = { "Projects/flac/src/include", "Projects/flac/src/src/libFLAC/include" },
	shared = { { defines = { "FLACPP_API_EXPORTS" }, dropdefines = { "FLAC__NO_DLL" },
		extra = function() links { "FLAC" } end } },
	files = { "Projects/flac/src/src/libFLAC++/*.cpp" },
})

-- --------------------------------------------------------------------------------------------
-- bsdiff + libdivsufsort. The divsufsort headers (config.h/divsufsort.h/divsufsort64.h) are
-- pre-generated into libdivsufsort/include (the CMake configure step, done once for Windows).
-- divsufsort and divsufsort64 are the SAME lib sources, the 64-bit one with -DBUILD_DIVSUFSORT64.
dep("divsufsort", {
	systems = WINDOWS,
	projname    = "divsufsort",
	defines     = { "HAVE_CONFIG_H" },
	includedirs = { "Projects/bsdiff/src/3rdparty/libdivsufsort/include" },
	files       = { "Projects/bsdiff/src/3rdparty/libdivsufsort/lib/*.c" },
})

dep("divsufsort64", {
	systems = WINDOWS,
	projname    = "divsufsort64",
	defines     = { "HAVE_CONFIG_H", "BUILD_DIVSUFSORT64" },
	includedirs = { "Projects/bsdiff/src/3rdparty/libdivsufsort/include" },
	files       = { "Projects/bsdiff/src/3rdparty/libdivsufsort/lib/*.c" },
})

dep("bsdiff", {
	systems = WINDOWS,
	includedirs = { "Projects/bzip2/src", "Projects/bsdiff/src/include", "Projects/bsdiff/src/3rdparty/libdivsufsort/include" },
	files = {
		"Projects/bsdiff/src/source/misc.c",
		"Projects/bsdiff/src/source/stream_file.c",
		"Projects/bsdiff/src/source/stream_memory.c",
		"Projects/bsdiff/src/source/stream_sub.c",
		"Projects/bsdiff/src/source/compressor_bz2.c",
		"Projects/bsdiff/src/source/decompressor_bz2.c",
		"Projects/bsdiff/src/source/patch_packer_bz2.c",
		"Projects/bsdiff/src/source/bsdiff.c",
		"Projects/bsdiff/src/source/bspatch.c",
	},
})

-- --------------------------------------------------------------------------------------------
-- bass + fmod are prebuilt (no sources). This placeholder project exists only so common_project
-- gives us the right Lib\<arch>\<toolset>_static\<config> target dir (%{cfg.targetdir}) to copy
-- the per-architecture prebuilt import libs + DLLs into, beside the built static libraries.
dep("prebuilt", {
	systems = WINDOWS,
	files = { "Projects/_prebuilt/prebuilt.c" },
	extra = function()
		filter "platforms:Win32"
		postbuildcommands {
			'{COPYFILE} "%{wks.location}../Projects/bass/src/c/bass.lib" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/bass/src/bass.dll" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/fmod/src/lib/fmod.dll" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/fmod/src/lib/fmod_vc.lib" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/fmod/src/lib/fmodL.dll" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/fmod/src/lib/fmodL_vc.lib" "%{cfg.targetdir}"',
		}
		filter "platforms:x64"
		postbuildcommands {
			'{COPYFILE} "%{wks.location}../Projects/bass/src/c/x64/bass.lib" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/bass/src/x64/bass.dll" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/fmod/src/lib/fmod64.dll" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/fmod/src/lib/fmod64_vc.lib" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/fmod/src/lib/fmodL64.dll" "%{cfg.targetdir}"',
			'{COPYFILE} "%{wks.location}../Projects/fmod/src/lib/fmodL64_vc.lib" "%{cfg.targetdir}"',
		}
		filter {}
	end,
})
