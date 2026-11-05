/* jconfig.h for libjpeg-turbo 3.2.1, written by hand from src/src/jconfig.h.in for every target this
 * repo builds (Windows, Linux, macOS, iOS, Android): the libjpeg 6.2 API, arithmetic coding, the
 * in-memory source and destination managers, and no SIMD - plain C only, which is what lets the same
 * library run on Windows XP and build for every architecture in one go. */

#define JPEG_LIB_VERSION  62

#define LIBJPEG_TURBO_VERSION  3.2.1

#define LIBJPEG_TURBO_VERSION_NUMBER  3002001

#define C_ARITH_CODING_SUPPORTED 1

#define D_ARITH_CODING_SUPPORTED 1

#define MEM_SRCDST_SUPPORTED  1

/* WITH_SIMD is deliberately not defined. */

#ifndef BITS_IN_JSAMPLE
#define BITS_IN_JSAMPLE  8
#endif

#ifdef _WIN32

#undef RIGHT_SHIFT_IS_UNSIGNED

/* Define "boolean" as unsigned char, not int, per Windows custom */
#ifndef __RPCNDR_H__            /* don't conflict if rpcndr.h already read */
typedef unsigned char boolean;
#endif
#define HAVE_BOOLEAN            /* prevent jmorecfg.h from redefining it */

/* Define "INT32" as int, not long, per Windows custom */
#if !(defined(_BASETSD_H_) || defined(_BASETSD_H))   /* don't conflict if basetsd.h already read */
typedef short INT16;
typedef signed int INT32;
#endif
#define XMD_H                   /* prevent jmorecfg.h from redefining it */

#endif
