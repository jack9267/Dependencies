# CLAUDE.md

Rules and findings for the Dependencies repo (the vendored third-party libraries). Follow these exactly.

## Building and what consumers see

- **The Windows build is JBuild (premake)**: `premake5.lua` is the build, generated with `pwsh -NoProfile
  -ExecutionPolicy Bypass -File jbuild\JBuild.ps1 -BuildSystem premake -VisualStudio 2022 -TargetOs winxp` into
  `.jbuild\Dependencies.sln`. Libraries land in `Lib\<arch>\v143_static\<Config>`; the `headers` project copies
  each library's headers into `include\` (generated, gitignored). `xcopy /D` only adds and overwrites, so when a
  library drops headers, delete its folder under `include\` before building `headers` again.
- **Consumers do not link this repo.** Galactic, ModLauncher, GTAC and the rest take `$(jdependencies_home)`,
  which is the INSTALLED copy, `C:\Program Files (x86)\Jack's Mini Network\Dependencies` (`Archive.bat` packs
  `include` and `Lib` into `Dependencies.7z`; `Installer\Installer.nsi` unpacks it there and sets the variable).
  Building here changes nothing for them until that is reinstalled. To try a change in a consumer first, set
  `$env:jdependencies_home` to this repo for that one MSBuild process (MSBuild reads it as a property), and
  build the consumer the normal way afterwards so its objects match the installed copy again.
- **MSBuild does not recompile a consumer's source when a header under `$(jdependencies_home)\include`
  changes** - it does not track them. After changing a library's headers, touch the consumer files that
  include them (`(Get-Item <file>).LastWriteTime = Get-Date`) and confirm their names appear in the build
  output.

## FreeBSD (`make TARGET=freebsd`)

- **Built like Linux** (2026-11-05): the core set with no `systems` list, from premake's `bsd` fragment
  (`.jbuild/make/bsd.mk`), into `Lib/freebsd/<Config>`. No GUI libraries, and no SDL, LibreSSL or curl: OpenSSL
  is FreeBSD's base system's, curl and SDL2 its packages (`pkg install curl sdl2`), which jbuild's
  `dependencies.mk` finds under `/usr/local`. On FreeBSD run `gmake` (FreeBSD's make is not GNU make); from Linux,
  `make TARGET=freebsd FREEBSD_SYSROOT=<FreeBSD 14 base.txz unpacked> -j2 release debug` (jbuild's CLAUDE.md).
- **One source fix, since dropped**: mongoose 7.1's `mongoose.h` was made to include `<netinet/in.h>` itself.
  glibc's `<arpa/inet.h>` brings it in; FreeBSD's does not (POSIX doesn't require it), so `sockaddr_in` and
  `IPPROTO_TCP` were unknown. 7.23 (2026-11-10) includes it the same way, so it is stock now. Everything else
  compiled as it is.
- **Built against a real FreeBSD 14.5 sysroot and used** (2026-11-05): every library cross-compiled from Linux,
  Release and Debug, then linked into Galactic's UnitTests and tools and a server program, which ran on FreeBSD
  14.5 in QEMU with every test passing (the sysroot and the VM: jbuild's and Galactic's CLAUDE.md). Not tried: a
  build on FreeBSD itself (`gmake -j4 release debug`).

## mongoose 7 (`Projects/mongoose7`)

- **7.23** (2026-11-10, from 7.1): `mongoose.c`/`mongoose.h` from the `7.23` tag, unchanged but for CRLF and one
  line (below). Nothing links it yet - Galactic is on `mongoose6` - it is here for a port of Galactic's web servers. Its
  `mg_http_serve_file` reads through `struct mg_fs` (stat, open, read, seek, close), answers `If-None-Match` with
  304 and one `Range` with 206/416, and keeps the connection open; it sends no `Last-Modified`. Built Win32/x64,
  Debug/Release, with no warnings; the Debug library imports only what XP has (sockets with `select`,
  `GetTickCount`, `FindFirstFileW`...). Not built off Windows yet. `_WIN32_WINNT` is not defined for it, so
  `mongoose.h` sets 0x0600 - harmless today (nothing Vista-only is called), but check the imports again after an
  update.
- **TLS is its OpenSSL backend on our LibreSSL** (`MG_TLS=MG_TLS_OPENSSL`, LibreSSL's headers where LibreSSL is
  built; FreeBSD's base OpenSSL there). A program linking `mongoose7_static` links `ssl_static` and `crypto_static`
  too (and `bcrypt`, as for curl). Consumers need no define: `mongoose.h` declares the same for any backend.
  **The one patch**: `BIO_set_init(bio, 1)` after mongoose makes its BIO in `mg_tls_init`. OpenSSL's `BIO_new`
  marks a BIO whose method has no `create` initialised; LibreSSL's doesn't, so every read failed with
  `BIO_R_UNINITIALIZED` ("tls hs: rc -1") and no handshake ever finished. Keep it across an update. Seen working
  (Debug Win32): an HTTPS server on it, with a self-signed RSA certificate, answered curl with 200. The client
  side (`mg_http_connect` to `https://`, checking a CA) is not tried yet.
- **No compression**: it links no zlib/zstd. `mg_http_serve_file` only sends `<file>.gz` beside a file, when one is
  there and the client takes gzip; WebSockets have no `permessage-deflate`.

## LibreSSL (`Projects/libressl`)

- **4.4.0, stock** (2026-11-02, from 2.7.5). `src` is the release tarball unchanged. 2.7.5 carried one patch,
  an XP fallback for `pthread_once` in `include/compat/pthread.h`; it is gone (see YY-Thunks below).
- **The source lists in `premake5.lua` are LibreSSL's own CMake lists**: `CRYPTO_SRC` from
  `src/crypto/CMakeLists.txt`, `SSL_SRC` and `BS_SRC` from `src/ssl/CMakeLists.txt`, and the compat files that
  CMake's checks choose for our defines. After an update, take them again from there rather than globbing:
  - The static ssl library must NOT contain `ssl/bs_*.c`. crypto has its own copies (`crypto/bytestring`), and
    linking both static libraries would clash. Only the ssl DLL builds them, with the compat files, because the
    crypto DLL exports neither.
  - Each library's `hidden/` include folder must come before `include/`: it holds the library's own copies of
    the public headers.
  - `OPENSSL_NO_ASM` everywhere, so the architecture folder (`crypto/arch/<arch>`, `crypto/bn/arch/<arch>`)
    only has to compile; the generic `arm` one is used for every target. The Apple Make build compiles all its
    architectures in one clang call, so a per-architecture folder could not be used there anyway.
- **Windows: `_WIN32_WINNT` is Vista's, as LibreSSL asks.** It uses three Vista functions -
  `InitOnceExecuteOnce`, `BCryptGenRandom`, `inet_pton` - and YY-Thunks (linked into every XP-targeting
  program and DLL) defines their `__imp_` symbols, with XP fallbacks (keyed events, `RtlGenRandom`, a hand
  parser). Checked with `dumpbin /imports`: no `bcrypt.dll` and none of the three in the DLLs or in GTAC's
  launcher and client. A target without YY-Thunks (ARM64) needs `bcrypt` linked; the shared jbuild list does
  not have it yet.
- **LibreSSL's object numbers are not OpenSSL's**: `NID_ED25519` is 952 here, 1087 in OpenSSL. Code that
  uses the names is fine; a hard-coded number (an FFI binding, a test) is not.
- **4.x keeps structures private that 2.7.5 exposed**, `ASN1_OBJECT` among them. Use the accessors
  (`OBJ_cmp`, `ASN1_STRING_get0_data`, ...). ModLauncher's `CodeSigning.cpp` was the one caller reaching inside.
- `Projects/libressl/CMakeLists.txt` is the old CMake build's hand-written wrapper for 2.7.5 and no longer
  matches the source; JBuild does not use it.

## curl (`Projects/curl`)

- **8.23.0, stock** (2026-11-02, from 8.12.1, once LibreSSL was updated). curl dropped Windows XP in 8.19.0:
  it refuses to build for less than Vista (`_WIN32_WINNT` 0x0600), and calls `BCryptGenRandom` and
  `if_nametoindex` itself. Built for Vista, with YY-Thunks covering those on XP builds; `YY.Depends.Analyzer
  <file> /Target:5.1.2600` (in the YY-Thunks folder; it writes `<file>.md` beside itself) reports no Windows
  import missing on XP in the curl DLL or in GTAC's client and launcher. 8.18.0 is the last release that
  still supports XP itself.
- **Windows builds from `Projects/curl/windows/curl_config.h`**, not curl's `config-win32.h`, which is for
  Visual Studio 2010-2013 only since 8.13. It is made by curl's own CMake: configure `src` with
  `-A Win32` and `-A x64`, `-DCURL_TARGET_WINDOWS_VERSION=0x0600`, OpenSSL pointed at this LibreSSL (on MSVC
  `FindOpenSSL` reads `LIB_EAY_RELEASE`/`SSL_EAY_RELEASE`, not `OPENSSL_*_LIBRARY`), zlib, and zstd
  (`-DCURL_ZSTD=ON`, `ZSTD_INCLUDE_DIR`/`ZSTD_LIBRARY`), and the features
  `CURL_DISABLE_OPENSSL_AUTO_LOAD_CONFIG` on, everything else at curl's defaults (LDAP is Windows' own `wldap32`, which XP has); then take
  `lib/curl_config.h`. Only `SIZEOF_SIZE_T`, `SIZEOF_CURL_SOCKET_T` and `ssize_t` differ between the two,
  and the header picks them by `_WIN64`. Regenerate it after updating curl; the features belong there, not
  in `premake5.lua`.
- **Linux builds LibreSSL and curl too** (2026-11-05, `crypto_static`, `ssl_static`, `curl_static`; premake's `TLS`
  list), so a program there can link them statically and run without the libssl/libcurl packages (jbuild's
  `TLS_LDLIBS`/`CURL_LDLIBS`). LibreSSL's Linux defines are what its own CMake finds on glibc 2.39, less
  `arc4random_buf`, `strlcpy` and `strlcat` (glibc has them only from 2.36/2.38), which come from LibreSSL's compat
  sources instead. `Projects/curl/linux/curl_config.h` was made by curl 8.23.0's CMake on Ubuntu 24.04 x64 with TLS,
  zlib, zstd and the optional libraries off (`-DCURL_ENABLE_SSL=OFF -DCURL_USE_OPENSSL=OFF -DCURL_ZLIB=OFF
  -DCURL_ZSTD=OFF -DCURL_BROTLI=OFF -DUSE_NGHTTP2=OFF -DUSE_LIBIDN2=OFF -DCURL_USE_LIBPSL=OFF -DCURL_USE_LIBSSH2=OFF
  -DCURL_USE_GSSAPI=OFF -DCURL_DISABLE_LDAP=ON`), as the Apple one, the defines adding TLS and compression; its CA
  bundle and path, which CMake wrote as "none", are taken out (Galactic gives curl its certificates in memory). It
  says `SIZEOF_SIZE_T 8`: x64 only. FreeBSD keeps its base OpenSSL. Seen: Galactic's UnitTests and a server program
  linked with them on Linux, `ldd` showing no libcurl, libssl or libcrypto, the tests passing and the server running.
- **`Projects/curl/apple/curl_config.h` is still 8.12.1's.** It has to be made again by curl's CMake on macOS
  before the iOS build can be trusted with 8.23.0 (not done).

## zstd (`Projects/zstd`)

- **1.5.7, stock** (2026-11-02), for Galactic's own use and for curl, which accepts zstd responses (`HAVE_ZSTD`). `zstd_static` and `zstd.dll` from `lib/`
  (common, compress, decompress, dictBuilder), with `zstd.h`, `zdict.h` and `zstd_errors.h` in `include\`.
  Two symlinks in the release's command-line tests (`tests/cli-tests/bin/unzstd`, `zstdcat`) cannot be made
  on Windows and are left out; nothing builds from them.
- **Multithreaded compression is built in** (`ZSTD_MULTITHREAD`, as zstd's own CMake does), but no thread starts
  unless a caller sets `ZSTD_c_nbWorkers`. On Windows it uses Vista's condition variables; YY-Thunks supplies them
  on XP, and the XP check on `zstd.dll` is clean (it imports only `KERNEL32` and the CRT).
- **`ZSTD_DISABLE_ASM` everywhere**: the x86_64 assembly decoder is GCC/clang-only, and the Apple build compiles
  every architecture in one go. MSVC always uses the C decoder anyway.

## jpeg (`Projects/jpeg`)

- **libjpeg-turbo 3.2.1, stock** (2026-11-05, replacing IJG libjpeg 6b from 1998), still `jpeg_static`. `src` is the
  release tarball unchanged; built for every target now (6b was Windows-only), with `jpeglib.h`, `jmorecfg.h`,
  `jerror.h` and `jconfig.h` in `include\`. Galactic reads JPEG images with it (`CMipLevel::LoadJPEG`).
- **Plain C: no SIMD, so no NASM** (`WITH_SIMD` undefined), as the user asked: the x86 SIMD code needs NASM to build,
  and plain C runs on any CPU XP does; it also lets one Apple compile serve every architecture. Arithmetic coding is in; the TurboJPEG API and the tools are not built.
- **The source list is the release's own `CMakeLists.txt` `JPEG_SOURCES`** plus `jaricom`/`jcarith`/`jdarith`; after an
  update, take it again from there. Since 3.0 a third of the files are compiled once per sample size (8, 12 and 16
  bits): the release's `src/src/wrapper/<name>-<bits>.c` each define `BITS_IN_JSAMPLE` and include the file, so
  premake lists the wrappers (`JPEG_WRAPPED` in premake5.lua) rather than compiling one file three times.
- **`jconfig.h` (`include/`, public) and `jconfigint.h`/`jversion.h` (`config/`, the library's own) are written by
  hand** from the release's `.in` templates, for every target at once: the 6.2 API (`JPEG_LIB_VERSION 62`),
  `SIZEOF_SIZE_T` and the inline/visibility/thread-local spellings chosen by the preprocessor. Regenerate them from
  the new templates after an update. On Windows `jconfig.h` keeps libjpeg's `boolean` = `unsigned char` (as 6b's did),
  guarded against `rpcndr.h`. Only TurboJPEG uses thread-local storage, and YY-Thunks makes it work on XP anyway.
- **After updating to it, build the `headers` project** before anything that uses it: `include\` still holds 6b's
  `jpeglib.h`/`jmorecfg.h`, and Galactic then fails to compile (`JCS_EXT_BGRA` undeclared, `INT32` redefined).
- Built and tested on Linux and Windows (2026-11-05: x86 and x64, Debug and Release; through Galactic, every one of
  10,970 JPEGs on the laptop decoded with no crash under cdb, and a sample matched Windows' own decoder pixel for
  pixel); the macOS, iOS and Android builds of it are untested. `Projects/jpeg/CMakeLists.txt` has the same list for
  the old CMake build.

## AngelScript (`Projects/angelscript`)

- **2.38.0, stock** (2026-11-02), for a planned Galactic scripting backend. `src` is the SDK folder of the release
  zip unchanged. `angelscript_static` and `angelscript.dll` (`ANGELSCRIPT_EXPORT`; a consumer of the DLL defines
  `ANGELSCRIPT_DLL_LIBRARY_IMPORT`) from `angelscript/source`; `angelscript_addons_static` from the add-ons a host
  registers (string, array, dictionary, any, handle, weakref, math, grid, datetime, serializer, helper, context
  manager, builder). Left out: `scriptfile` (scripts touching files directly), `scriptsocket` (Windows sockets)
  and `debugger` (a console debugger). The add-ons export nothing, so they are static only and work with either.
- **Headers**: `angelscript.h` in `include\` (every add-on includes it as `<angelscript.h>`), the add-ons' headers
  and `aswrappedcall.h` flattened into `include\angelscript\` (`#include <angelscript/scriptarray.h>`). Of the
  add-ons only `scriptfile` includes another by relative path, and it is not copied.
- **`AS_MAX_PORTABILITY` everywhere, and a consumer must define it too.** Natives are then registered through the
  generic calling convention only (`asCALL_GENERIC`; anything else is refused at run time), which needs none of
  the per-platform assembly (`as_callfunc_*.asm`/`.S`), so the same sources build for every target. The add-ons
  carry their own generic wrappers for it.
- XP: the Vista-only `InitializeCriticalSectionEx` is used only for Windows Store builds; the DLL imports only
  `KERNEL32` and `msvcrt`.

## miniaudio (`Projects/miniaudio`)

- **0.11.26, stock** (2026-11-02), meant as an audio device backend for Galactic on every platform (Android has
  none yet). `src` is the release unchanged; `miniaudio_static` is its one translation unit, with `miniaudio.h`
  in `include\`. Static only: upstream calls its `MA_DLL` unsupported.
- **Windows keeps miniaudio's run-time linking**, which is what makes it safe on XP: WASAPI, DirectSound and
  WinMM (and `avrt`, `ole32`) are found with `LoadLibrary`, and it falls back to whichever the system has. A
  test program linking it imports only `KERNEL32`, nothing in it newer than XP; on Windows 11 it chose WASAPI.
  Don't define `MA_NO_RUNTIME_LINKING` for Windows.
- **Apple builds `apple/miniaudio.m`**, which only includes `src/miniaudio.c`: iOS needs it compiled as
  Objective-C (`AVAudioSession`). Apple also gets `MA_NO_RUNTIME_LINKING`, because notarization rejects its
  run-time framework loading, so a consumer links `-framework CoreFoundation -framework CoreAudio -framework
  AudioToolbox`, plus `AVFoundation` on iOS. Not yet built on a Mac.
- **Android keeps run-time linking**: AAudio from Android 8, OpenSL ES before. Upstream notes some devices
  where `dlopen("libOpenSLES.so")` fails; the fix there would be `MA_NO_RUNTIME_LINKING` with `-lOpenSLES`
  (and `-laaudio`, which needs API 26). Not yet built for Android.
- Vorbis is not built in (that needs `extras/stb_vorbis.c` or the libvorbis decoder); MP3, FLAC and WAV are.

## litehtml (`Projects/litehtml`)

- **Upstream master 6293d441 (v0.10 + 55, 2026-11-07), with two patches of ours** (2026-11-08). `src` is
  github.com/litehtml/litehtml as it was copied in, plus the patches below; it was a submodule of the fork
  jack9267/litehtml (upstream 436f49c of 2022 with four patches, and no shared history with upstream). Gumbo is
  upstream's copy inside it (0.14.1). `CMakeLists.txt` beside `src` is the old CMake build's wrapper, not what is
  built. **After an update, put the patches back** (each is its own commit, so `git show` gives it):
  - **`document::restyle()`** (`document.h`/`.cpp`): styles applied again and the render tree rebuilt, for a
    stylesheet given to `root()->apply_stylesheet()` after the document was made - Galactic's HTML view gets
    `@import`ed sheets over the network that way. `media_changed()` does nearly the same but leaves out
    `fix_tables_layout()` (and never clears `m_tabular_elements`, which `restyle()` does before rebuilding).
  - **`draw_text` with the element** (`document_container.h`, `el_text.cpp`, `html_tag.cpp`): a second virtual
    that also takes the element the text is for (the text element, or the list item for its marker), calling the
    original unless overridden, so other containers compile unchanged. Galactic reads its
    `--lucasgui-text-shadow` custom property from it: upstream draws no `text-shadow` and its parser keeps only
    properties it knows, and `--` ones.
- **Gumbo's public headers are only `gumbo.h` and `tag_enum.h`**, installed to `include\gumbo\`: its `src`
  folder also holds internal headers with generic names (`util.h`, `vector.h`, `parser.h`), so it is not copied
  whole. No consumer includes gumbo; litehtml's public headers no longer do either.
- **This version is not source-compatible with the 2022 one** that Galactic's `litehtml_LucasGUI`, ModLauncher
  and GTAC were written against. The old version used wchar, `litehtml::context`, `html_tag::render` and the old
  `document_container`; the fork also changed `draw_text` to take the element (now the overload above) and made
  `fix_tables_layout` public (now inside `restyle()`). Don't install a build with it until they are ported.

