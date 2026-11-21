/*
 * Dependencies: the mesh engine (thorvg_mesh.h, tvgMeshRenderer.h). Areas are libtess2's: a path's contours, by its
 * fill rule, become boundary contours, and clips, masks and fades are cut from those with libtess2's winding rules
 * (two areas added: inside both where the winding is two; one reversed: inside the first alone where it is one).
 */

#include <algorithm>
#include <atomic>
#include <cmath>
#include "tvgMeshRenderer.h"
#include "tvgMeshStroker.h"
#include "tvgFill.h"
#include "tesselator.h"

namespace tvg
{

static_assert(sizeof(Point) == 2 * sizeof(TESSreal), "libtess2 reads Points as pairs of its reals");

static const TESSreal NORMAL[3] = {0.0f, 0.0f, 1.0f};
static constexpr float LIMIT = 4194304.0f;          // libtess2 takes coordinates up to 2^23
static constexpr float FRINGE = 0.5f;               // the edge's fade reaches this far either side
static constexpr float MITER_LIMIT2 = 4.0f;         // how far (squared, in fades) a corner's fade may reach
static constexpr uint32_t TEXTURE_MAX = 256;        // a baked gradient's largest side, in texels

struct Tess
{
    TESStesselator* tess = tessNewTess(nullptr);
    ~Tess() { if (tess) tessDeleteTess(tess); }
    operator TESStesselator*() const { return tess; }
};


/************************************************************************/
/* Areas                                                                */
/************************************************************************/

BBox MeshRegion::bounds() const
{
    BBox box;
    box.init();
    for (auto& p : pts) {
        box.min = {std::min(box.min.x, p.x), std::min(box.min.y, p.y)};
        box.max = {std::max(box.max.x, p.x), std::max(box.max.y, p.y)};
    }
    return box;
}


static float _area(const Point* pts, uint32_t count)
{
    auto sum = 0.0f;
    for (uint32_t i = 0; i < count; ++i) {
        auto& a = pts[i];
        auto& b = pts[(i + 1) % count];
        sum += a.x * b.y - b.x * a.y;
    }
    return sum * 0.5f;
}


static void _add(TESStesselator* tess, const Point* pts, uint32_t count, bool reverse = false)
{
    if (count < 3) return;
    if (!reverse) {
        tessAddContour(tess, 2, pts, sizeof(Point), count);
        return;
    }
    std::vector<Point> reversed(pts, pts + count);
    std::reverse(reversed.begin(), reversed.end());
    tessAddContour(tess, 2, reversed.data(), sizeof(Point), count);
}


static void _add(TESStesselator* tess, const MeshRegion& region, bool reverse = false)
{
    auto pts = region.pts.data();
    for (auto count : region.counts) {
        _add(tess, pts, count, reverse);
        pts += count;
    }
}


static void _boundary(TESStesselator* tess, int rule, MeshRegion& out)
{
    out.clear();
    if (!tessTesselate(tess, rule, TESS_BOUNDARY_CONTOURS, 0, 2, NORMAL)) return;
    auto verts = reinterpret_cast<const Point*>(tessGetVertices(tess));
    auto elems = tessGetElements(tess);
    auto count = tessGetElementCount(tess);
    for (int i = 0; i < count; ++i) {
        auto base = elems[i * 2];
        auto n = elems[i * 2 + 1];
        if (n < 3) continue;
        out.pts.insert(out.pts.end(), verts + base, verts + base + n);
        out.counts.push_back(uint32_t(n));
    }
}


// The sign of an outside contour's area, as libtess2 gives them: what a contour turned that way counts as inside
static float _orientation()
{
    static const float sign = [] {
        const Point square[4] = {{0.0f, 0.0f}, {1.0f, 0.0f}, {1.0f, 1.0f}, {0.0f, 1.0f}};
        Tess tess;
        _add(tess, square, 4);
        MeshRegion out;
        _boundary(tess, TESS_WINDING_NONZERO, out);
        return (!out.empty() && _area(out.pts.data(), out.counts[0]) < 0.0f) ? -1.0f : 1.0f;
    }();
    return sign;
}


static void _intersect(MeshRegion& a, const MeshRegion& b)
{
    if (a.empty()) return;
    if (b.empty()) {
        a.clear();
        return;
    }
    Tess tess;
    _add(tess, a);
    _add(tess, b);
    MeshRegion out;
    _boundary(tess, TESS_WINDING_ABS_GEQ_TWO, out);
    a = std::move(out);
}


static void _subtract(MeshRegion& a, const MeshRegion& b)
{
    if (a.empty() || b.empty()) return;
    Tess tess;
    _add(tess, a);
    _add(tess, b, true);
    MeshRegion out;
    _boundary(tess, _orientation() > 0.0f ? TESS_WINDING_POSITIVE : TESS_WINDING_NEGATIVE, out);
    a = std::move(out);
}


static void _unite(MeshRegion& a, const MeshRegion& b)
{
    if (b.empty()) return;
    if (a.empty()) {
        a = b;
        return;
    }
    Tess tess;
    _add(tess, a);
    _add(tess, b);
    MeshRegion out;
    _boundary(tess, TESS_WINDING_NONZERO, out);
    a = std::move(out);
}


static bool _overlap(const BBox& a, const BBox& b)
{
    return a.min.x < b.max.x && b.min.x < a.max.x && a.min.y < b.max.y && b.min.y < a.max.y;
}


// Cut an area to a rectangle (the viewport), when it reaches outside it
static void _crop(MeshRegion& region, const RenderRegion& rect)
{
    if (region.empty()) return;
    if (rect.invalid()) {   // nothing shows (an empty clip, as a fast-tracked one comes)
        region.clear();
        return;
    }
    auto box = region.bounds();
    if (box.min.x >= rect.xMin && box.min.y >= rect.yMin && box.max.x <= rect.xMax && box.max.y <= rect.yMax) return;

    auto x0 = std::max(float(rect.xMin), -LIMIT), y0 = std::max(float(rect.yMin), -LIMIT);
    auto x1 = std::min(float(rect.xMax), LIMIT), y1 = std::min(float(rect.yMax), LIMIT);
    MeshRegion r;
    if (_orientation() > 0.0f) r.pts = {{x0, y0}, {x1, y0}, {x1, y1}, {x0, y1}};
    else r.pts = {{x0, y0}, {x0, y1}, {x1, y1}, {x1, y0}};
    r.counts = {4};
    _intersect(region, r);
}


static Point _clamp(const Point& p)
{
    return {std::min(std::max(p.x, -LIMIT), LIMIT), std::min(std::max(p.y, -LIMIT), LIMIT)};
}


// A path's contours, transformed and its curves flattened, by its fill rule
static void _fillRegion(const RenderPath& path, const Matrix& m, FillRule rule, MeshRegion& out)
{
    std::vector<Point> pts;
    std::vector<uint32_t> counts;
    size_t start = 0;
    auto valid = true;
    auto end = [&]() {
        auto n = pts.size() - start;
        if (n >= 3 && valid) counts.push_back(uint32_t(n));
        else pts.resize(start);
        start = pts.size();
        valid = true;
    };
    auto push = [&](const Point& p) {
        if (!std::isfinite(p.x) || !std::isfinite(p.y)) valid = false;
        pts.push_back(_clamp(p));
    };

    auto p = path.pts.data;
    Point cur{}, first{};
    auto open = false;
    for (auto& cmd : path.cmds) {
        switch (cmd) {
            case PathCommand::MoveTo: {
                end();
                cur = first = *p++ * m;
                push(cur);
                open = true;
                break;
            }
            case PathCommand::LineTo: {
                if (!open) { push(first); open = true; }
                cur = *p++ * m;
                push(cur);
                break;
            }
            case PathCommand::CubicTo: {
                if (!open) { push(first); open = true; }
                Bezier bz(cur, p[0] * m, p[1] * m, p[2] * m);
                auto n = std::max(1u, std::min(bz.segments(), 1024u));
                for (uint32_t i = 1; i <= n; ++i) push(i == n ? bz.end : bz.at(float(i) / float(n)));
                cur = bz.end;
                p += 3;
                break;
            }
            case PathCommand::Close: {
                end();
                cur = first;
                open = false;
                break;
            }
        }
    }
    end();

    if (counts.empty()) {
        out.clear();
        return;
    }
    MeshRegion raw;
    raw.pts = std::move(pts);
    raw.counts = std::move(counts);
    Tess tess;
    _add(tess, raw);
    _boundary(tess, rule == FillRule::EvenOdd ? TESS_WINDING_ODD : TESS_WINDING_NONZERO, out);
}


// A stroke's area: the stroker's triangles (local, then transformed, as the GL engine does them), merged
static void _strokeRegion(const RenderShape& rs, const RenderPath& path, const Matrix& m, MeshRegion& out)
{
    out.clear();
    auto width = rs.strokeWidth();
    auto scale = scaling(m);
    if (!std::isfinite(width) || !std::isfinite(scale) || tvg::zero(width) || tvg::zero(scale)) return;

    MeshGeometryBuffer buffer;
    MeshStroker stroker(&buffer, width, rs.strokeCap(), rs.strokeJoin(), rs.strokeMiterlimit(), scale);
    RenderPath dashed;
    if (gpuStrokeDash(rs, dashed, nullptr)) stroker.run(dashed);
    else stroker.run(path);

    Tess tess;
    auto v = buffer.vertex.data;
    auto added = false;
    for (uint32_t i = 0; i + 2 < buffer.index.count; i += 3) {
        Point tri[3];
        auto valid = true;
        for (int k = 0; k < 3; ++k) {
            auto idx = buffer.index[i + k];
            tri[k] = Point{v[idx * 2], v[idx * 2 + 1]} * m;
            if (!std::isfinite(tri[k].x) || !std::isfinite(tri[k].y)) valid = false;
            tri[k] = _clamp(tri[k]);
        }
        if (!valid) continue;
        auto area = _area(tri, 3);
        if (fabsf(area) < 1e-6f) continue;
        if (area < 0.0f) std::swap(tri[1], tri[2]);   // all one way round, so overlaps add rather than cancel
        _add(tess, tri, 3);
        added = true;
    }
    if (added) _boundary(tess, TESS_WINDING_NONZERO, out);
}


/************************************************************************/
/* Paints                                                               */
/************************************************************************/

static uint64_t _key()
{
    static std::atomic<uint64_t> next{1};
    return next++;
}


bool MeshPaint::opaque() const
{
    if (alpha < 1.0f) return false;
    switch (type) {
        case Type::Solid: return color[3] >= 1.0f;
        case Type::Linear: {
            for (auto& s : stops) if (s.c[3] < 1.0f) return false;
            return true;
        }
        case Type::Texture: return texture && texture->opaque;
    }
    return false;
}


// A linear gradient's colour at t on the side of any hard edge that tc (the triangle's middle) is on: the stops
// either side of tc, with t held between them - so the two sides of a hard edge (two stops at one offset) differ
static void _bandColor(const std::vector<MeshStop>& stops, float t, float tc, float out[4])
{
    if (tc <= stops.front().offset) {
        for (int k = 0; k < 4; ++k) out[k] = stops.front().c[k];
        return;
    }
    for (size_t i = 0; i + 1 < stops.size(); ++i) {
        auto& a = stops[i];
        auto& b = stops[i + 1];
        if (tc < b.offset) {
            auto div = b.offset - a.offset;
            auto f = div > 0.0f ? std::min(std::max((t - a.offset) / div, 0.0f), 1.0f) : 1.0f;
            for (int k = 0; k < 4; ++k) out[k] = a.c[k] + (b.c[k] - a.c[k]) * f;
            return;
        }
    }
    for (int k = 0; k < 4; ++k) out[k] = stops.back().c[k];
}


// A gradient's colour at t (straight), as the CPU engine's colour table has it: the first stop's before it, the
// last's after, straight colours interpolated between
static void _stopColor(const std::vector<MeshStop>& stops, float t, float out[4])
{
    const MeshStop* c = &stops.front();
    if (t > stops.front().offset) {
        c = &stops.back();
        for (size_t i = 0; i + 1 < stops.size(); ++i) {
            auto& a = stops[i];
            auto& b = stops[i + 1];
            if (t < b.offset) {
                auto div = b.offset - a.offset;
                auto f = div > 0.0f ? (t - a.offset) / div : 1.0f;
                for (int k = 0; k < 4; ++k) out[k] = a.c[k] + (b.c[k] - a.c[k]) * f;
                return;
            }
        }
    }
    for (int k = 0; k < 4; ++k) out[k] = c->c[k];
}


static float _spread(FillSpread spread, float t)
{
    switch (spread) {
        case FillSpread::Pad: return std::min(std::max(t, 0.0f), 1.0f);
        case FillSpread::Repeat: return t - floorf(t);
        case FillSpread::Reflect: {
            t = t - 2.0f * floorf(t * 0.5f);
            return t > 1.0f ? 2.0f - t : t;
        }
    }
    return t;
}


static uint32_t _pack(const float c[4], float alpha = 1.0f)
{
    auto a = std::min(std::max(c[3] * alpha, 0.0f), 1.0f);
    auto r = uint32_t(std::min(std::max(c[0], 0.0f), 1.0f) * a * 255.0f + 0.5f);
    auto g = uint32_t(std::min(std::max(c[1], 0.0f), 1.0f) * a * 255.0f + 0.5f);
    auto b = uint32_t(std::min(std::max(c[2], 0.0f), 1.0f) * a * 255.0f + 0.5f);
    return r | (g << 8) | (b << 16) | (uint32_t(a * 255.0f + 0.5f) << 24);
}


// A gradient that isn't a padded linear one: baked over the area's bounds, a pixel beyond each side for the fade
static void _bake(const Fill* fill, const Matrix& transform, const BBox& box, MeshPaint& paint)
{
    Matrix inv;
    if (!inverse(&transform, &inv)) {
        paint.alpha = 0.0f;
        return;
    }

    auto spread = fill->spread();
    auto type = fill->type();
    float lx = 0, ly = 0, loff = 0;                                    // linear
    float fx = 0, fy = 0, fr = 0, rdx = 0, rdy = 0, dr = 0, a = 1, invA = 1;   // radial
    float cx = 0, cy = 0, coff = 0;                                    // conic

    if (type == Type::LinearGradient) {
        float x1, y1, x2, y2;
        static_cast<const LinearGradient*>(fill)->linear(&x1, &y1, &x2, &y2);
        lx = x2 - x1;
        ly = y2 - y1;
        auto len = lx * lx + ly * ly;
        if (len < FLOAT_EPSILON) {
            paint.type = MeshPaint::Type::Solid;
            for (int k = 0; k < 4; ++k) paint.color[k] = paint.stops.back().c[k];
            return;
        }
        lx /= len;
        ly /= len;
        loff = -lx * x1 - ly * y1;
    } else if (type == Type::RadialGradient) {
        auto radial = static_cast<const RadialGradient*>(fill);
        float r;
        radial->radial(&cx, &cy, &r, &fx, &fy, &fr);
        if (!CONST_RADIAL(radial)->correct(fx, fy, fr)) {
            paint.type = MeshPaint::Type::Solid;
            for (int k = 0; k < 4; ++k) paint.color[k] = paint.stops.back().c[k];
            return;
        }
        dr = r - fr;
        rdx = cx - fx;
        rdy = cy - fy;
        a = dr * dr - rdx * rdx - rdy * rdy;
        auto precision = std::max(1e-5f, std::max(dr * dr, 1.0f) * 1e-4f);
        if (a < precision) a = precision;
        invA = 1.0f / a;
    } else if (type == Type::ConicGradient) {
        float angle;
        static_cast<const ConicGradient*>(fill)->conic(&cx, &cy, &angle);
        coff = -angle / 360.0f;
    } else {
        paint.alpha = 0.0f;
        return;
    }

    auto x0 = box.min.x - 1.0f, y0 = box.min.y - 1.0f;
    auto w = std::max(box.max.x - box.min.x + 2.0f, 1.0f), h = std::max(box.max.y - box.min.y + 2.0f, 1.0f);
    auto tw = uint32_t(std::min(std::max(ceilf(w), 1.0f), float(TEXTURE_MAX)));
    auto th = uint32_t(std::min(std::max(ceilf(h), 1.0f), float(TEXTURE_MAX)));

    auto texture = std::make_shared<MeshTexture>();
    texture->key = _key();
    texture->w = tw;
    texture->h = th;
    texture->pixels.resize(size_t(tw) * th);
    auto opaque = true;
    for (auto& s : paint.stops) if (s.c[3] < 1.0f) opaque = false;
    texture->opaque = opaque;

    float color[4];
    for (uint32_t j = 0; j < th; ++j) {
        for (uint32_t i = 0; i < tw; ++i) {
            auto x = x0 + (i + 0.5f) * w / tw;
            auto y = y0 + (j + 0.5f) * h / th;
            auto gx = inv.e11 * x + inv.e12 * y + inv.e13;
            auto gy = inv.e21 * x + inv.e22 * y + inv.e23;
            float t;
            if (type == Type::LinearGradient) {
                t = lx * gx + ly * gy + loff;
            } else if (type == Type::RadialGradient) {
                auto rx = gx - fx, ry = gy - fy;
                if (a < 0.0005f) {
                    t = 0.5f * (rx * rx + ry * ry - fr * fr) / (dr * fr + rx * rdx + ry * rdy);
                } else {
                    auto b = (dr * fr + rx * rdx + ry * rdy) * invA;
                    auto det = b * b + (rx * rx + ry * ry - fr * fr) * invA;
                    t = sqrtf(std::max(det, 0.0f)) - b;
                }
            } else {
                t = atan2f(gy - cy, gx - cx) * (0.5f / MATH_PI) + coff;
                t = t - floorf(t);
            }
            if (!std::isfinite(t)) t = 0.0f;
            _stopColor(paint.stops, _spread(spread, t), color);
            texture->pixels[size_t(j) * tw + i] = _pack(color);
        }
    }

    paint.type = MeshPaint::Type::Texture;
    paint.texture = texture;
    paint.u[0] = 1.0f / w; paint.u[1] = 0.0f; paint.u[2] = -x0 / w;
    paint.v[0] = 0.0f; paint.v[1] = 1.0f / h; paint.v[2] = -y0 / h;
}


static void _paint(const Fill* fill, const RenderColor& color, uint8_t opacity, const Matrix& m, const MeshRegion& region, MeshPaint& paint)
{
    paint = MeshPaint();
    paint.alpha = opacity / 255.0f;

    if (!fill) {
        paint.color[0] = color.r / 255.0f;
        paint.color[1] = color.g / 255.0f;
        paint.color[2] = color.b / 255.0f;
        paint.color[3] = color.a / 255.0f;
        return;
    }

    const Fill::ColorStop* stops = nullptr;
    auto cnt = fill->colorStops(&stops);
    if (cnt == 0 || !stops) {
        paint.alpha = 0.0f;
        return;
    }
    // offsets in order, each at least the one before (as the CPU engine's colour table takes them)
    auto last = -FLT_MAX;
    for (uint32_t i = 0; i < cnt; ++i) {
        last = std::max(last, stops[i].offset);
        paint.stops.push_back({last, {stops[i].r / 255.0f, stops[i].g / 255.0f, stops[i].b / 255.0f, stops[i].a / 255.0f}});
    }
    if (cnt == 1) {
        for (int k = 0; k < 4; ++k) paint.color[k] = paint.stops[0].c[k];
        return;
    }

    auto transform = m * fill->transform();

    if (fill->type() == Type::LinearGradient && fill->spread() == FillSpread::Pad) {
        // as the CPU engine sets it up (_prepareLinear): t across the screen
        float x1, y1, x2, y2;
        static_cast<const LinearGradient*>(fill)->linear(&x1, &y1, &x2, &y2);
        auto dx = x2 - x1, dy = y2 - y1;
        auto len = dx * dx + dy * dy;
        if (len < FLOAT_EPSILON) {
            for (int k = 0; k < 4; ++k) paint.color[k] = paint.stops.back().c[k];
            return;
        }
        dx /= len;
        dy /= len;
        auto offset = -dx * x1 - dy * y1;
        Matrix inv;
        if (!inverse(&transform, &inv)) {
            paint.alpha = 0.0f;
            return;
        }
        paint.type = MeshPaint::Type::Linear;
        paint.offset = offset + dx * inv.e13 + dy * inv.e23;
        paint.dx = dx * inv.e11 + dy * inv.e21;
        paint.dy = dx * inv.e12 + dy * inv.e22;
        return;
    }

    _bake(fill, transform, region.bounds(), paint);
}


static std::shared_ptr<MeshTexture> _texture(const RenderSurface* surface)
{
    if (!surface || !surface->data || surface->w == 0 || surface->h == 0 || surface->channelSize != sizeof(uint32_t)) return nullptr;

    auto texture = std::make_shared<MeshTexture>();
    texture->key = _key();
    texture->w = surface->w;
    texture->h = surface->h;
    texture->pixels.resize(size_t(surface->w) * surface->h);
    auto bgr = (surface->cs == ColorSpace::ARGB8888 || surface->cs == ColorSpace::ARGB8888S || surface->cs == ColorSpace::XRGB8888);
    auto noAlpha = (surface->cs == ColorSpace::XRGB8888 || surface->cs == ColorSpace::XBGR8888);
    auto straight = !surface->premultiplied && !noAlpha;
    auto opaque = true;

    for (uint32_t y = 0; y < surface->h; ++y) {
        auto src = surface->buf32 + size_t(y) * surface->stride;
        auto dst = texture->pixels.data() + size_t(y) * surface->w;
        for (uint32_t x = 0; x < surface->w; ++x) {
            auto c = src[x];
            uint32_t r = c & 0xff, g = (c >> 8) & 0xff, b = (c >> 16) & 0xff, a = noAlpha ? 255 : (c >> 24);
            if (bgr) std::swap(r, b);
            if (straight) {
                r = (r * a + 127) / 255;
                g = (g * a + 127) / 255;
                b = (b * a + 127) / 255;
            }
            if (a < 255) opaque = false;
            dst[x] = r | (g << 8) | (b << 16) | (a << 24);
        }
    }
    texture->opaque = opaque;
    return texture;
}


/************************************************************************/
/* Triangles                                                            */
/************************************************************************/

struct MeshTri
{
    float x, y, cover;
};


static MeshTri _lerp(const MeshTri& a, const MeshTri& b, float f)
{
    return {a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f, a.cover + (b.cover - a.cover) * f};
}


// Cut every triangle crossing the line a * x + b * y + c = value into pieces on either side
static void _split(std::vector<MeshTri>& tris, float a, float b, float c, float value)
{
    std::vector<MeshTri> out;
    out.reserve(tris.size() + tris.size() / 2);
    for (size_t i = 0; i + 2 < tris.size(); i += 3) {
        auto t = &tris[i];
        float f[3];
        auto below = 0, above = 0;
        for (int k = 0; k < 3; ++k) {
            f[k] = a * t[k].x + b * t[k].y + c - value;
            if (f[k] < 0.0f) ++below;
            else if (f[k] > 0.0f) ++above;
        }
        if (!below || !above) {
            out.insert(out.end(), t, t + 3);
            continue;
        }
        MeshTri lo[4], hi[4];
        int nl = 0, nh = 0;
        for (int k = 0; k < 3; ++k) {
            auto& cur = t[k];
            auto& nxt = t[(k + 1) % 3];
            auto fc = f[k], fn = f[(k + 1) % 3];
            if (fc <= 0.0f) lo[nl++] = cur;
            if (fc >= 0.0f) hi[nh++] = cur;
            if ((fc < 0.0f && fn > 0.0f) || (fc > 0.0f && fn < 0.0f)) {
                auto p = _lerp(cur, nxt, fc / (fc - fn));
                lo[nl++] = p;
                hi[nh++] = p;
            }
        }
        for (int k = 1; k + 1 < nl; ++k) { out.push_back(lo[0]); out.push_back(lo[k]); out.push_back(lo[k + 1]); }
        for (int k = 1; k + 1 < nh; ++k) { out.push_back(hi[0]); out.push_back(hi[k]); out.push_back(hi[k + 1]); }
    }
    tris.swap(out);
}


static MeshVertex _vertex(float x, float y, uint32_t rgba, const MeshPaint& paint)
{
    MeshVertex v;
    v.x = x;
    v.y = y;
    v.u = v.v = 0.0f;
    if (paint.type == MeshPaint::Type::Texture) {
        v.u = paint.u[0] * x + paint.u[1] * y + paint.u[2];
        v.v = paint.v[0] * x + paint.v[1] * y + paint.v[2];
    }
    v.r = uint8_t(rgba);
    v.g = uint8_t(rgba >> 8);
    v.b = uint8_t(rgba >> 16);
    v.a = uint8_t(rgba >> 24);
    return v;
}


// The area as triangles, its boundary's vertices moved half a pixel in and a band added from there to half a pixel
// out, fading from the paint's coverage to none - the anti-aliasing
void MeshItem::build()
{
    built = true;
    vertices.clear();
    indices.clear();
    if (region.empty() || paint.alpha <= 0.0f) return;

    Tess tess;
    _add(tess, region);
    if (!tessTesselate(tess, TESS_WINDING_NONZERO, TESS_CONNECTED_POLYGONS, 3, 2, NORMAL)) return;
    auto vcount = uint32_t(tessGetVertexCount(tess));
    auto verts = reinterpret_cast<const Point*>(tessGetVertices(tess));
    auto ecount = uint32_t(tessGetElementCount(tess));
    auto elems = tessGetElements(tess);
    if (vcount == 0 || ecount == 0) return;

    std::vector<Point> pos(verts, verts + vcount);
    std::vector<Point> sum(vcount, Point{0.0f, 0.0f});
    std::vector<uint8_t> edgesAt(vcount, 0);
    struct Edge { uint32_t a, b; };
    std::vector<Edge> edges;
    std::vector<uint32_t> tris;
    tris.reserve(ecount * 3);

    for (uint32_t e = 0; e < ecount; ++e) {
        auto poly = elems + e * 6;
        auto nei = poly + 3;
        if (poly[0] == TESS_UNDEF || poly[1] == TESS_UNDEF || poly[2] == TESS_UNDEF) continue;
        for (int k = 0; k < 3; ++k) tris.push_back(uint32_t(poly[k]));
        for (int k = 0; k < 3; ++k) {
            if (nei[k] != TESS_UNDEF) continue;
            auto a = uint32_t(poly[k]), b = uint32_t(poly[(k + 1) % 3]), c = uint32_t(poly[(k + 2) % 3]);
            auto d = pos[b] - pos[a];
            auto len = length(d);
            if (len < 1e-6f) continue;
            Point n = {d.y / len, -d.x / len};
            if (dot(n, pos[c] - pos[a]) > 0.0f) n = {-n.x, -n.y};   // outwards: away from the triangle
            edges.push_back({a, b});
            sum[a] = sum[a] + n;
            sum[b] = sum[b] + n;
            if (edgesAt[a] < 255) ++edgesAt[a];
            if (edgesAt[b] < 255) ++edgesAt[b];
        }
    }

    // each boundary vertex: in by half a pixel, and its outer copy out by as much, along the mitred normal
    std::vector<uint32_t> outer(vcount, UINT32_MAX);
    std::vector<Point> all = pos;
    std::vector<float> cover(vcount, 1.0f);
    for (uint32_t i = 0; i < vcount; ++i) {
        if (!edgesAt[i]) continue;
        auto dm = sum[i] * (1.0f / edgesAt[i]);
        auto dmr2 = dot(dm, dm);
        if (dmr2 > 1e-6f) dm = dm * std::min(1.0f / dmr2, MITER_LIMIT2);
        all[i] = pos[i] - dm * FRINGE;
        outer[i] = uint32_t(all.size());
        all.push_back(pos[i] + dm * FRINGE);
        cover.push_back(0.0f);
    }
    for (auto& e : edges) {
        auto oa = outer[e.a], ob = outer[e.b];
        tris.push_back(e.a); tris.push_back(e.b); tris.push_back(ob);
        tris.push_back(e.a); tris.push_back(ob); tris.push_back(oa);
    }

    if (paint.type == MeshPaint::Type::Linear) {
        // cut along each stop (more often where the alpha changes, as straight colours don't interpolate evenly
        // premultiplied), so that a vertex's colour between two cuts is the gradient's
        std::vector<MeshTri> soup;
        soup.reserve(tris.size());
        auto tmin = FLT_MAX, tmax = -FLT_MAX;
        for (auto i : tris) {
            soup.push_back({all[i].x, all[i].y, cover[i]});
            auto t = paint.dx * all[i].x + paint.dy * all[i].y + paint.offset;
            tmin = std::min(tmin, t);
            tmax = std::max(tmax, t);
        }
        std::vector<float> cuts;
        for (size_t s = 0; s < paint.stops.size(); ++s) {
            cuts.push_back(paint.stops[s].offset);
            if (s + 1 < paint.stops.size() && paint.stops[s].c[3] != paint.stops[s + 1].c[3]) {
                auto o0 = paint.stops[s].offset, o1 = paint.stops[s + 1].offset;
                for (int k = 1; k < 8; ++k) cuts.push_back(o0 + (o1 - o0) * k / 8.0f);
            }
        }
        for (auto cut : cuts) {
            if (cut > tmin && cut < tmax) _split(soup, paint.dx, paint.dy, paint.offset, cut);
        }
        vertices.reserve(soup.size());
        indices.reserve(soup.size());
        float color[4];
        for (size_t i = 0; i + 2 < soup.size(); i += 3) {
            auto tc = paint.dx * (soup[i].x + soup[i + 1].x + soup[i + 2].x) / 3.0f + paint.dy * (soup[i].y + soup[i + 1].y + soup[i + 2].y) / 3.0f + paint.offset;
            for (size_t k = i; k < i + 3; ++k) {
                auto& v = soup[k];
                _bandColor(paint.stops, paint.dx * v.x + paint.dy * v.y + paint.offset, tc, color);
                indices.push_back(uint32_t(vertices.size()));
                vertices.push_back(_vertex(v.x, v.y, _pack(color, paint.alpha * v.cover), paint));
            }
        }
        return;
    }

    static const float WHITE[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    auto base = (paint.type == MeshPaint::Type::Texture) ? WHITE : paint.color;
    vertices.reserve(all.size());
    for (size_t i = 0; i < all.size(); ++i) {
        vertices.push_back(_vertex(all[i].x, all[i].y, _pack(base, paint.alpha * cover[i]), paint));
    }
    indices = std::move(tris);
}


/************************************************************************/
/* MeshRenderer                                                         */
/************************************************************************/

MeshRenderer::MeshRenderer()
{
    surface.cs = ColorSpace::ABGR8888;
    surface.channelSize = sizeof(uint32_t);
    surface.premultiplied = true;
}


MeshRenderer::~MeshRenderer()
{
}


bool MeshRenderer::target(uint32_t w, uint32_t h)
{
    surface.w = surface.stride = w;
    surface.h = h;
    return viewport({0, 0, int32_t(w), int32_t(h)});
}


bool MeshRenderer::preUpdate()
{
    return true;
}


static void _cut(MeshRegion& region, const Array<RenderData>& clips, const RenderRegion& vport)
{
    for (auto& c : clips) {
        if (region.empty()) return;
        auto clip = static_cast<const MeshShape*>(c);
        if (!clip) continue;
        _intersect(region, clip->clipArea);
    }
    _crop(region, vport);
}


static RenderRegion _bbox(const MeshRegion& a, const MeshRegion& b)
{
    BBox box;
    box.init();
    for (auto r : {&a, &b}) {
        if (r->empty()) continue;
        auto rb = r->bounds();
        box.min = {std::min(box.min.x, rb.min.x), std::min(box.min.y, rb.min.y)};
        box.max = {std::max(box.max.x, rb.max.x), std::max(box.max.y, rb.max.y)};
    }
    if (box.min.x > box.max.x) return {};
    return {int32_t(floorf(box.min.x - FRINGE)), int32_t(floorf(box.min.y - FRINGE)), int32_t(ceilf(box.max.x + FRINGE)), int32_t(ceilf(box.max.y + FRINGE))};
}


RenderData MeshRenderer::prepare(const RenderShape& rs, RenderData data, const Matrix& transform, const Array<RenderData>& clips, uint8_t opacity, RenderUpdateFlag flags, bool clipper)
{
    auto shape = data ? static_cast<MeshShape*>(data) : new MeshShape;
    shape->opacity = opacity;
    shape->fill.built = shape->stroke.built = false;

    const RenderPath* path = &rs.path;
    RenderPath trimmed;
    if (rs.trimpath()) {
        if (rs.stroke->trim.trim(rs.path, trimmed)) path = &trimmed;
        else path = nullptr;
    }

    // a clipper lets through its fill's area (cut by its own clips)
    if (clipper) {
        shape->hasFill = shape->hasStroke = false;
        shape->clipArea.clear();
        if (path) _fillRegion(*path, transform, rs.rule, shape->clipArea);
        _cut(shape->clipArea, clips, vport);
        shape->bbox = _bbox(shape->clipArea, MeshRegion());
        return shape;
    }

    shape->fill.region.clear();
    shape->stroke.region.clear();
    shape->hasFill = path && (rs.fill || rs.color.a > 0);
    shape->hasStroke = path && rs.stroke && rs.strokeWidth() > 0.0f && (rs.stroke->fill || rs.stroke->color.a > 0);
    shape->strokeFirst = rs.strokeFirst();

    if (shape->hasFill) {
        _fillRegion(*path, transform, rs.rule, shape->fill.region);
        _cut(shape->fill.region, clips, vport);
        _paint(rs.fill, rs.color, opacity, transform, shape->fill.region, shape->fill.paint);
        shape->hasFill = !shape->fill.region.empty() && shape->fill.paint.alpha > 0.0f;
    }
    if (shape->hasStroke) {
        _strokeRegion(rs, *path, transform, shape->stroke.region);
        _cut(shape->stroke.region, clips, vport);
        _paint(rs.stroke->fill, rs.stroke->color, opacity, transform, shape->stroke.region, shape->stroke.paint);
        shape->hasStroke = !shape->stroke.region.empty() && shape->stroke.paint.alpha > 0.0f;
    }
    shape->bbox = _bbox(shape->hasFill ? shape->fill.region : MeshRegion(), shape->hasStroke ? shape->stroke.region : MeshRegion());
    return shape;
}


RenderData MeshRenderer::prepare(RenderSurface* image, RenderData data, const Matrix& transform, const Array<RenderData>& clips, uint8_t opacity, TVG_UNUSED FilterMethod filter, RenderUpdateFlag flags)
{
    auto picture = data ? static_cast<MeshPicture*>(data) : new MeshPicture;
    picture->opacity = opacity;
    picture->image.built = false;
    picture->hasImage = false;
    if (!image || image->w == 0 || image->h == 0) return picture;

    auto& paint = picture->image.paint;
    picture->inexact = false;
    if ((flags & RenderUpdateFlag::Image) || !paint.texture) {
        auto texture = _texture(image);
        if (!texture) {
            picture->inexact = true;   // a picture it can't read (8-bit grey): left out
            return picture;
        }
        paint.texture = texture;
    }
    paint.type = MeshPaint::Type::Texture;
    paint.alpha = opacity / 255.0f;

    Matrix inv;
    if (!inverse(&transform, &inv)) return picture;
    auto w = float(image->w), h = float(image->h);
    paint.u[0] = inv.e11 / w; paint.u[1] = inv.e12 / w; paint.u[2] = inv.e13 / w;
    paint.v[0] = inv.e21 / h; paint.v[1] = inv.e22 / h; paint.v[2] = inv.e23 / h;

    MeshRegion quad;
    quad.pts = {_clamp(Point{0.0f, 0.0f} * transform), _clamp(Point{w, 0.0f} * transform), _clamp(Point{w, h} * transform), _clamp(Point{0.0f, h} * transform)};
    quad.counts = {4};
    Tess tess;
    _add(tess, quad);
    _boundary(tess, TESS_WINDING_NONZERO, picture->image.region);
    _cut(picture->image.region, clips, vport);
    picture->hasImage = !picture->image.region.empty();
    picture->bbox = _bbox(picture->image.region, MeshRegion());
    return picture;
}


bool MeshRenderer::postUpdate()
{
    return true;
}


bool MeshRenderer::preRender()
{
    entries.clear();
    batches.clear();
    images.clear();
    complete = true;
    blendMethod = BlendMethod::Normal;
    return true;
}


void MeshRenderer::push(const MeshItem& item)
{
    if (blendMethod != BlendMethod::Normal && blendMethod != BlendMethod::Composition) complete = false;
    Entry entry;
    entry.item = &item;
    entries.push_back(entry);
}


bool MeshRenderer::renderShape(RenderData data)
{
    auto shape = static_cast<MeshShape*>(data);
    if (!shape) return false;
    if (shape->strokeFirst && shape->hasStroke) push(shape->stroke);
    if (shape->hasFill) push(shape->fill);
    if (!shape->strokeFirst && shape->hasStroke) push(shape->stroke);
    return true;
}


bool MeshRenderer::renderImage(RenderData data)
{
    auto picture = static_cast<MeshPicture*>(data);
    if (!picture) return false;
    if (picture->inexact) complete = false;
    if (picture->hasImage) push(picture->image);
    return true;
}


bool MeshRenderer::postRender()
{
    for (auto& entry : entries) {
        auto& item = entry.own ? *entry.own : const_cast<MeshItem&>(*entry.item);
        if (!item.built) item.build();
        if (item.indices.empty()) continue;
        auto image = -1;
        if (item.paint.type == MeshPaint::Type::Texture && item.paint.texture) {
            auto& texture = item.paint.texture;
            for (size_t i = 0; i < images.size(); ++i) {
                if (images[i].key == texture->key) {
                    image = int32_t(i);
                    break;
                }
            }
            if (image < 0) {
                image = int32_t(images.size());
                images.push_back({texture->key, texture->pixels.data(), texture->w, texture->h});
            }
        }
        batches.push_back({item.vertices.data(), uint32_t(item.vertices.size()), item.indices.data(), uint32_t(item.indices.size()), image});
    }
    return true;
}


void MeshRenderer::dispose(RenderData data)
{
    delete static_cast<MeshData*>(data);
}


RenderRegion MeshRenderer::region(RenderData data)
{
    return data ? static_cast<MeshData*>(data)->bbox : RenderRegion{};
}


bool MeshRenderer::bounds(TVG_UNUSED RenderData data, TVG_UNUSED Point* pt4, TVG_UNUSED const Matrix& m)
{
    return false;
}


bool MeshRenderer::blend(BlendMethod method)
{
    blendMethod = method;
    return true;
}


ColorSpace MeshRenderer::colorSpace()
{
    return ColorSpace::ABGR8888;
}


const RenderSurface* MeshRenderer::mainSurface()
{
    return &surface;
}


bool MeshRenderer::clear()
{
    return true;
}


bool MeshRenderer::sync()
{
    return true;
}


bool MeshRenderer::intersectsShape(RenderData data, const RenderRegion& region)
{
    return data && region.intersected(static_cast<MeshData*>(data)->bbox);
}


bool MeshRenderer::intersectsImage(RenderData data, const RenderRegion& region)
{
    return data && region.intersected(static_cast<MeshData*>(data)->bbox);
}


/************************************************************************/
/* Compositions: a group's opacity, masks                               */
/************************************************************************/

MeshItem& MeshRenderer::Entry::change()
{
    if (!own) {
        own = std::make_shared<MeshItem>();
        own->region = item->region;
        own->paint = item->paint;
    }
    own->built = false;
    return *own;
}


RenderCompositor* MeshRenderer::target(TVG_UNUSED const RenderRegion& region, TVG_UNUSED ColorSpace cs, CompositionFlag flags)
{
    auto cmp = new MeshCompositor;
    cmp->flags = flags;
    cmp->start = entries.size();
    return cmp;
}


bool MeshRenderer::beginComposite(RenderCompositor* cmp, MaskMethod method, uint8_t opacity)
{
    auto c = static_cast<MeshCompositor*>(cmp);
    if (!c) return false;
    if (method == MaskMethod::None) {
        c->start = entries.size();
        c->groupOpacity = opacity;
    } else {
        c->content = entries.size();
        c->maskMethod = method;
        c->maskOpacity = opacity;
    }
    return true;
}


bool MeshRenderer::endComposite(RenderCompositor* cmp)
{
    auto c = static_cast<MeshCompositor*>(cmp);
    if (!c) return false;
    if (c->maskMethod != MaskMethod::None) mask(c);
    else group(c);
    delete c;
    return true;
}


// Whether two draws' areas overlap at all
static bool _overlap(const MeshRegion& a, const MeshRegion& b)
{
    if (!_overlap(a.bounds(), b.bounds())) return false;
    auto both = a;
    _intersect(both, b);
    return !both.empty();
}


static constexpr size_t GROUP_PIECES_MAX = 64;   // a translucent group is split into no more pieces than this


// Translucent draws of one colour each, as the picture they make together: pieces that don't overlap, each with the
// colour of what is over what there (the upper blended over the lower, premultiplied). False past GROUP_PIECES_MAX.
static bool _flatten(const std::vector<const MeshItem*>& items, std::vector<std::shared_ptr<MeshItem>>& out)
{
    struct Piece { MeshRegion region; float c[4]; };   // premultiplied
    std::vector<Piece> pieces;
    MeshRegion covered;
    for (auto item : items) {
        auto a = item->paint.color[3] * item->paint.alpha;
        const float src[4] = {item->paint.color[0] * a, item->paint.color[1] * a, item->paint.color[2] * a, a};
        std::vector<Piece> next;
        for (auto& p : pieces) {
            Piece over;
            for (int k = 0; k < 4; ++k) over.c[k] = src[k] + p.c[k] * (1.0f - a);
            over.region = p.region;
            _intersect(over.region, item->region);
            _subtract(p.region, item->region);
            if (!p.region.empty()) next.push_back(std::move(p));
            if (!over.region.empty()) next.push_back(std::move(over));
        }
        Piece fresh;
        fresh.region = item->region;
        _subtract(fresh.region, covered);
        if (!fresh.region.empty()) {
            for (int k = 0; k < 4; ++k) fresh.c[k] = src[k];
            next.push_back(std::move(fresh));
        }
        _unite(covered, item->region);
        pieces.swap(next);
        if (pieces.size() > GROUP_PIECES_MAX) return false;
    }
    for (auto& p : pieces) {
        auto item = std::make_shared<MeshItem>();
        item->region = std::move(p.region);
        auto a = p.c[3];
        for (int k = 0; k < 3; ++k) item->paint.color[k] = a > 0.0f ? p.c[k] / a : 0.0f;
        item->paint.color[3] = a;
        out.push_back(item);
    }
    return true;
}


// A group drawn at an opacity: as one picture faded, not each shape faded over the ones under it. Where every shape
// is opaque that is each shape less what is drawn over it, faded; where every one is of one colour, the pieces they
// make together (_flatten). Translucent gradients or pictures overlapping can't be done: faded each, as near as can be.
void MeshRenderer::group(MeshCompositor* c)
{
    auto end = entries.size();
    if (c->groupOpacity >= 255 || c->start >= end) return;
    auto o = c->groupOpacity / 255.0f;

    if (end - c->start > 1) {
        auto opaque = true, solid = true;
        for (auto i = c->start; i < end; ++i) {
            auto& paint = entries[i].get().paint;
            if (!paint.opaque()) opaque = false;
            if (!paint.solid()) solid = false;
        }
        if (opaque) {
            MeshRegion above;
            for (auto i = end; i-- > c->start;) {
                auto area = entries[i].get().region;
                if (!above.empty()) _subtract(entries[i].change().region, above);
                _unite(above, area);
            }
        } else {
            std::vector<std::shared_ptr<MeshItem>> pieces;
            std::vector<const MeshItem*> items;
            for (auto i = c->start; i < end; ++i) items.push_back(&entries[i].get());
            if (solid && _flatten(items, pieces)) {
                entries.erase(entries.begin() + c->start, entries.end());
                for (auto& piece : pieces) {
                    Entry entry;
                    entry.own = piece;
                    entries.push_back(entry);
                }
                end = entries.size();
            } else {
                for (auto i = c->start; i < end && complete; ++i) {
                    for (auto j = i + 1; j < end; ++j) {
                        if (_overlap(entries[i].get().region, entries[j].get().region)) {
                            complete = false;
                            break;
                        }
                    }
                }
            }
        }
    }
    for (auto i = c->start; i < end; ++i) entries[i].change().paint.alpha *= o;
    entries.erase(std::remove_if(entries.begin() + c->start, entries.end(), [](const Entry& e) { return e.get().region.empty(); }), entries.end());
}


// A mask: its draws (from start to content) make an area, by which the content's draws are cut, then the mask's are
// dropped - as long as the mask's draws are of one colour each, opaque (or one draw of any one alpha)
void MeshRenderer::mask(MeshCompositor* c)
{
    auto ms = c->start, cs = c->content, end = entries.size();
    if (cs == SIZE_MAX || cs < ms || cs > end) {
        complete = false;
        return;
    }
    auto method = c->maskMethod;
    auto m = c->maskOpacity / 255.0f;
    auto luma = (method == MaskMethod::Luma || method == MaskMethod::InvLuma);

    MeshRegion area;
    auto ok = true;
    for (auto i = ms; i < cs; ++i) {
        auto& item = entries[i].get();
        if (!item.paint.solid()) {
            ok = false;
            break;
        }
        auto a = item.paint.color[3] * item.paint.alpha;
        auto value = a;
        if (luma) value *= 0.2125f * item.paint.color[0] + 0.7154f * item.paint.color[1] + 0.0721f * item.paint.color[2];
        if (value >= 0.999f) _unite(area, item.region);
        else if (luma && value <= 0.001f && a >= 0.999f) _subtract(area, item.region);   // opaque black hides what is under it
        else if (cs - ms == 1) {
            m *= value;
            area = item.region;
        } else {
            ok = false;
            break;
        }
    }

    if (!ok || method == MaskMethod::Lighten || method == MaskMethod::Darken) {
        // not a mask of one colour: the content as it is, as near as can be
        complete = false;
        entries.erase(entries.begin() + ms, entries.begin() + cs);
        return;
    }

    if (method == MaskMethod::Add) {
        for (auto i = ms; i < cs; ++i) entries[i].change().paint.alpha *= m;
        return;
    }

    if (method == MaskMethod::Difference) {
        MeshRegion content;
        for (auto i = cs; i < end; ++i) _unite(content, entries[i].get().region);
        for (auto i = ms; i < cs; ++i) {
            auto& item = entries[i].change();
            _subtract(item.region, content);
            item.paint.alpha *= m;
        }
        for (auto i = cs; i < end; ++i) _subtract(entries[i].change().region, area);
        entries.erase(std::remove_if(entries.begin() + ms, entries.end(), [](const Entry& e) { return e.get().region.empty(); }), entries.end());
        return;
    }

    entries.erase(entries.begin() + ms, entries.begin() + cs);
    end = entries.size();

    auto inverse = (method == MaskMethod::InvAlpha || method == MaskMethod::Subtract || method == MaskMethod::InvLuma);
    if (!inverse) {
        for (auto i = ms; i < end; ++i) {
            auto& item = entries[i].change();
            _intersect(item.region, area);
            item.paint.alpha *= m;
        }
    } else if (m >= 0.999f) {
        for (auto i = ms; i < end; ++i) _subtract(entries[i].change().region, area);
    } else {
        // the mask only part hides: inside it at 1 - m, outside as it was
        std::vector<Entry> split;
        for (auto i = ms; i < end; ++i) {
            auto& src = entries[i].get();
            Entry outside, inside;
            outside.own = std::make_shared<MeshItem>();
            outside.own->region = src.region;
            outside.own->paint = src.paint;
            _subtract(outside.own->region, area);
            inside.own = std::make_shared<MeshItem>();
            inside.own->region = src.region;
            inside.own->paint = src.paint;
            _intersect(inside.own->region, area);
            inside.own->paint.alpha *= (1.0f - m);
            split.push_back(outside);
            split.push_back(inside);
        }
        entries.erase(entries.begin() + ms, entries.end());
        entries.insert(entries.end(), split.begin(), split.end());
    }
    entries.erase(std::remove_if(entries.begin() + ms, entries.end(), [](const Entry& e) { return e.get().region.empty(); }), entries.end());
}


/************************************************************************/
/* Effects, partial drawing: none                                       */
/************************************************************************/

void MeshRenderer::prepare(RenderEffect* effect, TVG_UNUSED const Matrix& transform)
{
    if (effect) effect->valid = true;   // so that it is offered to render() and seen there
}


bool MeshRenderer::region(TVG_UNUSED RenderEffect* effect)
{
    return false;
}


bool MeshRenderer::render(TVG_UNUSED RenderCompositor* cmp, TVG_UNUSED const RenderEffect* effect, TVG_UNUSED bool direct)
{
    complete = false;
    return true;
}


void MeshRenderer::dispose(TVG_UNUSED RenderEffect* effect)
{
}


void MeshRenderer::damage(TVG_UNUSED RenderData rd, TVG_UNUSED const RenderRegion& region)
{
}


bool MeshRenderer::partial(TVG_UNUSED bool disable)
{
    return false;
}


uint32_t MeshRenderer::dirtyRegions() const
{
    return 1;
}


Result MeshRenderer::dirtyRegions(Region* regions, TVG_UNUSED uint32_t cnt) const
{
    if (!regions) return Result::InvalidArguments;
    *regions = {0, 0, int32_t(surface.w), int32_t(surface.h)};
    return Result::Success;
}

}
