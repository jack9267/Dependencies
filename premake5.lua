-- Dependencies: the vendored third-party libraries, built with premake as an alternative to the
-- CMake build. A single file (no per-project scripts), using the shared jbuild/premake utils.
--
--     premake5 vs2022        (run from the repository root)
--
-- Output mirrors the CMake build so the same consumers link unchanged: each static library lands in
--   Lib\<arch>\<toolset>_static\<Debug|Release>\<name>_static.lib
-- via common_project()'s targetdir - so NO per-library install step is needed, only the headers,
-- which the "headers" project below assembles into include\ the way install_include() did.

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

-- zstd: the library from lib/ (common, compress, decompress, dictBuilder; not legacy or deprecated), as
-- its own CMake builds it, multithreaded compression included - workers start only when a caller sets
-- ZSTD_c_nbWorkers. On Windows that uses Vista's condition variables, which YY-Thunks supplies on XP.
-- The x86_64 assembly decoder is GCC/clang-only, and one Apple compile serves every architecture, so it is
-- off everywhere (ZSTD_DISABLE_ASM; the C decoder is the same one MSVC builds always use). The DLL is
-- zstd.dll with its version .rc.
dep("zstd", {
	includedirs = { "Projects/zstd/src/lib", "Projects/zstd/src/lib/common" },
	defines     = { "ZSTD_MULTITHREAD", "ZSTD_DISABLE_ASM" },
	shared      = { {
		defines  = { "ZSTD_DLL_EXPORT=1" },
		addfiles = { "Projects/zstd/src/build/VS2010/libzstd-dll/libzstd-dll.rc" },
	} },
	files = {
		"Projects/zstd/src/lib/common/*.c",
		"Projects/zstd/src/lib/compress/*.c",
		"Projects/zstd/src/lib/decompress/*.c",
		"Projects/zstd/src/lib/dictBuilder/*.c",
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

-- angelscript: the engine, AS_MAX_PORTABILITY everywhere - native functions are registered through the
-- generic calling convention only, so none of the per-platform assembly (as_callfunc_*.asm/.S) is needed
-- and one build serves every target. A consumer defines it too: registering a native any other way is
-- refused at run time. The DLL is angelscript.dll (ANGELSCRIPT_EXPORT; a consumer of it defines
-- ANGELSCRIPT_DLL_LIBRARY_IMPORT).
dep("angelscript", { lang = "C++",
	includedirs = { "Projects/angelscript/src/angelscript/include" },
	defines     = { "AS_MAX_PORTABILITY" },
	shared      = "ANGELSCRIPT_EXPORT",
	files       = { "Projects/angelscript/src/angelscript/source/*.cpp" } })
-- angelscript_addons: the SDK's add-ons a host registers (string, array, dictionary, any, handle, weakref,
-- math, grid, datetime, serializer, helper, context manager, and the builder for #include and metadata),
-- each with its generic wrappers under AS_MAX_PORTABILITY. Static only: they export nothing, and work
-- with the static library or the DLL alike. Left out: scriptfile (scripts reading and writing files
-- directly), scriptsocket (Windows sockets) and debugger (a console debugger on stdin/stdout).
local ANGELSCRIPT_ADDONS = { "contextmgr", "datetime", "scriptany", "scriptarray", "scriptbuilder",
	"scriptdictionary", "scriptgrid", "scripthandle", "scripthelper", "scriptmath", "scriptstdstring",
	"serializer", "weakref" }
local ANGELSCRIPT_ADDON_FILES = {}
for _, a in ipairs(ANGELSCRIPT_ADDONS) do
	ANGELSCRIPT_ADDON_FILES[#ANGELSCRIPT_ADDON_FILES + 1] = "Projects/angelscript/src/add_on/" .. a .. "/*.cpp"
end
dep("angelscript_addons", { lang = "C++", dir = "Projects/angelscript",
	includedirs = { "Projects/angelscript/src/angelscript/include" },
	defines     = { "AS_MAX_PORTABILITY" },
	files       = ANGELSCRIPT_ADDON_FILES })

-- mongoose6: 64 KB per socket read/write and of a served file kept queued, where mongoose's defaults are
-- 1460 and 1024 - one TCP segment per connection per mg_mgr_poll() held HTTP file serving to about 23 KB/s
-- against a server loop that sleeps between polls. Used only inside mongoose.c, so consumers need not match.
dep("mongoose6", { includedirs = { "Projects/mongoose6/include/mongoose6" },
	defines = { "MG_TCP_IO_SIZE=65536", "MG_MAX_HTTP_SEND_MBUF=65536" } })
-- mongoose7: MG_IO_SIZE (default 512) is the step its buffers grow and round by, and half of how much of a
-- served file static_cb keeps queued - 1 KB per poll otherwise, the same crawl as mongoose6's defaults.
-- 32 KB gives 64 KB of a file at a time. Used only inside mongoose.c.
dep("mongoose7", { includedirs = { "Projects/mongoose7/include/mongoose7" },
	defines = { "MG_IO_SIZE=32768" } })

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
	{ file = "Projects/zstd/src/lib/zstd.h" },
	{ file = "Projects/zstd/src/lib/zdict.h" },
	{ file = "Projects/zstd/src/lib/zstd_errors.h" },
	{ dir = "Projects/png/include" },
	{ dir = "Projects/tinyxml/include" },
	{ dir = "Projects/lua5.3/include" },
	{ dir = "Projects/lua5.4/include" },
	{ dir = "Projects/squirrel/include" },
	{ dir = "Projects/sqstdlib/include" },
	{ file = "Projects/angelscript/src/angelscript/include/angelscript.h" },
	{ file = "Projects/angelscript/src/add_on/autowrapper/aswrappedcall.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/contextmgr/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/datetime/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/scriptany/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/scriptarray/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/scriptbuilder/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/scriptdictionary/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/scriptgrid/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/scripthandle/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/scripthelper/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/scriptmath/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/scriptstdstring/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/serializer/*.h", to = "angelscript" },
	{ files = "Projects/angelscript/src/add_on/weakref/*.h", to = "angelscript" },
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
-- libressl: crypto + ssl (no tls lib), 4.4.0. The source lists are src/crypto/CMakeLists.txt's and
-- src/ssl/CMakeLists.txt's; after an update, take them again from there. OPENSSL_NO_ASM everywhere, so no
-- assembly and no CPU detection: the generic crypto/arch/arm headers serve every architecture, which
-- also lets the Apple build compile all of its architectures in one go. The shared builds export through
-- a generated .def (libressl_def below); static libs need none of that.
--
-- Windows: _WIN32_WINNT is Vista's, as LibreSSL asks. Three things it uses are Vista's
-- (InitOnceExecuteOnce, BCryptGenRandom, inet_pton), and on XP builds YY-Thunks supplies all three: its
-- object defines their __imp_ symbols, so nothing imports them from the system. A target built without
-- YY-Thunks (ARM64) has them natively and links bcrypt.
local libressl_defines = WINDOWS_TARGET and {
	"LIBRESSL_INTERNAL", "OPENSSL_NO_HW_PADLOCK", "__BEGIN_HIDDEN_DECLS=", "__END_HIDDEN_DECLS=",
	"_CRT_SECURE_NO_WARNINGS", "_CRT_DEPRECATED_NO_WARNINGS", "_REENTRANT", "_POSIX_THREAD_SAFE_FUNCTIONS",
	"WIN32_LEAN_AND_MEAN", "_WIN32_WINNT=0x0600", "NO_SYSLOG", "inline=__inline", "HAVE_LITTLE_ENDIAN",
	"HAVE_STRNLEN", "OPENSSL_NO_ASM", "SIZEOF_TIME_T=8",
} or {
	-- The libc of macOS, iOS and Android has these, so the compat headers use the system's.
	"LIBRESSL_INTERNAL", "OPENSSL_NO_HW_PADLOCK", "__BEGIN_HIDDEN_DECLS=", "__END_HIDDEN_DECLS=",
	"OPENSSL_NO_ASM", "SIZEOF_TIME_T=8",
	"HAVE_ASPRINTF", "HAVE_GETDELIM", "HAVE_GETLINE", "HAVE_GETOPT", "HAVE_GETPAGESIZE",
	"HAVE_GETPROGNAME", "HAVE_STRCASECMP", "HAVE_STRLCAT", "HAVE_STRLCPY", "HAVE_STRNDUP", "HAVE_STRNLEN",
	"HAVE_STRSEP", "HAVE_TIMEGM", "HAVE_ARC4RANDOM_BUF", "HAVE_GETENTROPY", "HAVE_TIMINGSAFE_BCMP",
	"HAVE_CLOCK_GETTIME", "HAVE_D_NAMLEN", "HAVE_D_TYPE", "HAVE_ERR_H", "HAVE_MEMMEM", "HAVE_POLL",
	"HAVE_READPASSPHRASE_H", "HAVE_STRTONUM",
}

-- crypto's lock, BIO and UI sources for the platform.
local LIBRESSL_PLATFORM_CRYPTO = srcs("Projects/libressl/src/crypto", WINDOWS_TARGET and
	{ "compat/crypto_lock_win", "bio/b_win", "ui/ui_openssl_win" } or
	{ "crypto_lock", "bio/b_posix", "ui/ui_openssl" })

-- What the C library lacks, from src/crypto (CMake's COMPAT_SRC, as its checks come out for the defines
-- above). Both libraries' DLLs build these in.
local LIBRESSL_PLATFORM = srcs("Projects/libressl/src/crypto", WINDOWS_TARGET and {
	"compat/posix_win", "compat/bsd-asprintf", "compat/getdelim", "compat/getline", "compat/getopt_long",
	"compat/getpagesize", "compat/getprogname_windows", "compat/strcasecmp", "compat/strlcat",
	"compat/strlcpy", "compat/strndup", "compat/strsep", "compat/strtonum", "compat/explicit_bzero_win",
	"compat/arc4random", "compat/arc4random_uniform", "compat/getentropy_win", "compat/timingsafe_bcmp",
} or { "compat/explicit_bzero" })
local LIBRESSL_COMPAT = table.join(LIBRESSL_PLATFORM, srcs("Projects/libressl/src/crypto", {
	"compat/freezero", "compat/reallocarray", "compat/recallocarray", "compat/syslog_r",
	"compat/timingsafe_memcmp",
}))

-- Each library's hidden/ (its own copies of the public headers, marking what is internal) comes before
-- include/, as in the CMake build.
local LIBRESSL_ARCH = { "Projects/libressl/src/crypto/arch/arm", "Projects/libressl/src/crypto/bn/arch/arm" }
local LIBRESSL_CRYPTO_DIRS = {}
for _, d in ipairs({ "aes", "asn1", "bio", "bn", "bytestring", "conf", "dh", "dsa", "curve25519", "ec",
		"ecdh", "ecdsa", "err", "evp", "hidden", "hmac", "lhash", "mlkem", "modes", "ocsp", "pkcs12", "rsa",
		"sha", "stack", "x509" }) do
	LIBRESSL_CRYPTO_DIRS[#LIBRESSL_CRYPTO_DIRS + 1] = "Projects/libressl/src/crypto/" .. d
end
local libressl_crypto_includes = table.join({ "Projects/libressl/src/crypto" }, LIBRESSL_CRYPTO_DIRS,
	{ "Projects/libressl/src/include/compat", "Projects/libressl/src/include" }, LIBRESSL_ARCH)
local libressl_ssl_includes = table.join({
	"Projects/libressl/src/ssl", "Projects/libressl/src/ssl/hidden", "Projects/libressl/src/crypto",
	"Projects/libressl/src/crypto/bio", "Projects/libressl/src/include/compat",
	"Projects/libressl/src/include" }, LIBRESSL_ARCH)

-- Mirrors the CMake export_symbol macro on Windows: build a module-definition (.def) from a libressl
-- .sym (newline-separated symbol names) as "EXPORTS\n" + the names, and feed it to /DEF. removeSyms
-- drops entries (crypto's CRYPTO_UNEXPORT).
-- The .def is written under .jbuild/gen (gitignored) each generate; returns an absolute path for /DEF.
local function libressl_def(name, symRelPath, removeSyms)
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
	os.mkdir(path.getabsolute(".jbuild/gen"))
	local defPath = path.getabsolute(".jbuild/gen/" .. name .. ".def")
	local f = io.open(defPath, "w")
	f:write("EXPORTS\n")
	for _, s in ipairs(syms) do f:write(s .. "\n") end
	f:close()
	return defPath
end

-- crypto: src/crypto/CMakeLists.txt's CRYPTO_SRC (408 files).
local LIBRESSL_CRYPTO = srcs("Projects/libressl/src/crypto", {
	"crypto_err", "crypto_ex_data", "crypto_init", "crypto_legacy", "crypto_memory", "aes/aes", "aes/aes_core",
	"asn1/a_bitstr", "asn1/a_enum", "asn1/a_int", "asn1/a_mbstr", "asn1/a_object", "asn1/a_octet",
	"asn1/a_pkey", "asn1/a_print", "asn1/a_pubkey", "asn1/a_strex", "asn1/a_string", "asn1/a_strnid",
	"asn1/a_time", "asn1/a_time_posix", "asn1/a_time_tm", "asn1/a_type", "asn1/a_utf8", "asn1/asn1_err",
	"asn1/asn1_gen", "asn1/asn1_item", "asn1/asn1_lib", "asn1/asn1_old", "asn1/asn1_old_lib", "asn1/asn1_par",
	"asn1/asn1_types", "asn1/asn_mime", "asn1/asn_moid", "asn1/bio_asn1", "asn1/bio_ndef", "asn1/p5_pbe",
	"asn1/p5_pbev2", "asn1/p8_pkey", "asn1/t_crl", "asn1/t_req", "asn1/t_spki", "asn1/t_x509", "asn1/t_x509a",
	"asn1/tasn_dec", "asn1/tasn_enc", "asn1/tasn_fre", "asn1/tasn_new", "asn1/tasn_prn", "asn1/tasn_typ",
	"asn1/tasn_utl", "asn1/x_algor", "asn1/x_attrib", "asn1/x_bignum", "asn1/x_crl", "asn1/x_exten",
	"asn1/x_long", "asn1/x_name", "asn1/x_pubkey", "asn1/x_req", "asn1/x_sig", "asn1/x_spki", "asn1/x_val",
	"asn1/x_x509", "asn1/x_x509a", "bf/blowfish", "bio/b_dump", "bio/b_print", "bio/b_sock", "bio/bf_buff",
	"bio/bf_nbio", "bio/bf_null", "bio/bio_cb", "bio/bio_err", "bio/bio_lib", "bio/bio_meth", "bio/bss_acpt",
	"bio/bss_bio", "bio/bss_conn", "bio/bss_dgram", "bio/bss_fd", "bio/bss_file", "bio/bss_mem", "bio/bss_null",
	"bio/bss_sock", "bn/bn_add", "bn/bn_add_sub", "bn/bn_bpsw", "bn/bn_const", "bn/bn_convert", "bn/bn_ctx",
	"bn/bn_div", "bn/bn_err", "bn/bn_exp", "bn/bn_gcd", "bn/bn_isqrt", "bn/bn_kron", "bn/bn_lib", "bn/bn_mod",
	"bn/bn_mod_sqrt", "bn/bn_mod_words", "bn/bn_mont", "bn/bn_mul", "bn/bn_prime", "bn/bn_primitives",
	"bn/bn_print", "bn/bn_rand", "bn/bn_recp", "bn/bn_shift", "bn/bn_small_primes", "bn/bn_sqr", "bn/bn_word",
	"buffer/buf_err", "buffer/buffer", "bytestring/bs_ber", "bytestring/bs_cbb", "bytestring/bs_cbs",
	"camellia/camellia", "cast/cast", "chacha/chacha", "cmac/cm_ameth", "cmac/cm_pmeth", "cmac/cmac",
	"cms/cms_asn1", "cms/cms_att", "cms/cms_dd", "cms/cms_enc", "cms/cms_env", "cms/cms_err", "cms/cms_ess",
	"cms/cms_io", "cms/cms_kari", "cms/cms_lib", "cms/cms_pwri", "cms/cms_sd", "cms/cms_smime", "conf/conf_api",
	"conf/conf_def", "conf/conf_err", "conf/conf_lib", "conf/conf_mod", "conf/conf_sap", "ct/ct_b64",
	"ct/ct_err", "ct/ct_log", "ct/ct_oct", "ct/ct_policy", "ct/ct_prn", "ct/ct_sct", "ct/ct_sct_ctx",
	"ct/ct_vfy", "ct/ct_x509v3", "curve25519/curve25519-generic", "curve25519/curve25519", "des/des",
	"des/des_cksum", "des/des_enc", "des/des_fcrypt", "des/des_key", "dh/dh_ameth", "dh/dh_asn1", "dh/dh_check",
	"dh/dh_err", "dh/dh_gen", "dh/dh_key", "dh/dh_lib", "dh/dh_pmeth", "dsa/dsa_ameth", "dsa/dsa_asn1",
	"dsa/dsa_err", "dsa/dsa_gen", "dsa/dsa_key", "dsa/dsa_lib", "dsa/dsa_meth", "dsa/dsa_ossl", "dsa/dsa_pmeth",
	"dsa/dsa_prn", "ec/ec_ameth", "ec/ec_asn1", "ec/ec_convert", "ec/ec_curve", "ec/ec_err", "ec/ec_field",
	"ec/ec_key", "ec/ec_lib", "ec/ec_mult", "ec/ec_pmeth", "ec/eck_prn", "ec/ecp_hp_methods", "ec/ecp_methods",
	"ec/ecx_methods", "ecdh/ecdh", "ecdsa/ecdsa", "engine/engine_stubs", "err/err", "err/err_all",
	"err/err_prn", "evp/bio_b64", "evp/bio_enc", "evp/bio_md", "evp/e_aes", "evp/e_bf", "evp/e_camellia",
	"evp/e_cast", "evp/e_chacha", "evp/e_chacha20poly1305", "evp/e_des", "evp/e_des3", "evp/e_idea",
	"evp/e_null", "evp/e_rc2", "evp/e_rc4", "evp/e_sm4", "evp/e_xcbc_d", "evp/evp_aead", "evp/evp_cipher",
	"evp/evp_digest", "evp/evp_encode", "evp/evp_err", "evp/evp_key", "evp/evp_names", "evp/evp_pbe",
	"evp/evp_pkey", "evp/m_md4", "evp/m_md5", "evp/m_md5_sha1", "evp/m_null", "evp/m_ripemd", "evp/m_sha1",
	"evp/m_sha3", "evp/m_sigver", "evp/m_sm3", "evp/p_legacy", "evp/p_lib", "evp/p_sign", "evp/p_verify",
	"evp/pmeth_fn", "evp/pmeth_gn", "evp/pmeth_lib", "hkdf/hkdf", "hmac/hm_ameth", "hmac/hm_pmeth", "hmac/hmac",
	"idea/idea", "kdf/hkdf_evp", "kdf/kdf_err", "kdf/tls1_prf", "lhash/lhash", "md4/md4", "md5/md5",
	"mlkem/mlkem", "mlkem/mlkem_internal", "mlkem/mlkem_key", "modes/cbc128", "modes/ccm128", "modes/cfb128",
	"modes/ctr128", "modes/gcm128", "modes/ofb128", "modes/xts128", "objects/obj_dat", "objects/obj_err",
	"objects/obj_lib", "objects/obj_xref", "ocsp/ocsp_asn", "ocsp/ocsp_cl", "ocsp/ocsp_err", "ocsp/ocsp_ext",
	"ocsp/ocsp_ht", "ocsp/ocsp_lib", "ocsp/ocsp_prn", "ocsp/ocsp_srv", "ocsp/ocsp_vfy", "pem/pem_all",
	"pem/pem_err", "pem/pem_info", "pem/pem_lib", "pem/pem_oth", "pem/pem_pk8", "pem/pem_pkey", "pem/pem_sign",
	"pem/pem_x509", "pem/pem_xaux", "pem/pvkfmt", "pkcs12/p12_add", "pkcs12/p12_asn", "pkcs12/p12_attr",
	"pkcs12/p12_crt", "pkcs12/p12_decr", "pkcs12/p12_init", "pkcs12/p12_key", "pkcs12/p12_kiss",
	"pkcs12/p12_mutl", "pkcs12/p12_npas", "pkcs12/p12_p8d", "pkcs12/p12_p8e", "pkcs12/p12_sbag",
	"pkcs12/p12_utl", "pkcs12/pk12err", "pkcs7/pk7_asn1", "pkcs7/pk7_attr", "pkcs7/pk7_doit", "pkcs7/pk7_lib",
	"pkcs7/pk7_mime", "pkcs7/pk7_smime", "pkcs7/pkcs7err", "poly1305/poly1305", "rand/rand_err",
	"rand/rand_lib", "rand/randfile", "rc2/rc2", "rc4/rc4", "ripemd/ripemd", "rsa/rsa_ameth", "rsa/rsa_asn1",
	"rsa/rsa_blinding", "rsa/rsa_chk", "rsa/rsa_eay", "rsa/rsa_err", "rsa/rsa_gen", "rsa/rsa_lib",
	"rsa/rsa_meth", "rsa/rsa_none", "rsa/rsa_oaep", "rsa/rsa_pk1", "rsa/rsa_pmeth", "rsa/rsa_prn",
	"rsa/rsa_pss", "rsa/rsa_saos", "rsa/rsa_sign", "rsa/rsa_x931", "sha/sha1", "sha/sha256", "sha/sha3",
	"sha/sha512", "sm3/sm3", "sm4/sm4", "stack/stack", "ts/ts_asn1", "ts/ts_conf", "ts/ts_err", "ts/ts_lib",
	"ts/ts_req_print", "ts/ts_req_utils", "ts/ts_rsp_print", "ts/ts_rsp_sign", "ts/ts_rsp_utils",
	"ts/ts_rsp_verify", "ts/ts_verify_ctx", "txt_db/txt_db", "ui/ui_err", "ui/ui_lib", "ui/ui_null",
	"x509/by_dir", "x509/by_file", "x509/by_mem", "x509/x509_addr", "x509/x509_akey", "x509/x509_akeya",
	"x509/x509_alt", "x509/x509_asid", "x509/x509_att", "x509/x509_bcons", "x509/x509_bitst", "x509/x509_cmp",
	"x509/x509_conf", "x509/x509_constraints", "x509/x509_cpols", "x509/x509_crld", "x509/x509_d2",
	"x509/x509_def", "x509/x509_err", "x509/x509_ext", "x509/x509_extku", "x509/x509_genn", "x509/x509_ia5",
	"x509/x509_info", "x509/x509_int", "x509/x509_issuer_cache", "x509/x509_lib", "x509/x509_lu",
	"x509/x509_ncons", "x509/x509_obj", "x509/x509_ocsp", "x509/x509_pcons", "x509/x509_pku", "x509/x509_pmaps",
	"x509/x509_policy", "x509/x509_prn", "x509/x509_purp", "x509/x509_r2x", "x509/x509_req", "x509/x509_set",
	"x509/x509_siginfo", "x509/x509_skey", "x509/x509_trs", "x509/x509_txt", "x509/x509_utl", "x509/x509_v3",
	"x509/x509_verify", "x509/x509_vfy", "x509/x509_vpm", "x509/x509cset", "x509/x509name", "x509/x509rset",
	"x509/x509spki", "x509/x509type", "x509/x_all",
})

-- ssl: src/ssl/CMakeLists.txt's SSL_SRC (53 files), and BS_SRC, the bytestring copies only the DLL
-- builds.
local LIBRESSL_SSL = srcs("Projects/libressl/src/ssl", {
	"bio_ssl", "d1_both", "d1_lib", "d1_pkt", "d1_srtp", "dtls12_handshake_msg", "pqueue", "s3_cbc", "s3_lib",
	"ssl_asn1", "ssl_both", "ssl_cert", "ssl_ciph", "ssl_ciphers", "ssl_clnt", "ssl_err", "ssl_init", "ssl_kex",
	"ssl_lib", "ssl_methods", "ssl_pkt", "ssl_rsa", "ssl_seclevel", "ssl_sess", "ssl_sigalgs", "ssl_srvr",
	"ssl_stat", "ssl_tlsext", "ssl_transcript", "ssl_txt", "ssl_versions", "t1_enc", "t1_lib", "tls_buffer",
	"tls_content", "tls_key_share", "tls_lib", "tls12_key_schedule", "tls12_legacy", "tls12_lib",
	"tls12_record", "tls12_record_layer", "tls13_client", "tls13_error", "tls13_handshake",
	"tls13_handshake_msg", "tls13_key_schedule", "tls13_legacy", "tls13_lib", "tls13_quic", "tls13_record",
	"tls13_record_layer", "tls13_server",
})
local LIBRESSL_SSL_BYTESTRING = srcs("Projects/libressl/src/ssl", {
	"bs_ber", "bs_cbb", "bs_cbs",
})

dep("crypto", {
	systems     = GUI,
	defines     = table.join(libressl_defines, { "LIBRESSL_CRYPTO_INTERNAL" }),
	includedirs = libressl_crypto_includes,
	-- DLL is crypto-57 (major version from src/crypto/VERSION), import library crypto.lib. Exports via
	-- the generated .def; links the Win32 libs the CMake build names (ws2_32 is workspace-scope).
	shared = { { extra = function()
		targetname "crypto-57"
		implibname "crypto"
		links { "bcrypt", "shell32", "comdlg32" }
		linkoptions { '/DEF:"' .. libressl_def("crypto",
			"Projects/libressl/src/crypto/crypto.sym", { "BIO_s_log" }) .. '"' }
	end } },
	files = table.join(LIBRESSL_CRYPTO, LIBRESSL_PLATFORM_CRYPTO, LIBRESSL_COMPAT),
})

dep("ssl", {
	systems     = GUI,
	defines     = libressl_defines,
	includedirs = libressl_ssl_includes,
	-- DLL is ssl-60 (src/ssl/VERSION), import library ssl.lib; exports via the generated .def and links
	-- the crypto DLL (ssl is layered on it) plus the CMake's Win32 libs. The crypto DLL exports neither
	-- the bytestring functions nor the C library stand-ins, so the ssl DLL builds its own, as CMake's does;
	-- the static library leaves them to crypto's (two copies would clash where both are linked).
	shared = { {
		addfiles = table.join(LIBRESSL_SSL_BYTESTRING, LIBRESSL_COMPAT),
		extra    = function()
			targetname "ssl-60"
			implibname "ssl"
			links { "crypto", "bcrypt", "shell32", "comdlg32" }
			linkoptions { '/DEF:"' .. libressl_def("ssl", "Projects/libressl/src/ssl/ssl.sym") .. '"' }
		end,
	} },
	files       = LIBRESSL_SSL,
})

-- --------------------------------------------------------------------------------------------
-- Remaining from-source libraries: graphics / network / UI. Windows needs no generated headers.

-- macOS links the libcurl its SDK has; iOS has none, so there it is built from the vendored source, on
-- LibreSSL as here. curl takes its platform from a configure-made curl_config.h; Projects/curl/apple's
-- is one made by curl's own CMake on macOS (the two share a libc), with nothing in it about TLS or zlib -
-- those are the defines.
--
-- Windows takes one too (curl's config-win32.h is for Visual Studio 2010-2013 only since 8.13):
-- Projects/curl/windows's was made by curl's own CMake against this LibreSSL and zlib, with the features
-- below, and holds every Windows setting; regenerate it after updating curl. It is built for Vista (since
-- 8.19.0 curl refuses anything older); what it calls from Vista on - BCryptGenRandom, if_nametoindex and
-- the rest - YY-Thunks supplies on XP builds, as for LibreSSL.
dep("curl", {
	systems = { "windows", "ios" },
	defines = not WINDOWS_TARGET and {
		"HAVE_CONFIG_H", "BUILDING_LIBCURL", "CURL_STATICLIB", "USE_OPENSSL", "HAVE_LIBZ", "HAVE_ZLIB_H",
		"HAVE_ZSTD", "CURL_DISABLE_OPENSSL_AUTO_LOAD_CONFIG",
	} or {
		"HAVE_CONFIG_H", "BUILDING_LIBCURL", "CURL_STATICLIB", "_WIN32_WINNT=0x0600",
	},
	includedirs = table.join({ WINDOWS_TARGET and "Projects/curl/windows" or "Projects/curl/apple" },
		{ "Projects/curl/src/include", "Projects/curl/src/lib",
		"Projects/libressl/src/include", "Projects/zlib/include", "Projects/zstd/src/lib" }),
	-- The DLL drops CURL_STATICLIB, compiles the version .rc, and links the ssl/crypto/zlib/zstd DLLs and bcrypt
	-- (wldap32/ws2_32/crypt32/iphlpapi are already workspace-scope).
	shared = { {
		dropdefines = { "CURL_STATICLIB" },
		addfiles    = { "Projects/curl/src/lib/**.rc" },
		extra       = function() links { "ssl", "crypto", "zlib", "zstd", "bcrypt" } end,
	} },
	files = WINDOWS_TARGET and { "Projects/curl/src/lib/**.c" } or {
		"Projects/curl/src/lib/*.c", "Projects/curl/src/lib/curlx/*.c", "Projects/curl/src/lib/vauth/*.c",
		"Projects/curl/src/lib/vdns/*.c", "Projects/curl/src/lib/vquic/*.c", "Projects/curl/src/lib/vssh/*.c",
		"Projects/curl/src/lib/vtls/*.c" },
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

-- NASM, for flac's x86 assembly: jbuild's pinned one (jbuild_nasm, Common.lua - fetched once into jbuild\tools),
-- whatever is installed, so every machine assembles with the same NASM.
local function nasm_path()
	return path.translate(jbuild_nasm(), "\\")
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
