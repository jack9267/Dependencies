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

