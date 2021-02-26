disable_rtti()

# set definitions and sources for arm
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^arm" OR
  CMAKE_SYSTEM_PROCESSOR MATCHES "^aarch64")
  set(PNG_ARM_NEON_POSSIBLE_VALUES check on off)
  set(PNG_ARM_NEON "check" CACHE STRING "Enable ARM NEON optimizations:
     check: (default) use internal checking code;
     off: disable the optimizations;
     on: turn on unconditionally.")
  set_property(CACHE PNG_ARM_NEON PROPERTY STRINGS
     ${PNG_ARM_NEON_POSSIBLE_VALUES})
  list(FIND PNG_ARM_NEON_POSSIBLE_VALUES ${PNG_ARM_NEON} index)
  if(index EQUAL -1)
    message(FATAL_ERROR
            "PNG_ARM_NEON must be one of [${PNG_ARM_NEON_POSSIBLE_VALUES}]")
  elseif(NOT ${PNG_ARM_NEON} STREQUAL "off")
    set(libpng_arm_sources
      src/arm/arm_init.c
      src/arm/filter_neon.S
      src/arm/filter_neon_intrinsics.c
      src/arm/palette_neon_intrinsics.c)

    if(${PNG_ARM_NEON} STREQUAL "on")
      add_definitions(-DPNG_ARM_NEON_OPT=2)
    elseif(${PNG_ARM_NEON} STREQUAL "check")
      add_definitions(-DPNG_ARM_NEON_CHECK_SUPPORTED)
    endif()
  else()
    add_definitions(-DPNG_ARM_NEON_OPT=0)
  endif()
endif()

# set definitions and sources for powerpc
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^powerpc*" OR
   CMAKE_SYSTEM_PROCESSOR MATCHES "^ppc64*")
  set(PNG_POWERPC_VSX_POSSIBLE_VALUES on off)
  set(PNG_POWERPC_VSX "on" CACHE STRING "Enable POWERPC VSX optimizations:
     off: disable the optimizations.")
  set_property(CACHE PNG_POWERPC_VSX PROPERTY STRINGS
     ${PNG_POWERPC_VSX_POSSIBLE_VALUES})
  list(FIND PNG_POWERPC_VSX_POSSIBLE_VALUES ${PNG_POWERPC_VSX} index)
  if(index EQUAL -1)
    message(FATAL_ERROR
            "PNG_POWERPC_VSX must be one of [${PNG_POWERPC_VSX_POSSIBLE_VALUES}]")
  elseif(NOT ${PNG_POWERPC_VSX} STREQUAL "off")
    set(libpng_powerpc_sources
      src/powerpc/powerpc_init.c
      src/powerpc/filter_vsx_intrinsics.c)
    if(${PNG_POWERPC_VSX} STREQUAL "on")
      add_definitions(-DPNG_POWERPC_VSX_OPT=2)
    endif()
  else()
    add_definitions(-DPNG_POWERPC_VSX_OPT=0)
  endif()
endif()

# set definitions and sources for intel
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^i?86" OR
   CMAKE_SYSTEM_PROCESSOR MATCHES "^x86_64*")
  set(PNG_INTEL_SSE_POSSIBLE_VALUES on off)
  set(PNG_INTEL_SSE "on" CACHE STRING "Enable INTEL_SSE optimizations:
     off: disable the optimizations")
  set_property(CACHE PNG_INTEL_SSE PROPERTY STRINGS
     ${PNG_INTEL_SSE_POSSIBLE_VALUES})
  list(FIND PNG_INTEL_SSE_POSSIBLE_VALUES ${PNG_INTEL_SSE} index)
  if(index EQUAL -1)
    message(FATAL_ERROR
            "PNG_INTEL_SSE must be one of [${PNG_INTEL_SSE_POSSIBLE_VALUES}]")
  elseif(NOT ${PNG_INTEL_SSE} STREQUAL "off")
    set(libpng_intel_sources
      src/intel/intel_init.c
      src/intel/filter_sse2_intrinsics.c)
    if(${PNG_INTEL_SSE} STREQUAL "on")
      add_definitions(-DPNG_INTEL_SSE_OPT=1)
    endif()
  else()
    add_definitions(-DPNG_INTEL_SSE_OPT=0)
  endif()
endif()

# set definitions and sources for MIPS
if(CMAKE_SYSTEM_PROCESSOR MATCHES "mipsel*" OR
   CMAKE_SYSTEM_PROCESSOR MATCHES "mips64el*")
  set(PNG_MIPS_MSA_POSSIBLE_VALUES on off)
  set(PNG_MIPS_MSA "on" CACHE STRING "Enable MIPS_MSA optimizations:
     off: disable the optimizations")
  set_property(CACHE PNG_MIPS_MSA PROPERTY STRINGS
     ${PNG_MIPS_MSA_POSSIBLE_VALUES})
  list(FIND PNG_MIPS_MSA_POSSIBLE_VALUES ${PNG_MIPS_MSA} index)
  if(index EQUAL -1)
    message(FATAL_ERROR
            "PNG_MIPS_MSA must be one of [${PNG_MIPS_MSA_POSSIBLE_VALUES}]")
  elseif(NOT ${PNG_MIPS_MSA} STREQUAL "off")
    set(libpng_mips_sources
      src/mips/mips_init.c
      src/mips/filter_msa_intrinsics.c)
    if(${PNG_MIPS_MSA} STREQUAL "on")
      add_definitions(-DPNG_MIPS_MSA_OPT=2)
    endif()
  else()
    add_definitions(-DPNG_MIPS_MSA_OPT=0)
  endif()
endif()

# OUR SOURCES
set(libpng_public_hdrs
  src/png.h
  src/pngconf.h
)
set(libpng_private_hdrs
  src/pngpriv.h
  src/pngdebug.h
  src/pnginfo.h
  src/pngstruct.h
)
set(libpng_sources
  ${libpng_public_hdrs}
  ${libpng_private_hdrs}
  src/png.c
  src/pngerror.c
  src/pngget.c
  src/pngmem.c
  src/pngpread.c
  src/pngread.c
  src/pngrio.c
  src/pngrtran.c
  src/pngrutil.c
  src/pngset.c
  src/pngtrans.c
  src/pngwio.c
  src/pngwrite.c
  src/pngwtran.c
  src/pngwutil.c
  ${libpng_arm_sources}
  ${libpng_intel_sources}
  ${libpng_mips_sources}
  ${libpng_powerpc_sources}
)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

install_include("${CMAKE_CURRENT_SOURCE_DIR}/include")

new_library_static(png "${libpng_sources}" "")

if(WIN32)
	set(DEFINES "PNG_BUILD_DLL;PNG_DLL")
	set(libpng_version_sources src/scripts/pngwin.rc)
else()
	set(DEFINES "")
endif()
new_library_shared(png "${libpng_sources};${libpng_version_sources}" "${DEFINES}")
prefix_lib(png)

target_link_libraries(png zlib)
