/* ThorVG's config.h, which its meson build writes from meson_options.txt (meson.build's config_h): written by hand
   for Dependencies' build, every target at once. The CPU engine; SVG, Lottie and TrueType loaders (pictures inside
   them come from the host, not ThorVG's PNG/JPG decoders); no file IO (nothing it loads reads a path on disk); no
   threads, SIMD, OpenMP, Lottie expressions (JerryScript) or logging. */
#define THORVG_VERSION_STRING "1.1.4"
#define THORVG_CPU_ENGINE_SUPPORT 1
#define THORVG_PARTIAL_RENDER_SUPPORT 1
#define THORVG_SVG_LOADER_SUPPORT 1
#define THORVG_LOTTIE_LOADER_SUPPORT 1
#define THORVG_SFNT_LOADER_SUPPORT 1
#define THORVG_TTF_LOADER_SUPPORT 1
#define WIN32_LEAN_AND_MEAN 1
