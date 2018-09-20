
# We only want Debug and Release
#set(CMAKE_CONFIGURATION_TYPES "Debug;Release;RelWithDebInfo" CACHE STRING "Configuration types" FORCE)

if(WIN32)
	# Find NASM
	enable_language(ASM_NASM)
endif()

if(NOT MSVC)
	# Use pthreads on other systems
	set(CMAKE_THREAD_PREFER_PTHREAD true)
endif()

if(MSVC)
	# Ensure Release has debug info
	#set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
	#set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")

	# Enable PDB on all configurations
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /Zi")
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Zi")

	set(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} /Zi")
	set(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} /Zi")

	set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /debug")
	set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /debug")

	set(CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL "${CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL} /debug")
	set(CMAKE_EXE_LINKER_FLAGS_MINSIZEREL "${CMAKE_EXE_LINKER_FLAGS_MINSIZEREL} /debug")
endif()

#set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO}")
#set(CMAKE_STATIC_LINKER_FLAGS_RELEASE "${CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO}")
#set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO}")

# C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED OFF)
set(CMAKE_CXX_EXTENSIONS OFF)

include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
if(COMPILER_SUPPORTS_CXX11)
	message("C++11 is supported by the compiler")
else()
	message(WARNING "C++11 is NOT supported by the compiler")
endif()
CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
if(COMPILER_SUPPORTS_CXX14)
	message("C++14 is supported by the compiler")
else()
	message(WARNING "C++14 is NOT supported by the compiler")
endif()

# determine bits
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(ENGINE_PLATFORM "x64")

	set(RUNTIME_DEBUG_POSTFIX "_d_${ENGINE_PLATFORM}")
	set(RUNTIME_RELEASE_POSTFIX "_${ENGINE_PLATFORM}")
else()
	set(ENGINE_PLATFORM "x86")

	set(RUNTIME_DEBUG_POSTFIX "_d")
	set(RUNTIME_RELEASE_POSTFIX "")
endif()

# lib directory
if(MSVC)
	set(LIB_DIRECTORY "Lib/${ENGINE_PLATFORM}/${CMAKE_VS_PLATFORM_TOOLSET}")
else()
	set(LIB_DIRECTORY "Lib")
endif()

# hide symbols
set(CMAKE_CXX_VISIBILITY_PRESET hidden)

# hide symbols on unix
if(UNIX AND CMAKE_COMPILER_IS_GNUCC)
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -fvisibility=hidden")
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -fvisibility=hidden")
endif()

# Add directx sdk to include/linker path
if(WIN32)
	if(DEFINED ENV{DXSDK_DIR})
		include_directories($ENV{DXSDK_DIR}/Include)
		link_directories("$ENV{DXSDK_DIR}/Lib/${ENGINE_PLATFORM}")
	else()
		message(FATAL_ERROR "The DirectX SDK needs to be installed.\n\nhttps://www.microsoft.com/en-gb/download/details.aspx?id=6812")
	endif()
endif()

macro(add_compiler_flags FLAGS)
	foreach(FLAG ${FLAGS})
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${FLAG}")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${FLAG}")
	endforeach()
endmacro()

macro(compiler_flags CONFIGURATIONS FLAGS)
	foreach(CONFIGURATION ${CONFIGURATIONS})
		foreach(FLAG ${FLAGS})
			set(CMAKE_C_FLAGS_${CONFIGURATION} "${CMAKE_C_FLAGS_${CONFIGURATION}} ${FLAG}")
			set(CMAKE_CXX_FLAGS_${CONFIGURATION} "${CMAKE_CXX_FLAGS_${CONFIGURATION}} ${FLAG}")
		endforeach()
	endforeach()
endmacro()

macro(linker_flags TYPES CONFIGURATIONS FLAGS)
	foreach(CONFIGURATION ${CONFIGURATIONS})
		foreach(TYPE ${TYPES})
			set(CMAKE_${TYPE}_LINKER_FLAGS_${CONFIGURATION} "${CMAKE_${TYPE}_LINKER_FLAGS_${CONFIGURATION}} ${FLAGS}")
		endforeach()
	endforeach()
endmacro()

macro(define CONFIGURATION DEFINES)
	foreach(DEFINE ${DEFINES})
		set(CMAKE_C_FLAGS_${CONFIGURATION} "${CMAKE_C_FLAGS_${CONFIGURATION}} -D${DEFINE}")
		set(CMAKE_CXX_FLAGS_${CONFIGURATION} "${CMAKE_CXX_FLAGS_${CONFIGURATION}} -D${DEFINE}")
	endforeach()
endmacro()

macro(define_debug DEFINES)
	define(DEBUG ${DEFINES})
endmacro()

# Enable DEBUG=1 for debug builds as some projects check that
define_debug(DEBUG=1)

# Visual Studio specifics
if(MSVC)
	# Force /MT for static VC runtimes if Release...
	option(FORCE_STATIC_VCRT "Force /MT for static VC runtimes" OFF)
	if(FORCE_STATIC_VCRT)
		foreach(flag_var
			CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
			CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
			CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
			CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
			if(${flag_var} MATCHES "/MD")
				string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
			endif()
		endforeach()

		set(LIB_DIRECTORY "${LIB_DIRECTORY}_static")
	endif()

	# common defines
	add_definitions(-DWIN32 -D_WINDOWS -D_CRT_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_WARNINGS -D_USE_MATH_DEFINES=1 -DNOMINMAX)

	if(MSVC_VERSION GREATER_EQUAL 1900)
		# Prevent static variables from being thread local storage
		add_compiler_flags("/Zc:threadSafeInit-")
	endif()

	# multi-processor core
	add_compiler_flags("/MP")

	# whole program optimisation
	compiler_flags("RELEASE;RELWITHDEBINFO;MINSIZEREL" "/GL")

	foreach(flag_var
		CMAKE_SHARED_LINKER_FLAGS_RELEASE
		CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO
		CMAKE_EXE_LINKER_FLAGS_RELEASE
		CMAKE_EXE_LINKER_FLAGS_MINSIZEREL CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO)
		if(${flag_var} MATCHES "/INCREMENTAL" AND NOT ${flag_var} MATCHES "/INCREMENTAL:NO")
			string(REGEX REPLACE "/INCREMENTAL" "/INCREMENTAL:NO" ${flag_var} "${${flag_var}}")
		endif()
	endforeach()

	linker_flags("SHARED;STATIC;EXE" "RELEASE;RELWITHDEBINFO;MINSIZEREL" "/LTCG")
	linker_flags("SHARED;EXE" "RELEASE;RELWITHDEBINFO;MINSIZEREL" "/OPT:REF")

	# disable manifest on dlls
	set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /MANIFEST:NO")

	# macro to disable VS warning
	macro(disable_warning ID)
		add_compiler_flags(/wd${ID})
	endmacro()

	# macro to disable VS linker warnings
	macro(disable_linker_warning ID)
		set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /ignore:${ID}")
		set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} /ignore:${ID}")
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /ignore:${ID}")
	endmacro()

	# precompiled header macro
	macro(precompiled_header HEADER)
		add_compiler_flags(/Yu${HEADER}.h)
		set_source_files_properties(${HEADER}.cpp PROPERTIES COMPILE_FLAGS "/Yc${HEADER}.h")
	endmacro()

	# This object file does not define any previously undefined public symbols, so it will not be used by any link operation that consumes this library
	disable_linker_warning(4221)

	# Warnings should be errors
	#add_compiler_flags("/WX")
endif()

# to avoid repeating stuff
function(install_include INCLUDE)
	install(DIRECTORY "${INCLUDE}/" DESTINATION include FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp")
endfunction()
