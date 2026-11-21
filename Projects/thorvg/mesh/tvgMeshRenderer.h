/*
 * Dependencies: the mesh engine (thorvg_mesh.h): ThorVG's RenderMethod drawing into triangle lists.
 *
 * Each shape becomes one or two draws (fill, stroke): an area - its boundary contours, from libtess2, clips and the
 * viewport cut in when it is prepared - and a paint for it. Masks and a group's opacity are compositions, only known
 * as the scene is drawn: they cut or fade the draws made inside them then. A draw becomes triangles when the drawing
 * is done, with a band a pixel wide along the boundary fading to nothing.
 */

#ifndef _TVG_MESH_RENDERER_H_
#define _TVG_MESH_RENDERER_H_

#include <memory>
#include <vector>
#include "tvgRender.h"
#include "thorvg_mesh.h"

namespace tvg
{

// An area: closed contours, inside where their winding is one (libtess2's boundary contours)
struct MeshRegion
{
    std::vector<Point> pts;
    std::vector<uint32_t> counts;   // the points in each contour, in order

    bool empty() const { return counts.empty(); }
    void clear() { pts.clear(); counts.clear(); }
    BBox bounds() const;
};

// A picture a draw samples: premultiplied RGBA; a new key whenever it is made again
struct MeshTexture
{
    uint64_t key = 0;
    std::vector<uint32_t> pixels;
    uint32_t w = 0, h = 0;
    bool opaque = false;
};

struct MeshStop
{
    float offset;
    float c[4];   // straight RGBA, 0 to 1
};

// What fills a draw's area
struct MeshPaint
{
    enum class Type : uint8_t { Solid, Linear, Texture };

    Type type = Type::Solid;
    float alpha = 1.0f;           // the paint's opacity, over whatever it is
    float color[4] = {};          // Solid: straight RGBA
    float dx = 0, dy = 0, offset = 0;   // Linear (pad): t = dx * x + dy * y + offset
    std::vector<MeshStop> stops;
    std::shared_ptr<MeshTexture> texture;   // Texture: u = u[0] * x + u[1] * y + u[2], v likewise
    float u[3] = {}, v[3] = {};

    bool opaque() const;
    bool solid() const { return type == Type::Solid; }
};

// One draw: an area, its paint, and the triangles made of them (when first wanted)
struct MeshItem
{
    MeshRegion region;
    MeshPaint paint;
    std::vector<MeshVertex> vertices;
    std::vector<uint32_t> indices;
    bool built = false;

    void build();
};

struct MeshData
{
    virtual ~MeshData() {}
    RenderRegion bbox{};
    uint8_t opacity = 255;
    bool inexact = false;   // holds something it can't draw
};

struct MeshShape : MeshData
{
    MeshItem fill, stroke;
    bool hasFill = false, hasStroke = false;
    bool strokeFirst = false;
    MeshRegion clipArea;   // as a clipper: the area it lets through
};

struct MeshPicture : MeshData
{
    MeshItem image;
    bool hasImage = false;
};

struct MeshCompositor : RenderCompositor
{
    CompositionFlag flags = CompositionFlag::Invalid;
    size_t start = 0;                 // the first draw inside it (the mask's, when masking)
    size_t content = SIZE_MAX;        // masking: the first of the content's
    MaskMethod maskMethod = MaskMethod::None;
    uint8_t groupOpacity = 255;
    uint8_t maskOpacity = 255;
};

class MeshRenderer : public RenderMethod
{
public:
    MeshRenderer();
    ~MeshRenderer() override;

    bool preUpdate() override;
    RenderData prepare(const RenderShape& rshape, RenderData data, const Matrix& transform, const Array<RenderData>& clips, uint8_t opacity, RenderUpdateFlag flags, bool clipper) override;
    RenderData prepare(RenderSurface* surface, RenderData data, const Matrix& transform, const Array<RenderData>& clips, uint8_t opacity, FilterMethod filter, RenderUpdateFlag flags) override;
    bool postUpdate() override;
    bool preRender() override;
    bool renderShape(RenderData data) override;
    bool renderImage(RenderData data) override;
    bool postRender() override;
    void dispose(RenderData data) override;
    RenderRegion region(RenderData data) override;
    bool bounds(RenderData data, Point* pt4, const Matrix& m) override;
    bool blend(BlendMethod method) override;
    ColorSpace colorSpace() override;
    const RenderSurface* mainSurface() override;
    bool clear() override;
    bool sync() override;
    bool intersectsShape(RenderData data, const RenderRegion& region) override;
    bool intersectsImage(RenderData data, const RenderRegion& region) override;

    RenderCompositor* target(const RenderRegion& region, ColorSpace cs, CompositionFlag flags) override;
    bool beginComposite(RenderCompositor* cmp, MaskMethod method, uint8_t opacity) override;
    bool endComposite(RenderCompositor* cmp) override;

    void prepare(RenderEffect* effect, const Matrix& transform) override;
    bool region(RenderEffect* effect) override;
    bool render(RenderCompositor* cmp, const RenderEffect* effect, bool direct) override;
    void dispose(RenderEffect* effect) override;

    void damage(RenderData rd, const RenderRegion& region) override;
    bool partial(bool disable) override;
    uint32_t dirtyRegions() const override;
    Result dirtyRegions(Region* regions, uint32_t cnt) const override;

    bool target(uint32_t w, uint32_t h);

    // the last draw, for MeshCanvas
    std::vector<MeshBatch> batches;
    std::vector<MeshImage> images;
    bool complete = true;

private:
    struct Entry
    {
        const MeshItem* item = nullptr;        // a prepared draw, as it is
        std::shared_ptr<MeshItem> own;         // or one a composition changed
        const MeshItem& get() const { return own ? *own : *item; }
        MeshItem& change();                    // its own copy, to change
    };

    void push(const MeshItem& item);
    void group(MeshCompositor* cmp);
    void mask(MeshCompositor* cmp);

    RenderSurface surface;
    std::vector<Entry> entries;
    BlendMethod blendMethod = BlendMethod::Normal;
};

}

#endif //_TVG_MESH_RENDERER_H_
