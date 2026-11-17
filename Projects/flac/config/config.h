/* Ours, in place of the config.h FLAC's CMake writes from config.cmake.h.in (premake5.lua defines HAVE_CONFIG_H).
   What that would find is worked out here from the compiler's own macros, so one compile serves every target - an
   Apple build compiles all its architectures at once. PACKAGE_VERSION comes from premake5.lua, read from the
   release's CMakeLists.txt. Keep it in step with config.cmake.h.in on an update. */
#ifndef DEPENDENCIES_FLAC_CONFIG_H
#define DEPENDENCIES_FLAC_CONFIG_H

/* Every target is little-endian. */
#define CPU_IS_BIG_ENDIAN 0
#define WORDS_BIGENDIAN CPU_IS_BIG_ENDIAN

/* 64-bit words where pointers are 64-bit (FLAC's CMake leaves it 0; the Windows build has always had it on x64). */
#if defined(_WIN64) || defined(__LP64__) || defined(_LP64)
#define ENABLE_64_BIT_WORDS 1
#else
#define ENABLE_64_BIT_WORDS 0
#endif

#define FLAC__ALIGN_MALLOC_DATA
#define FLAC__HAS_OGG 1

/* x86 and x64: SSE intrinsics, and AVX2/FMA chosen at run time (cpu.c). */
#if defined(__i386__) || defined(__x86_64__) || defined(_M_IX86) || defined(_M_X64)
#define FLAC__HAS_X86INTRIN 1
#define FLAC__USE_AVX
#if !defined(_MSC_VER)
#define HAVE_CPUID_H 1
#endif
#else
#define FLAC__HAS_X86INTRIN 0
#endif

/* arm64: NEON intrinsics (the encoder's LPC). */
#if defined(__aarch64__) || defined(_M_ARM64)
#define FLAC__CPU_ARM64
#define FLAC__HAS_NEONINTRIN 1
#define FLAC__HAS_A64NEONINTRIN 1
#else
#define FLAC__HAS_NEONINTRIN 0
#define FLAC__HAS_A64NEONINTRIN 0
#endif

#define HAVE_LROUND 1
#define HAVE_STDINT_H 1
#define HAVE_INTTYPES_H 1

#if !defined(_WIN32)
#define HAVE_FSEEKO 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_BSWAP16 1
#define HAVE_BSWAP32 1
/* As config.cmake.h.in: GNU extensions where there are any. */
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#endif

#endif
