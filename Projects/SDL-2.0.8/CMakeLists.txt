set(SDL2_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
set(EXTRA_LIBS "")

include_directories("${SDL2_SOURCE_DIR}/include")

file(GLOB SOURCE_FILES
  ${SDL2_SOURCE_DIR}/src/*.c
  ${SDL2_SOURCE_DIR}/src/atomic/*.c
  ${SDL2_SOURCE_DIR}/src/audio/*.c
  ${SDL2_SOURCE_DIR}/src/cpuinfo/*.c
  ${SDL2_SOURCE_DIR}/src/dynapi/*.c
  ${SDL2_SOURCE_DIR}/src/events/*.c
  ${SDL2_SOURCE_DIR}/src/file/*.c
  ${SDL2_SOURCE_DIR}/src/libm/*.c
  ${SDL2_SOURCE_DIR}/src/render/*.c
  ${SDL2_SOURCE_DIR}/src/render/*/*.c
  ${SDL2_SOURCE_DIR}/src/stdlib/*.c
  ${SDL2_SOURCE_DIR}/src/thread/*.c
  ${SDL2_SOURCE_DIR}/src/timer/*.c
  ${SDL2_SOURCE_DIR}/src/video/*.c
  ${SDL2_SOURCE_DIR}/src/video/yuv2rgb/*.c)

file(GLOB JOYSTICK_SOURCES ${SDL2_SOURCE_DIR}/src/joystick/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${JOYSTICK_SOURCES})

file(GLOB HAPTIC_SOURCES ${SDL2_SOURCE_DIR}/src/haptic/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${HAPTIC_SOURCES})

file(GLOB POWER_SOURCES ${SDL2_SOURCE_DIR}/src/power/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${POWER_SOURCES})

file(GLOB DUMMYAUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/dummy/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${DUMMYAUDIO_SOURCES})

file(GLOB DISKAUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/disk/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${DISKAUDIO_SOURCES})

file(GLOB VIDEO_DUMMY_SOURCES ${SDL2_SOURCE_DIR}/src/video/dummy/*.c)
set(SOURCE_FILES ${SOURCE_FILES} ${VIDEO_DUMMY_SOURCES})

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
		if(NOT ARCH_64)
			set_property(DIRECTORY . APPEND PROPERTY COMPILE_OPTIONS "/arch:SSE")
		endif()
	endif()

	file(GLOB WINMM_AUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/winmm/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${WINMM_AUDIO_SOURCES})

	file(GLOB DSOUND_AUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/directsound/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${DSOUND_AUDIO_SOURCES})

	file(GLOB WASAPI_AUDIO_SOURCES ${SDL2_SOURCE_DIR}/src/audio/wasapi/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${WASAPI_AUDIO_SOURCES})

	file(GLOB WIN_VIDEO_SOURCES ${SDL2_SOURCE_DIR}/src/video/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${WIN_VIDEO_SOURCES})

	set(SOURCE_FILES ${SOURCE_FILES}
		${SDL2_SOURCE_DIR}/src/thread/windows/SDL_sysmutex.c
		${SDL2_SOURCE_DIR}/src/thread/windows/SDL_syssem.c
		${SDL2_SOURCE_DIR}/src/thread/windows/SDL_systhread.c
		${SDL2_SOURCE_DIR}/src/thread/windows/SDL_systls.c
		${SDL2_SOURCE_DIR}/src/thread/generic/SDL_syscond.c)

	set(SOURCE_FILES ${SOURCE_FILES} ${SDL2_SOURCE_DIR}/src/power/windows/SDL_syspower.c)

	file(GLOB FILESYSTEM_SOURCES ${SDL2_SOURCE_DIR}/src/filesystem/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${FILESYSTEM_SOURCES})

	file(GLOB TIMER_SOURCES ${SDL2_SOURCE_DIR}/src/timer/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${TIMER_SOURCES})

	file(GLOB LOADSO_SOURCES ${SDL2_SOURCE_DIR}/src/loadso/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${LOADSO_SOURCES})

	file(GLOB CORE_SOURCES ${SDL2_SOURCE_DIR}/src/core/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${CORE_SOURCES})

	file(GLOB JOYSTICK_SOURCES ${SDL2_SOURCE_DIR}/src/joystick/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${JOYSTICK_SOURCES})

	file(GLOB HAPTIC_SOURCES ${SDL2_SOURCE_DIR}/src/haptic/windows/*.c)
	set(SOURCE_FILES ${SOURCE_FILES} ${HAPTIC_SOURCES})

	file(GLOB VERSION_SOURCES ${SDL2_SOURCE_DIR}/src/main/windows/*.rc)
	file(GLOB SDLMAIN_SOURCES ${SDL2_SOURCE_DIR}/src/main/windows/*.c)

	list(APPEND EXTRA_LIBS user32 gdi32 winmm imm32 ole32 oleaut32 version uuid)
	list(APPEND EXTRA_LIBS dinput8)
	list(APPEND EXTRA_LIBS dxerr)
endif()

install_include("${SDL2_SOURCE_DIR}/include")

new_library_static(SDL2 "${SOURCE_FILES}" "SDL2_BUILDING;HAVE_LIBC")
new_library_shared(SDL2 "${SOURCE_FILES};${VERSION_SOURCES}" "SDL2_BUILDING;HAVE_LIBC;SDL2_STATIC")

target_link_libraries(SDL2 ${EXTRA_LIBS})
