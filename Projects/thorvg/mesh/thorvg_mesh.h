/*
 * Dependencies: ThorVG's scenes as triangles. Not part of ThorVG: an engine of ours (its RenderMethod), built into
 * thorvg_static beside the CPU engine, that turns what a canvas holds into triangle lists a program draws with its
 * own renderer - coloured vertices, and for gradients other than linear ones and for pictures, a texture.
 *
 * Every shape is cut to its exact area (libtess2), clips and masks included, with a band a pixel wide along its edges
 * fading to nothing for anti-aliasing. A linear gradient is vertex colours (the triangles cut along each stop), so it
 * is exact at any size; radial and conic gradients and repeating ones are a small texture.
 *
 * Not everything ThorVG draws can be triangles of one colour each: blend modes, scene effects (blur, shadows), masks
 * whose own colours vary (a gradient mask) and a translucent group of overlapping shapes are drawn as near as can be
 * and complete() says so - a program that must have it right draws that canvas with a SwCanvas instead.
 */

#ifndef _THORVG_MESH_H_
#define _THORVG_MESH_H_

#include "thorvg.h"

namespace tvg
{

/**
 * @brief A vertex of a mesh: a position in pixels, a texture coordinate (unused without a texture), and a colour,
 * premultiplied by its alpha, which multiplies the texture's.
 */
struct MeshVertex
{
    float x, y;
    float u, v;
    uint8_t r, g, b, a;
};

/**
 * @brief A texture meshes sample: premultiplied RGBA, one byte each (ColorSpace::ABGR8888). @c key changes whenever
 * the pixels do, so a program can keep what it made of it while the key stays the same.
 */
struct MeshImage
{
    uint64_t key;
    const uint32_t* pixels;
    uint32_t width, height;
};

/**
 * @brief One draw: triangles (three indices each), in the order they are drawn, with the texture they sample
 * (an index into MeshCanvas::image(), or -1 for none). Blended premultiplied: source + destination * (1 - alpha).
 */
struct MeshBatch
{
    const MeshVertex* vertices;
    uint32_t vertexCount;
    const uint32_t* indices;
    uint32_t indexCount;
    int32_t image;
};

/**
 * @brief A canvas that draws into triangle lists.
 *
 * Use it as any canvas: add(), update(), draw(), sync(). After sync() the batches and images describe the last
 * draw, until the next update() or draw().
 */
struct TVG_API MeshCanvas final : Canvas
{
    ~MeshCanvas() override;

    /**
     * @brief Sets the area drawn, in pixels from (0, 0): anything outside is cut away.
     */
    Result target(uint32_t w, uint32_t h) noexcept;

    /** @brief The number of draws of the last draw(). */
    uint32_t batches() const noexcept;

    /** @brief A draw of the last draw(), nullptr past the end. */
    const MeshBatch* batch(uint32_t index) const noexcept;

    /** @brief The number of textures the draws sample. */
    uint32_t images() const noexcept;

    /** @brief A texture the draws sample, nullptr past the end. */
    const MeshImage* image(uint32_t index) const noexcept;

    /**
     * @brief Whether the last draw() was drawn exactly: false when it held something triangles of one colour can't
     * show (a blend mode, a scene effect, a mask of varying colour, a translucent group of overlapping shapes).
     */
    bool complete() const noexcept;

    static MeshCanvas* gen() noexcept;

    _TVG_PROTECTED_CTOR(MeshCanvas);
};

}

#endif //_THORVG_MESH_H_
