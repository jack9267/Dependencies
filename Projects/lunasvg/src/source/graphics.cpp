#include "graphics.h"

#include <thorvg.h> // Dependencies: Canvas::createScene

#include <cstdlib>
#include <cstring>
#include "lunasvg.h"

#include <cfloat>
#include <cmath>

namespace lunasvg {

const Color Color::Black(0xFF000000);
const Color Color::White(0xFFFFFFFF);
const Color Color::Transparent(0x00000000);

const Rect Rect::Empty(0, 0, 0, 0);
const Rect Rect::Invalid(0, 0, -1, -1);
const Rect Rect::Infinite(-FLT_MAX / 2.f, -FLT_MAX / 2.f, FLT_MAX, FLT_MAX);

Rect::Rect(const Box& box)
    : x(box.x), y(box.y), w(box.w), h(box.h)
{
}

const Transform Transform::Identity(1, 0, 0, 1, 0, 0);

Transform::Transform()
{
    plutovg_matrix_init_identity(&m_matrix);
}

Transform::Transform(float a, float b, float c, float d, float e, float f)
{
    plutovg_matrix_init(&m_matrix, a, b, c, d, e, f);
}

Transform::Transform(const Matrix& matrix)
    : Transform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.e, matrix.f)
{
}

Transform Transform::operator*(const Transform& transform) const
{
    plutovg_matrix_t result;
    plutovg_matrix_multiply(&result, &transform.m_matrix, &m_matrix);
    return result;
}

Transform& Transform::operator*=(const Transform& transform)
{
    return (*this = *this * transform);
}

Transform& Transform::multiply(const Transform& transform)
{
    return (*this *= transform);
}

Transform& Transform::translate(float tx, float ty)
{
    return multiply(translated(tx, ty));
}

Transform& Transform::scale(float sx, float sy)
{
    return multiply(scaled(sx, sy));
}

Transform& Transform::rotate(float angle, float cx, float cy)
{
    return multiply(rotated(angle, cx, cy));
}

Transform& Transform::shear(float shx, float shy)
{
    return multiply(sheared(shx, shy));
}

Transform& Transform::postMultiply(const Transform& transform)
{
    return (*this = transform * *this);
}

Transform& Transform::postTranslate(float tx, float ty)
{
    return postMultiply(translated(tx, ty));
}

Transform& Transform::postScale(float sx, float sy)
{
    return postMultiply(scaled(sx, sy));
}

Transform& Transform::postRotate(float angle, float cx, float cy)
{
    return postMultiply(rotated(angle, cx, cy));
}

Transform& Transform::postShear(float shx, float shy)
{
    return postMultiply(sheared(shx, shy));
}

Transform Transform::inverse() const
{
    plutovg_matrix_t inverse;
    plutovg_matrix_invert(&m_matrix, &inverse);
    return inverse;
}

Transform& Transform::invert()
{
    plutovg_matrix_invert(&m_matrix, &m_matrix);
    return *this;
}

void Transform::reset()
{
    plutovg_matrix_init_identity(&m_matrix);
}

Point Transform::mapPoint(float x, float y) const
{
    plutovg_matrix_map(&m_matrix, x, y, &x, &y);
    return Point(x, y);
}

Point Transform::mapPoint(const Point& point) const
{
    return mapPoint(point.x, point.y);
}

Rect Transform::mapRect(const Rect& rect) const
{
    if(!rect.isValid()) {
        return Rect::Invalid;
    }

    plutovg_rect_t result = {rect.x, rect.y, rect.w, rect.h};
    plutovg_matrix_map_rect(&m_matrix, &result, &result);
    return result;
}

float Transform::xScale() const
{
    return std::sqrt(m_matrix.a * m_matrix.a + m_matrix.b * m_matrix.b);
}

float Transform::yScale() const
{
    return std::sqrt(m_matrix.c * m_matrix.c + m_matrix.d * m_matrix.d);
}

bool Transform::parse(const char* data, size_t length)
{
    return plutovg_matrix_parse(&m_matrix, data, length);
}

Transform Transform::rotated(float angle, float cx, float cy)
{
    plutovg_matrix_t matrix;
    if(cx == 0.f && cy == 0.f) {
        plutovg_matrix_init_rotate(&matrix, PLUTOVG_DEG2RAD(angle));
    } else {
        plutovg_matrix_init_translate(&matrix, cx, cy);
        plutovg_matrix_rotate(&matrix, PLUTOVG_DEG2RAD(angle));
        plutovg_matrix_translate(&matrix, -cx, -cy);
    }

    return matrix;
}

Transform Transform::scaled(float sx, float sy)
{
    plutovg_matrix_t matrix;
    plutovg_matrix_init_scale(&matrix, sx, sy);
    return matrix;
}

Transform Transform::sheared(float shx, float shy)
{
    plutovg_matrix_t matrix;
    plutovg_matrix_init_shear(&matrix, PLUTOVG_DEG2RAD(shx), PLUTOVG_DEG2RAD(shy));
    return matrix;
}

Transform Transform::translated(float tx, float ty)
{
    plutovg_matrix_t matrix;
    plutovg_matrix_init_translate(&matrix, tx, ty);
    return matrix;
}

Path::Path(const Path& path)
    : m_data(plutovg_path_reference(path.data()))
{
}

Path::Path(Path&& path)
    : m_data(path.release())
{
}

Path::~Path()
{
    plutovg_path_destroy(m_data);
}

Path& Path::operator=(const Path& path)
{
    Path(path).swap(*this);
    return *this;
}

Path& Path::operator=(Path&& path)
{
    Path(std::move(path)).swap(*this);
    return *this;
}

void Path::moveTo(float x, float y)
{
    plutovg_path_move_to(ensure(), x, y);
}

void Path::lineTo(float x, float y)
{
    plutovg_path_line_to(ensure(), x, y);
}

void Path::quadTo(float x1, float y1, float x2, float y2)
{
    plutovg_path_quad_to(ensure(), x1, y1, x2, y2);
}

void Path::cubicTo(float x1, float y1, float x2, float y2, float x3, float y3)
{
    plutovg_path_cubic_to(ensure(), x1, y1, x2, y2, x3, y3);
}

void Path::arcTo(float rx, float ry, float xAxisRotation, bool largeArcFlag, bool sweepFlag, float x, float y)
{
    plutovg_path_arc_to(ensure(), rx, ry, PLUTOVG_DEG2RAD(xAxisRotation), largeArcFlag, sweepFlag, x, y);
}

void Path::close()
{
    plutovg_path_close(ensure());
}

void Path::addEllipse(float cx, float cy, float rx, float ry)
{
    plutovg_path_add_ellipse(ensure(), cx, cy, rx, ry);
}

void Path::addRoundRect(float x, float y, float w, float h, float rx, float ry)
{
    plutovg_path_add_round_rect(ensure(), x, y, w, h, rx, ry);
}

void Path::addRect(float x, float y, float w, float h)
{
    plutovg_path_add_rect(ensure(), x, y, w, h);
}

void Path::addEllipse(const Point& center, const Size& radii)
{
    addEllipse(center.x, center.y, radii.w, radii.h);
}

void Path::addRoundRect(const Rect& rect, const Size& radii)
{
    addRoundRect(rect.x, rect.y, rect.w, rect.h, radii.w, radii.h);
}

void Path::addRect(const Rect& rect)
{
    addRect(rect.x, rect.y, rect.w, rect.h);
}

void Path::reset()
{
    if(m_data == nullptr)
        return;
    if(isUnique()) {
        plutovg_path_reset(m_data);
    } else {
        plutovg_path_destroy(m_data);
        m_data = nullptr;
    }
}

Rect Path::boundingRect() const
{
    if(m_data == nullptr)
        return Rect::Empty;
    plutovg_rect_t extents;
    plutovg_path_extents(m_data, &extents, false);
    return extents;
}

bool Path::isEmpty() const
{
    if(m_data)
        return plutovg_path_get_elements(m_data, nullptr) == 0;
    return true;
}

bool Path::isUnique() const
{
    return plutovg_path_get_reference_count(m_data) == 1;
}

bool Path::parse(const char* data, size_t length)
{
    plutovg_path_reset(ensure());
    return plutovg_path_parse(m_data, data, length);
}

plutovg_path_t* Path::ensure()
{
    if(isNull()) {
        m_data = plutovg_path_create();
    } else if(!isUnique()) {
        plutovg_path_destroy(m_data);
        m_data = plutovg_path_clone(m_data);
    }

    return m_data;
}

PathIterator::PathIterator(const Path& path)
    : m_size(plutovg_path_get_elements(path.data(), &m_elements))
    , m_index(0)
{
}

PathCommand PathIterator::currentSegment(std::array<Point, 3>& points) const
{
    auto command = m_elements[m_index].header.command;
    switch(command) {
    case PLUTOVG_PATH_COMMAND_MOVE_TO:
        points[0] = m_elements[m_index + 1].point;
        break;
    case PLUTOVG_PATH_COMMAND_LINE_TO:
        points[0] = m_elements[m_index + 1].point;
        break;
    case PLUTOVG_PATH_COMMAND_CUBIC_TO:
        points[0] = m_elements[m_index + 1].point;
        points[1] = m_elements[m_index + 2].point;
        points[2] = m_elements[m_index + 3].point;
        break;
    case PLUTOVG_PATH_COMMAND_CLOSE:
        points[0] = m_elements[m_index + 1].point;
        break;
    }

    return PathCommand(command);
}

void PathIterator::next()
{
    m_index += m_elements[m_index].header.length;
}

FontFace::FontFace(plutovg_font_face_t* face)
    : m_face(plutovg_font_face_reference(face))
{
}

FontFace::FontFace(const void* data, size_t length, plutovg_destroy_func_t destroy_func, void* closure)
    : m_face(plutovg_font_face_load_from_data(data, length, 0, destroy_func, closure))
{
}

FontFace::FontFace(const char* filename)
    : m_face(plutovg_font_face_load_from_file(filename, 0))
{
}

FontFace::FontFace(const FontFace& face)
    : m_face(plutovg_font_face_reference(face.get()))
{
}

FontFace::FontFace(FontFace&& face)
    : m_face(face.release())
{
}

FontFace::~FontFace()
{
    plutovg_font_face_destroy(m_face);
}

FontFace& FontFace::operator=(const FontFace& face)
{
    FontFace(face).swap(*this);
    return *this;
}

FontFace& FontFace::operator=(FontFace&& face)
{
    FontFace(std::move(face)).swap(*this);
    return *this;
}

void FontFace::swap(FontFace& face)
{
    std::swap(m_face, face.m_face);
}

plutovg_font_face_t* FontFace::release()
{
    return std::exchange(m_face, nullptr);
}

bool FontFaceCache::addFontFace(const std::string& family, bool bold, bool italic, const FontFace& face)
{
    if(!face.isNull())
        plutovg_font_face_cache_add(m_cache, family.data(), bold, italic, face.get());
    return !face.isNull();
}

FontFace FontFaceCache::getFontFace(const std::string& family, bool bold, bool italic) const
{
    if(auto face = plutovg_font_face_cache_get(m_cache, family.data(), bold, italic)) {
        return FontFace(face);
    }

    static const struct {
        const char* generic;
        const char* fallback;
    } generic_fallbacks[] = {
#if defined(__linux__)
        {"sans-serif", "DejaVu Sans"},
        {"serif", "DejaVu Serif"},
        {"monospace", "DejaVu Sans Mono"},
#else
        {"sans-serif", "Arial"},
        {"serif", "Times New Roman"},
        {"monospace", "Courier New"},
#endif
        {"cursive", "Comic Sans MS"},
        {"fantasy", "Impact"}
    };

    for(auto value : generic_fallbacks) {
        if(value.generic == family || family.empty()) {
            return FontFace(plutovg_font_face_cache_get(m_cache, value.fallback, bold, italic));
        }
    }

    return FontFace();
}

FontFaceCache::FontFaceCache()
    : m_cache(plutovg_font_face_cache_create())
{
#ifndef LUNASVG_DISABLE_LOAD_SYSTEM_FONTS
    plutovg_font_face_cache_load_sys(m_cache);
#endif
}

FontFaceCache* fontFaceCache()
{
    static FontFaceCache cache;
    return &cache;
}

Font::Font(const FontFace& face, float size)
    : m_face(face), m_size(size)
{
    if(m_size > 0.f && !m_face.isNull()) {
        plutovg_font_face_get_metrics(m_face.get(), m_size, &m_ascent, &m_descent, &m_lineGap, nullptr);
    }
}

float Font::xHeight() const
{
    plutovg_rect_t extents = {0};
    if(m_size > 0.f && !m_face.isNull())
        plutovg_font_face_get_glyph_metrics(m_face.get(), m_size, 'x', nullptr, nullptr, &extents);
    return extents.h;
}

float Font::measureText(const std::u32string_view& text) const
{
    if(m_size > 0.f && !m_face.isNull())
        return plutovg_font_face_text_extents(m_face.get(), m_size, text.data(), text.length(), PLUTOVG_TEXT_ENCODING_UTF32, nullptr);
    return 0;
}

std::shared_ptr<Canvas> Canvas::create(const Bitmap& bitmap)
{
    return std::shared_ptr<Canvas>(new Canvas(bitmap));
}

std::shared_ptr<Canvas> Canvas::create(float x, float y, float width, float height)
{
    constexpr int kMaxSize = 1 << 15;
    if(width <= 0 || height <= 0 || width >= kMaxSize || height >= kMaxSize)
        return std::shared_ptr<Canvas>(new Canvas(0, 0, 1, 1));
    auto l = static_cast<int>(std::floor(x));
    auto t = static_cast<int>(std::floor(y));
    auto r = static_cast<int>(std::ceil(x + width));
    auto b = static_cast<int>(std::ceil(y + height));
    return std::shared_ptr<Canvas>(new Canvas(l, t, r - l, b - t));
}

std::shared_ptr<Canvas> Canvas::create(const Rect& extents)
{
    return create(extents.x, extents.y, extents.w, extents.h);
}

// Dependencies: drawing into a ThorVG scene (Canvas::createScene). Every call builds what plutovg would have filled:
// a path is a tvg::Shape with its paint and transform; a clip is a scene with that clipper, which what is drawn next
// goes into until restore(); a layer (group opacity, a clip mask, a mask) is the layer canvas's scene, added with its
// opacity or set as a mask (Alpha, or Luma after convertToLuminanceMask); a pattern is its tile's scene repeated over
// the shape, which masks it; an image is a picture clipped to its rectangle. Coordinates are the renderer's device
// space, which is the scene's: no layer offsets (m_translation is plutovg's).

struct Canvas::ScenePaint {
    enum class Type { Color, Linear, Radial, Texture };
    Type type = Type::Color;
    float r = 0.f, g = 0.f, b = 0.f, a = 1.f;
    float x1 = 0.f, y1 = 0.f, x2 = 0.f, y2 = 0.f;
    float cx = 0.f, cy = 0.f, radius = 0.f, fx = 0.f, fy = 0.f;
    SpreadMethod spread = SpreadMethod::Pad;
    GradientStops stops;
    plutovg_matrix_t matrix = { 1, 0, 0, 1, 0, 0 };
    tvg::Paint* tile = nullptr; // the texture's scene, one reference ours
    TextureType textureType = TextureType::Plain;
    float opacity = 1.f;
    int tileWidth = 0;
    int tileHeight = 0;

    ~ScenePaint() { setTile(nullptr); }
    void setTile(tvg::Paint* paint)
    {
        if(paint)
            paint->ref();
        if(tile)
            tile->unref();
        tile = paint;
    }
};

// a then b: the point mapped by b first, then by a
static plutovg_matrix_t sceneMultiply(const plutovg_matrix_t& a, const plutovg_matrix_t& b)
{
    return { a.a * b.a + a.c * b.b, a.b * b.a + a.d * b.b, a.a * b.c + a.c * b.d, a.b * b.c + a.d * b.d,
             a.a * b.e + a.c * b.f + a.e, a.b * b.e + a.d * b.f + a.f };
}

static tvg::Matrix sceneMatrix(const plutovg_matrix_t& m)
{
    return { m.a, m.c, m.e, m.b, m.d, m.f, 0.f, 0.f, 1.f };
}

static uint8_t sceneByte(float value)
{
    return static_cast<uint8_t>(std::clamp(value, 0.f, 1.f) * 255.f + 0.5f);
}

static void sceneTraverse(void* closure, plutovg_path_command_t command, const plutovg_point_t* points, int npoints)
{
    auto shape = static_cast<tvg::Shape*>(closure);
    switch(command) {
    case PLUTOVG_PATH_COMMAND_MOVE_TO:
        shape->moveTo(points[0].x, points[0].y);
        break;
    case PLUTOVG_PATH_COMMAND_LINE_TO:
        shape->lineTo(points[0].x, points[0].y);
        break;
    case PLUTOVG_PATH_COMMAND_CUBIC_TO:
        shape->cubicTo(points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y);
        break;
    case PLUTOVG_PATH_COMMAND_CLOSE:
        shape->close();
        break;
    }
}

static tvg::Shape* sceneShape(const plutovg_path_t* path, FillRule fillRule, const plutovg_matrix_t& matrix)
{
    auto shape = tvg::Shape::gen();
    plutovg_path_traverse(path, sceneTraverse, shape);
    shape->fillRule(fillRule == FillRule::EvenOdd ? tvg::FillRule::EvenOdd : tvg::FillRule::NonZero);
    shape->transform(sceneMatrix(matrix));
    return shape;
}

static tvg::FillSpread sceneSpread(SpreadMethod spread)
{
    switch(spread) {
    case SpreadMethod::Reflect:
        return tvg::FillSpread::Reflect;
    case SpreadMethod::Repeat:
        return tvg::FillSpread::Repeat;
    default:
        return tvg::FillSpread::Pad;
    }
}

std::shared_ptr<Canvas> Canvas::createScene(float width, float height)
{
    auto canvas = std::shared_ptr<Canvas>(new Canvas(0, 0, static_cast<int>(std::ceil(width)), static_cast<int>(std::ceil(height)), true));
    auto clipper = tvg::Shape::gen();
    clipper->appendRect(0, 0, static_cast<float>(canvas->m_width), static_cast<float>(canvas->m_height));
    canvas->m_scene->clip(clipper);
    return canvas;
}

std::shared_ptr<Canvas> Canvas::createLike(const Canvas& like, float x, float y, float width, float height)
{
    if(like.m_scene == nullptr)
        return create(x, y, width, height);
    constexpr int kMaxSize = 1 << 15;
    if(width <= 0 || height <= 0 || width >= kMaxSize || height >= kMaxSize)
        return std::shared_ptr<Canvas>(new Canvas(0, 0, 1, 1, true));
    auto l = static_cast<int>(std::floor(x));
    auto t = static_cast<int>(std::floor(y));
    auto r = static_cast<int>(std::ceil(x + width));
    auto b = static_cast<int>(std::ceil(y + height));
    return std::shared_ptr<Canvas>(new Canvas(l, t, r - l, b - t, true));
}

std::shared_ptr<Canvas> Canvas::createLike(const Canvas& like, const Rect& extents)
{
    return createLike(like, extents.x, extents.y, extents.w, extents.h);
}

tvg::Scene* Canvas::releaseScene()
{
    auto scene = m_scene;
    m_scene = m_target = nullptr;
    m_targets.clear();
    if(scene)
        scene->unref(false);
    return scene;
}

void Canvas::setColor(const Color& color)
{
    setColor(color.redF(), color.greenF(), color.blueF(), color.alphaF());
}

void Canvas::setColor(float r, float g, float b, float a)
{
    if(m_scene) {
        m_paint->type = ScenePaint::Type::Color;
        m_paint->r = r;
        m_paint->g = g;
        m_paint->b = b;
        m_paint->a = a;
        return;
    }

    plutovg_canvas_set_rgba(m_canvas, r, g, b, a);
}

void Canvas::setLinearGradient(float x1, float y1, float x2, float y2, SpreadMethod spread, const GradientStops& stops, const Transform& transform)
{
    if(m_scene) {
        m_paint->type = ScenePaint::Type::Linear;
        m_paint->x1 = x1;
        m_paint->y1 = y1;
        m_paint->x2 = x2;
        m_paint->y2 = y2;
        m_paint->spread = spread;
        m_paint->stops = stops;
        m_paint->matrix = transform.matrix();
        return;
    }

    plutovg_canvas_set_linear_gradient(m_canvas, x1, y1, x2, y2, static_cast<plutovg_spread_method_t>(spread), stops.data(), stops.size(), &transform.matrix());
}

void Canvas::setRadialGradient(float cx, float cy, float r, float fx, float fy, SpreadMethod spread, const GradientStops& stops, const Transform& transform)
{
    if(m_scene) {
        m_paint->type = ScenePaint::Type::Radial;
        m_paint->cx = cx;
        m_paint->cy = cy;
        m_paint->radius = r;
        m_paint->fx = fx;
        m_paint->fy = fy;
        m_paint->spread = spread;
        m_paint->stops = stops;
        m_paint->matrix = transform.matrix();
        return;
    }

    plutovg_canvas_set_radial_gradient(m_canvas, cx, cy, r, fx, fy, 0.f, static_cast<plutovg_spread_method_t>(spread), stops.data(), stops.size(), &transform.matrix());
}

void Canvas::setTexture(const Canvas& source, TextureType type, float opacity, const Transform& transform)
{
    if(m_scene) {
        m_paint->type = ScenePaint::Type::Texture;
        m_paint->setTile(source.m_scene ? source.m_scene->duplicate() : nullptr);
        m_paint->textureType = type;
        m_paint->opacity = opacity;
        m_paint->matrix = transform.matrix();
        m_paint->tileWidth = source.width();
        m_paint->tileHeight = source.height();
        return;
    }

    plutovg_canvas_set_texture(m_canvas, source.surface(), static_cast<plutovg_texture_type_t>(type), opacity, &transform.matrix());
}

// The shape (its path and transform set) given the paint and added where drawing goes. A texture is its tile's scene
// repeated over the path's extents (padded by strokePad for a stroke), masked by the shape painted opaque.
void Canvas::addShape(tvg::Shape* shape, const plutovg_path_t* path, float strokePad, const Transform& transform, bool stroke)
{
    const auto& paint = *m_paint;
    if(paint.type == ScenePaint::Type::Color) {
        auto r = sceneByte(paint.r), g = sceneByte(paint.g), b = sceneByte(paint.b), a = sceneByte(paint.a);
        stroke ? shape->strokeFill(r, g, b, a) : shape->fill(r, g, b, a);
        m_target->add(shape);
        return;
    }

    if(paint.type == ScenePaint::Type::Linear || paint.type == ScenePaint::Type::Radial) {
        tvg::Fill* fill = nullptr;
        if(paint.type == ScenePaint::Type::Linear) {
            auto linear = tvg::LinearGradient::gen();
            linear->linear(paint.x1, paint.y1, paint.x2, paint.y2);
            fill = linear;
        } else {
            auto radial = tvg::RadialGradient::gen();
            radial->radial(paint.cx, paint.cy, paint.radius, paint.fx, paint.fy, 0.f);
            fill = radial;
        }

        std::vector<tvg::Fill::ColorStop> stops;
        stops.reserve(paint.stops.size());
        for(const auto& stop : paint.stops)
            stops.push_back({ stop.offset, sceneByte(stop.color.r), sceneByte(stop.color.g), sceneByte(stop.color.b), sceneByte(stop.color.a) });
        fill->colorStops(stops.data(), static_cast<uint32_t>(stops.size()));
        fill->spread(sceneSpread(paint.spread));
        fill->transform(sceneMatrix(paint.matrix));
        stroke ? shape->strokeFill(fill) : shape->fill(fill);
        m_target->add(shape);
        return;
    }

    if(paint.tile == nullptr || paint.tileWidth <= 0 || paint.tileHeight <= 0) {
        tvg::Paint::rel(shape);
        return;
    }

    stroke ? shape->strokeFill(255, 255, 255, 255) : shape->fill(255, 255, 255, 255);
    auto tileMatrix = sceneMultiply(transform.matrix(), paint.matrix);
    int firstColumn = 0, lastColumn = 0, firstRow = 0, lastRow = 0;
    if(paint.textureType == TextureType::Tiled) {
        // which tiles the path covers: its extents in the tile's space
        plutovg_rect_t extents;
        plutovg_path_extents(path, &extents, false);
        extents.x -= strokePad;
        extents.y -= strokePad;
        extents.w += strokePad * 2.f;
        extents.h += strokePad * 2.f;
        plutovg_matrix_t inverse;
        if(!plutovg_matrix_invert(&tileMatrix, &inverse)) {
            tvg::Paint::rel(shape);
            return;
        }

        auto toTile = sceneMultiply(inverse, transform.matrix());
        float minX = 0, minY = 0, maxX = 0, maxY = 0;
        const plutovg_point_t corners[] = {
            { extents.x, extents.y }, { extents.x + extents.w, extents.y },
            { extents.x, extents.y + extents.h }, { extents.x + extents.w, extents.y + extents.h }
        };

        for(int i = 0; i < 4; i++) {
            plutovg_point_t point;
            plutovg_matrix_map_point(&toTile, &corners[i], &point);
            if(i == 0 || point.x < minX) minX = point.x;
            if(i == 0 || point.y < minY) minY = point.y;
            if(i == 0 || point.x > maxX) maxX = point.x;
            if(i == 0 || point.y > maxY) maxY = point.y;
        }

        firstColumn = static_cast<int>(std::floor(minX / paint.tileWidth));
        lastColumn = static_cast<int>(std::floor(maxX / paint.tileWidth));
        firstRow = static_cast<int>(std::floor(minY / paint.tileHeight));
        lastRow = static_cast<int>(std::floor(maxY / paint.tileHeight));
        constexpr long long kMaxTiles = 4096; // a tile tiny against the shape is left out, not drawn a million times
        if(static_cast<long long>(lastColumn - firstColumn + 1) * (lastRow - firstRow + 1) > kMaxTiles) {
            tvg::Paint::rel(shape);
            return;
        }
    }

    auto tiles = tvg::Scene::gen();
    for(int row = firstRow; row <= lastRow; row++) {
        for(int column = firstColumn; column <= lastColumn; column++) {
            // each tile cut to its own size, as its pixels are. ThorVG doesn't move a paint's clipper by the paint's own
            // transform, so the tile's scene stays untransformed, its clipper and content each given the tile's.
            plutovg_matrix_t offset = { 1, 0, 0, 1, static_cast<float>(column * paint.tileWidth), static_cast<float>(row * paint.tileHeight) };
            auto matrix = sceneMatrix(sceneMultiply(tileMatrix, offset));
            auto clipper = tvg::Shape::gen();
            clipper->appendRect(0, 0, static_cast<float>(paint.tileWidth), static_cast<float>(paint.tileHeight));
            clipper->transform(matrix);
            auto content = paint.tile->duplicate();
            content->transform(matrix);
            auto tile = tvg::Scene::gen();
            tile->clip(clipper);
            tile->add(content);
            tiles->add(tile);
        }
    }

    tiles->opacity(sceneByte(paint.opacity));
    tiles->mask(shape, tvg::MaskMethod::Alpha);
    m_target->add(tiles);
}

void Canvas::fillPath(const Path& path, FillRule fillRule, const Transform& transform)
{
    if(m_scene) {
        addShape(sceneShape(path.data(), fillRule, transform.matrix()), path.data(), 0.f, transform, false);
        return;
    }

    plutovg_canvas_set_matrix(m_canvas, &m_translation);
    plutovg_canvas_transform(m_canvas, &transform.matrix());
    plutovg_canvas_set_fill_rule(m_canvas, static_cast<plutovg_fill_rule_t>(fillRule));
    plutovg_canvas_set_operator(m_canvas, PLUTOVG_OPERATOR_SRC_OVER);
    plutovg_canvas_fill_path(m_canvas, path.data());
}

static void sceneStroke(tvg::Shape* shape, float width, float miterLimit, LineCap cap, LineJoin join, float dashOffset, const DashArray& dashes)
{
    shape->strokeWidth(width);
    shape->strokeMiterlimit(miterLimit);
    shape->strokeCap(cap == LineCap::Round ? tvg::StrokeCap::Round : cap == LineCap::Square ? tvg::StrokeCap::Square : tvg::StrokeCap::Butt);
    shape->strokeJoin(join == LineJoin::Round ? tvg::StrokeJoin::Round : join == LineJoin::Bevel ? tvg::StrokeJoin::Bevel : tvg::StrokeJoin::Miter);
    if(!dashes.empty())
        shape->strokeDash(dashes.data(), static_cast<uint32_t>(dashes.size()), dashOffset);
}

void Canvas::strokePath(const Path& path, const StrokeData& strokeData, const Transform& transform)
{
    if(m_scene) {
        auto shape = sceneShape(path.data(), FillRule::NonZero, transform.matrix());
        sceneStroke(shape, strokeData.lineWidth(), strokeData.miterLimit(), strokeData.lineCap(), strokeData.lineJoin(), strokeData.dashOffset(), strokeData.dashArray());
        addShape(shape, path.data(), strokeData.lineWidth() * std::max(strokeData.miterLimit(), 1.f), transform, true);
        return;
    }

    plutovg_canvas_set_matrix(m_canvas, &m_translation);
    plutovg_canvas_transform(m_canvas, &transform.matrix());
    plutovg_canvas_set_line_width(m_canvas, strokeData.lineWidth());
    plutovg_canvas_set_miter_limit(m_canvas, strokeData.miterLimit());
    plutovg_canvas_set_line_cap(m_canvas, static_cast<plutovg_line_cap_t>(strokeData.lineCap()));
    plutovg_canvas_set_line_join(m_canvas, static_cast<plutovg_line_join_t>(strokeData.lineJoin()));
    plutovg_canvas_set_dash_offset(m_canvas, strokeData.dashOffset());
    plutovg_canvas_set_dash_array(m_canvas, strokeData.dashArray().data(), strokeData.dashArray().size());
    plutovg_canvas_set_operator(m_canvas, PLUTOVG_OPERATOR_SRC_OVER);
    plutovg_canvas_stroke_path(m_canvas, path.data());
}

// The text's glyph outlines as one path, as plutovg_canvas_add_text builds it
static plutovg_path_t* sceneTextPath(const std::u32string_view& text, const Font& font, const Point& origin)
{
    auto path = plutovg_path_create();
    if(font.face().isNull() || font.size() <= 0.f)
        return path;
    plutovg_text_iterator_t it;
    plutovg_text_iterator_init(&it, text.data(), static_cast<int>(text.length()), PLUTOVG_TEXT_ENCODING_UTF32);
    float advanceWidth = 0.f;
    while(plutovg_text_iterator_has_next(&it)) {
        auto codepoint = plutovg_text_iterator_next(&it);
        advanceWidth += plutovg_font_face_get_glyph_path(font.face().get(), font.size(), origin.x + advanceWidth, origin.y, codepoint, path);
    }

    return path;
}

void Canvas::fillText(const std::u32string_view& text, const Font& font, const Point& origin, const Transform& transform)
{
    if(m_scene) {
        auto path = sceneTextPath(text, font, origin);
        addShape(sceneShape(path, FillRule::NonZero, transform.matrix()), path, 0.f, transform, false);
        plutovg_path_destroy(path);
        return;
    }

    plutovg_canvas_set_matrix(m_canvas, &m_translation);
    plutovg_canvas_transform(m_canvas, &transform.matrix());
    plutovg_canvas_set_fill_rule(m_canvas, PLUTOVG_FILL_RULE_NON_ZERO);
    plutovg_canvas_set_operator(m_canvas, PLUTOVG_OPERATOR_SRC_OVER);
    plutovg_canvas_set_font(m_canvas, font.face().get(), font.size());
    plutovg_canvas_fill_text(m_canvas, text.data(), text.length(), PLUTOVG_TEXT_ENCODING_UTF32, origin.x, origin.y);
}

void Canvas::strokeText(const std::u32string_view& text, float strokeWidth, const Font& font, const Point& origin, const Transform& transform)
{
    if(m_scene) {
        auto path = sceneTextPath(text, font, origin);
        auto shape = sceneShape(path, FillRule::NonZero, transform.matrix());
        sceneStroke(shape, strokeWidth, 4.f, LineCap::Butt, LineJoin::Miter, 0.f, DashArray());
        addShape(shape, path, strokeWidth * 4.f, transform, true);
        plutovg_path_destroy(path);
        return;
    }

    plutovg_canvas_set_matrix(m_canvas, &m_translation);
    plutovg_canvas_transform(m_canvas, &transform.matrix());
    plutovg_canvas_set_line_width(m_canvas, strokeWidth);
    plutovg_canvas_set_miter_limit(m_canvas, 4.f);
    plutovg_canvas_set_line_cap(m_canvas, PLUTOVG_LINE_CAP_BUTT);
    plutovg_canvas_set_line_join(m_canvas, PLUTOVG_LINE_JOIN_MITER);
    plutovg_canvas_set_dash_offset(m_canvas, 0.f);
    plutovg_canvas_set_dash_array(m_canvas, nullptr, 0);
    plutovg_canvas_set_operator(m_canvas, PLUTOVG_OPERATOR_SRC_OVER);
    plutovg_canvas_set_font(m_canvas, font.face().get(), font.size());
    plutovg_canvas_stroke_text(m_canvas, text.data(), text.length(), PLUTOVG_TEXT_ENCODING_UTF32, origin.x, origin.y);
}

void Canvas::clipPath(const Path& path, FillRule clipRule, const Transform& transform)
{
    if(m_scene) {
        auto clipped = tvg::Scene::gen();
        clipped->clip(sceneShape(path.data(), clipRule, transform.matrix()));
        m_target->add(clipped);
        m_target = clipped;
        return;
    }

    plutovg_canvas_set_matrix(m_canvas, &m_translation);
    plutovg_canvas_transform(m_canvas, &transform.matrix());
    plutovg_canvas_set_fill_rule(m_canvas, static_cast<plutovg_fill_rule_t>(clipRule));
    plutovg_canvas_clip_path(m_canvas, path.data());
}

void Canvas::clipRect(const Rect& rect, FillRule clipRule, const Transform& transform)
{
    if(m_scene) {
        auto clipper = tvg::Shape::gen();
        clipper->appendRect(rect.x, rect.y, rect.w, rect.h);
        clipper->transform(sceneMatrix(transform.matrix()));
        auto clipped = tvg::Scene::gen();
        clipped->clip(clipper);
        m_target->add(clipped);
        m_target = clipped;
        return;
    }

    plutovg_canvas_set_matrix(m_canvas, &m_translation);
    plutovg_canvas_transform(m_canvas, &transform.matrix());
    plutovg_canvas_set_fill_rule(m_canvas, static_cast<plutovg_fill_rule_t>(clipRule));
    plutovg_canvas_clip_rect(m_canvas, rect.x, rect.y, rect.w, rect.h);
}

void Canvas::drawImage(const Bitmap& image, const Rect& dstRect, const Rect& srcRect, const Transform& transform)
{
    auto xScale = dstRect.w / srcRect.w;
    auto yScale = dstRect.h / srcRect.h;
    plutovg_matrix_t matrix = { xScale, 0, 0, yScale, -srcRect.x * xScale, -srcRect.y * yScale };
    if(m_scene) {
        // the image's premultiplied ARGB32, copied for the picture (which frees it)
        auto surface = image.surface();
        int width = plutovg_surface_get_width(surface);
        int height = plutovg_surface_get_height(surface);
        int stride = plutovg_surface_get_stride(surface);
        if(width <= 0 || height <= 0)
            return;
        auto pixels = static_cast<uint32_t*>(std::malloc(static_cast<size_t>(width) * height * 4));
        if(pixels == nullptr)
            return;
        auto data = plutovg_surface_get_data(surface);
        for(int y = 0; y < height; y++)
            std::memcpy(pixels + static_cast<size_t>(y) * width, data + static_cast<size_t>(y) * stride, static_cast<size_t>(width) * 4);
        auto picture = tvg::Picture::gen();
        if(picture->load(pixels, static_cast<uint32_t>(width), static_cast<uint32_t>(width), static_cast<uint32_t>(height), tvg::ColorSpace::ARGB8888, false) != tvg::Result::Success) {
            std::free(pixels);
            tvg::Paint::rel(picture);
            return;
        }

        plutovg_matrix_t place = sceneMultiply(transform.matrix(), { 1, 0, 0, 1, dstRect.x, dstRect.y });
        picture->transform(sceneMatrix(sceneMultiply(place, matrix)));
        auto clipper = tvg::Shape::gen();
        clipper->appendRect(0, 0, dstRect.w, dstRect.h);
        clipper->transform(sceneMatrix(place));
        auto clipped = tvg::Scene::gen();
        clipped->clip(clipper);
        clipped->add(picture);
        m_target->add(clipped);
        return;
    }

    plutovg_canvas_set_matrix(m_canvas, &m_translation);
    plutovg_canvas_transform(m_canvas, &transform.matrix());
    plutovg_canvas_translate(m_canvas, dstRect.x, dstRect.y);
    plutovg_canvas_set_fill_rule(m_canvas, PLUTOVG_FILL_RULE_NON_ZERO);
    plutovg_canvas_set_operator(m_canvas, PLUTOVG_OPERATOR_SRC_OVER);
    plutovg_canvas_set_texture(m_canvas, image.surface(), PLUTOVG_TEXTURE_TYPE_PLAIN, 1.f, &matrix);
    plutovg_canvas_fill_rect(m_canvas, 0, 0, dstRect.w, dstRect.h);
}

void Canvas::blendCanvas(const Canvas& canvas, BlendMode blendMode, float opacity)
{
    if(m_scene) {
        if(canvas.m_scene == nullptr)
            return;
        if(blendMode == BlendMode::Dst_In || blendMode == BlendMode::Dst_Out) {
            // what this canvas holds, masked by the other: a new root holding the old one, so a second mask (a clip
            // mask, then a mask) masks the result of the first
            auto method = blendMode == BlendMode::Dst_Out ? (canvas.m_luminance ? tvg::MaskMethod::InvLuma : tvg::MaskMethod::InvAlpha)
                                                          : (canvas.m_luminance ? tvg::MaskMethod::Luma : tvg::MaskMethod::Alpha);
            auto root = tvg::Scene::gen();
            root->ref();
            root->add(m_scene);
            m_scene->unref();
            m_scene->mask(canvas.m_scene, method);
            m_scene = m_target = root;
            m_targets.clear();
            return;
        }

        canvas.m_scene->opacity(sceneByte(opacity));
        m_target->add(canvas.m_scene);
        return;
    }

    plutovg_matrix_t matrix = { 1, 0, 0, 1, static_cast<float>(canvas.x()), static_cast<float>(canvas.y()) };
    plutovg_canvas_set_matrix(m_canvas, &m_translation);
    plutovg_canvas_set_operator(m_canvas, static_cast<plutovg_operator_t>(blendMode));
    plutovg_canvas_set_texture(m_canvas, canvas.surface(), PLUTOVG_TEXTURE_TYPE_PLAIN, opacity, &matrix);
    plutovg_canvas_paint(m_canvas);
}

void Canvas::save()
{
    if(m_scene) {
        m_targets.push_back(m_target);
        return;
    }

    plutovg_canvas_save(m_canvas);
}

void Canvas::restore()
{
    if(m_scene) {
        if(!m_targets.empty()) {
            m_target = m_targets.back();
            m_targets.pop_back();
        }

        return;
    }

    plutovg_canvas_restore(m_canvas);
}

int Canvas::width() const
{
    if(m_surface == nullptr)
        return m_width;
    return plutovg_surface_get_width(m_surface);
}

int Canvas::height() const
{
    if(m_surface == nullptr)
        return m_height;
    return plutovg_surface_get_height(m_surface);
}

void Canvas::convertToLuminanceMask()
{
    if(m_scene) {
        m_luminance = true;
        return;
    }

    auto width = plutovg_surface_get_width(m_surface);
    auto height = plutovg_surface_get_height(m_surface);
    auto stride = plutovg_surface_get_stride(m_surface);
    auto data = plutovg_surface_get_data(m_surface);
    for(int y = 0; y < height; y++) {
        auto pixels = reinterpret_cast<uint32_t*>(data + stride * y);
        for(int x = 0; x < width; x++) {
            auto pixel = pixels[x];
            auto a = (pixel >> 24) & 0xFF;
            auto r = (pixel >> 16) & 0xFF;
            auto g = (pixel >> 8) & 0xFF;
            auto b = (pixel >> 0) & 0xFF;
            if(a) {
                r = (r * 255) / a;
                g = (g * 255) / a;
                b = (b * 255) / a;
            }

            auto l = (r * 0.2125 + g * 0.7154 + b * 0.0721);
            pixels[x] = static_cast<uint32_t>(l * (a / 255.0)) << 24;
        }
    }
}

Canvas::~Canvas()
{
    if(m_scene)
        m_scene->unref();
    plutovg_canvas_destroy(m_canvas);
    plutovg_surface_destroy(m_surface);
}

Canvas::Canvas(const Bitmap& bitmap)
    : m_surface(plutovg_surface_reference(bitmap.surface()))
    , m_canvas(plutovg_canvas_create(m_surface))
    , m_translation({1, 0, 0, 1, 0, 0})
    , m_x(0), m_y(0)
{
}

Canvas::Canvas(int x, int y, int width, int height)
    : m_surface(plutovg_surface_create(width, height))
    , m_canvas(plutovg_canvas_create(m_surface))
    , m_translation({1, 0, 0, 1, -static_cast<float>(x), -static_cast<float>(y)})
    , m_x(x), m_y(y)
{
}

Canvas::Canvas(int x, int y, int width, int height, bool)
    : m_surface(nullptr)
    , m_canvas(nullptr)
    , m_translation({1, 0, 0, 1, 0, 0})
    , m_x(x), m_y(y)
    , m_paint(new ScenePaint)
    , m_width(width), m_height(height)
{
    m_scene = m_target = tvg::Scene::gen();
    m_scene->ref();
}

} // namespace lunasvg
