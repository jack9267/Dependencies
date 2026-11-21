/*
 * Dependencies: MeshCanvas (thorvg_mesh.h), a canvas on the mesh engine, made as SwCanvas is (tvgCanvas.cpp).
 */

#include "tvgCanvas.h"
#include "tvgLoader.h"
#include "tvgMeshRenderer.h"

namespace tvg
{

MeshCanvas::MeshCanvas() = default;

MeshCanvas::~MeshCanvas() = default;


Result MeshCanvas::target(uint32_t w, uint32_t h) noexcept
{
    if (pImpl->status == Status::Updating || pImpl->status == Status::Drawing) return Result::InsufficientCondition;
    if (w == 0 || h == 0) return Result::InvalidArguments;

    static_cast<MeshRenderer*>(pImpl->renderer)->target(w, h);
    pImpl->vport = {0, 0, int32_t(w), int32_t(h)};
    pImpl->renderer->viewport(pImpl->vport);
    pImpl->status = Status::Damaged;  // paints must be updated again for this target

    // pictures inside what is loaded are decoded to what the canvases want; every canvas here takes RGBA
    BitmapLoader::cs = ColorSpace::ABGR8888;

    return Result::Success;
}


uint32_t MeshCanvas::batches() const noexcept
{
    return uint32_t(static_cast<const MeshRenderer*>(pImpl->renderer)->batches.size());
}


const MeshBatch* MeshCanvas::batch(uint32_t index) const noexcept
{
    auto& batches = static_cast<const MeshRenderer*>(pImpl->renderer)->batches;
    return index < batches.size() ? &batches[index] : nullptr;
}


uint32_t MeshCanvas::images() const noexcept
{
    return uint32_t(static_cast<const MeshRenderer*>(pImpl->renderer)->images.size());
}


const MeshImage* MeshCanvas::image(uint32_t index) const noexcept
{
    auto& images = static_cast<const MeshRenderer*>(pImpl->renderer)->images;
    return index < images.size() ? &images[index] : nullptr;
}


bool MeshCanvas::complete() const noexcept
{
    return static_cast<const MeshRenderer*>(pImpl->renderer)->complete;
}


MeshCanvas* MeshCanvas::gen() noexcept
{
    if (engineInit > 0) {
        auto renderer = new MeshRenderer;
        renderer->ref();
        auto ret = new MeshCanvas;
        ret->pImpl->renderer = renderer;
        return ret;
    }
    TVGLOG("RENDERER", "MeshCanvas needs Initializer::init() first");
    return nullptr;
}

}
