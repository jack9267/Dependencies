disable_rtti()

if(WIN32)
	add_definitions(-DUNICODE)
	add_definitions(-D_UNICODE)

	add_definitions(-D_WIN32_WINNT=_WIN32_WINNT_WINXP)
	add_definitions(-DHAVE_LIBC)
endif()

set(SDL2_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
set(EXTRA_LIBS "")
set(HIDAPI ON)
set(HIDAPI_SKIP_LIBUSB TRUE)

include(CheckFunctionExists)
include(CheckLibraryExists)
include(CheckIncludeFiles)
include(CheckIncludeFile)
include(CheckSymbolExists)
include(CheckCSourceCompiles)
include(CheckCSourceRuns)
include(CheckCCompilerFlag)
include(CheckTypeSize)
include(CheckStructHasMember)
include(CMakeDependentOption)
include(FindPkgConfig)
include(GNUInstallDirs)
set(CMAKE_MODULE_PATH "${SDL2_SOURCE_DIR}/cmake")
include(${SDL2_SOURCE_DIR}/cmake/macros.cmake)
include(${SDL2_SOURCE_DIR}/cmake/sdlchecks.cmake)

# Check for 64 or 32 bit
set(SIZEOF_VOIDP ${CMAKE_SIZEOF_VOID_P})
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  set(ARCH_64 TRUE)
  set(PROCESSOR_ARCH "x64")
else()
  set(ARCH_64 FALSE)
  set(PROCESSOR_ARCH "x86")
endif()

# General source files
file(GLOB SOURCE_FILES
  ${SDL2_SOURCE_DIR}/src/*.c
  ${SDL2_SOURCE_DIR}/src/atomic/*.c
  ${SDL2_SOURCE_DIR}/src/audio/*.c
  ${SDL2_SOURCE_DIR}/src/cpuinfo/*.c
  ${SDL2_SOURCE_DIR}/src/dynapi/*.c
  ${SDL2_SOURCE_DIR}/src/events/*.c
  ${SDL2_SOURCE_DIR}/src/file/*.c
  ${SDL2_SOURCE_DIR}/src/haptic/*.c
  ${SDL2_SOURCE_DIR}/src/libm/*.c
  ${SDL2_SOURCE_DIR}/src/locale/*.c
  ${SDL2_SOURCE_DIR}/src/misc/*.c
  ${SDL2_SOURCE_DIR}/src/power/*.c
  ${SDL2_SOURCE_DIR}/src/render/*.c
  ${SDL2_SOURCE_DIR}/src/render/*/*.c
  ${SDL2_SOURCE_DIR}/src/sensor/*.c
  ${SDL2_SOURCE_DIR}/src/stdlib/*.c
  ${SDL2_SOURCE_DIR}/src/thread/*.c
  ${SDL2_SOURCE_DIR}/src/timer/*.c
  ${SDL2_SOURCE_DIR}/src/video/*.c
  ${SDL2_SOURCE_DIR}/src/video/yuv2rgb/*.c)

file(GLOB JOYSTICK_SOURCES ${SDL2_SOURCE_DIR}/src/joystick/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${JOYSTICK_SOURCES})

file(GLOB DUMMYAUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/dummy/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${DUMMYAUDIO_SOURCES})

file(GLOB DISKAUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/disk/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${DISKAUDIO_SOURCES})

file(GLOB JOYSTICK_VIRTUAL_SOURCES ${SDL2_SOURCE_DIR}/src/joystick/virtual/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${JOYSTICK_VIRTUAL_SOURCES})

file(GLOB VIDEO_DUMMY_SOURCES ${SDL2_SOURCE_DIR}/src/video/dummy/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${VIDEO_DUMMY_SOURCES})

file(GLOB VIDEO_OFFSCREEN_SOURCES ${SDL2_SOURCE_DIR}/src/video/offscreen/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${VIDEO_OFFSCREEN_SOURCES})

if(WIN32)
	if(MSVC)
		# Windows SDK ksmedia.h
		# warning C4091: 'typedef ': ignored on left of '' when no variable is declared
		disable_warning(4091)
	endif()

	file(GLOB CORE_SOURCES ${SDL2_SOURCE_DIR}/src/core/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${CORE_SOURCES})

	if(MSVC)
		# Prevent codegen that would use the VC runtime libraries.
		set_property(DIRECTORY . APPEND PROPERTY COMPILE_OPTIONS "/GS-")
		if(NOT ARCH_64 AND NOT NO_ENHANCED_INSTRUCTIONS)
			set_property(DIRECTORY . APPEND PROPERTY COMPILE_OPTIONS "/arch:SSE")
		endif()
	endif()

	file(GLOB MISC_SOURCES ${SDL2_SOURCE_DIR}/src/misc/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${MISC_SOURCES})

	file(GLOB WINMM_AUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/winmm/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${WINMM_AUDIO_SOURCES})

	file(GLOB DSOUND_AUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/directsound/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${DSOUND_AUDIO_SOURCES})

	file(GLOB WASAPI_AUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/wasapi/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${WASAPI_AUDIO_SOURCES})

	file(GLOB WIN_VIDEO_SOURCES ${SDL2_SOURCE_DIR}/src/video/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${WIN_VIDEO_SOURCES})

	set(SOURCE_FILES ${SOURCE_FILES}
		${SDL2_SOURCE_DIR}/src/thread/generic/SDL_syscond.c
		${SDL2_SOURCE_DIR}/src/thread/windows/SDL_syscond_srw.c
		${SDL2_SOURCE_DIR}/src/thread/windows/SDL_sysmutex.c
		${SDL2_SOURCE_DIR}/src/thread/windows/SDL_syssem.c
		${SDL2_SOURCE_DIR}/src/thread/windows/SDL_systhread.c
		${SDL2_SOURCE_DIR}/src/thread/windows/SDL_systls.c)

	file(GLOB WINDOWS_SENSOR_SOURCES ${SDL2_SOURCE_DIR}/src/sensor/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${WINDOWS_SENSOR_SOURCES})

	set(SOURCE_FILES ${SOURCE_FILES} ${SDL2_SOURCE_DIR}/src/power/windows/SDL_syspower.c)

	file(GLOB LOCALE_SOURCES ${SDL2_SOURCE_DIR}/src/locale/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${LOCALE_SOURCES})

	file(GLOB FILESYSTEM_SOURCES ${SDL2_SOURCE_DIR}/src/filesystem/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${FILESYSTEM_SOURCES})

	file(GLOB TIMER_SOURCES ${SDL2_SOURCE_DIR}/src/timer/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${TIMER_SOURCES})

	file(GLOB LOADSO_SOURCES ${SDL2_SOURCE_DIR}/src/loadso/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${LOADSO_SOURCES})

	file(GLOB CORE_SOURCES ${SDL2_SOURCE_DIR}/src/core/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${CORE_SOURCES})

	CheckHIDAPI()
	if(HAVE_HIDAPI)
		set(SOURCE_FILES ${SOURCE_FILES} ${SDL2_SOURCE_DIR}/src/hidapi/windows/hid.c)
	endif()
	file(GLOB JOYSTICK_SOURCES ${SDL2_SOURCE_DIR}/src/joystick/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${JOYSTICK_SOURCES})
	list(APPEND EXTRA_LIBS dinput8)

	file(GLOB HAPTIC_SOURCES ${SDL2_SOURCE_DIR}/src/haptic/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${HAPTIC_SOURCES})

	file(GLOB VERSION_SOURCES ${SDL2_SOURCE_DIR}/src/main/windows/*.rc)
	file(GLOB SDLMAIN_SOURCES ${SDL2_SOURCE_DIR}/src/main/windows/*.c)

	list(APPEND EXTRA_LIBS user32 gdi32 winmm imm32 ole32 oleaut32 version uuid advapi32 setupapi shell32)
	list(APPEND EXTRA_LIBS dinput8)
	#list(APPEND EXTRA_LIBS dxerr)
endif()

install_include("${SDL2_SOURCE_DIR}/include")

add_definitions(-DHAVE_LIBC)

new_library_static(SDL2 "${SOURCE_FILES}" "SDL2_BUILDING;SDL2_STATIC")
new_library_shared(SDL2 "${SOURCE_FILES};${VERSION_SOURCES}" "SDL2_BUILDING;DLL_EXPORT")

target_link_libraries(SDL2 ${EXTRA_LIBS})
