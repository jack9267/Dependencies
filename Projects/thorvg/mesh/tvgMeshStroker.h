/*
 * Dependencies: ThorVG's GL engine's Stroker (gpu_engine/gl/tvgGlTessellator.h, 1.1.4) as it is, renamed, for the
 * mesh engine: the GL one needs OpenGL's headers, which the mesh engine has no use for. Its triangles overlap (joins
 * over segments); the mesh engine merges them into one area.
 *
 * Copyright (c) 2023 - 2026 ThorVG project. All rights reserved.

 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.

 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef _TVG_MESH_STROKER_H_
#define _TVG_MESH_STROKER_H_

#include "tvgRender.h"
#include "tvgMath.h"
#include "tvgGpuCommon.h"

namespace tvg
{

struct MeshGeometryBuffer
{
    Array<float> vertex;
    Array<uint32_t> index;

    void clear()
    {
        vertex.clear();
        index.clear();
    }
};

struct MeshStroker
{
    struct State
    {
        Point firstPt;
        Point firstPtDir;
        Point prevPt;
        Point prevPtDir;
        float firstLength;
        float prevLength;
        uint32_t firstIndex;
        uint32_t prevIndex;
    };

    MeshStroker(MeshGeometryBuffer* buffer, float strokeWidth, StrokeCap cap, StrokeJoin join, float miterLimit = 4.0f, float qualityScale = 1.0f);
    void run(const RenderPath& path, bool thinFill = false);
    RenderRegion bounds() const;
    bool overlapFree;

private:
    float radius() const { return mWidth * 0.5f; }
    void cap();
    void lineTo(const Point& curr);
    void cubicTo(const Point& cnt1, const Point& cnt2, const Point& end);
    void close();
    void join(const Point& dir, float len, uint32_t index);
    void round(const Point& prev, const Point& curr, const Point& center, const Point& apex);
    void miter(const Point& prev, const Point& curr, const Point& center, const Point& apex);
    void bevel(const Point& prev, const Point& curr, const Point& apex);
    void square(const Point& p, const Point& outDir);
    void squarePoint(const Point& p);
    void round(const Point& p, const Point& outDir);
    void roundPoint(const Point& p);

    MeshGeometryBuffer* mBuffer;
    float mWidth = 0.0f;
    float mMiterLimit = 4.f;
    float mQualityScale = 1.0f;
    StrokeCap mCap = StrokeCap::Square;
    StrokeJoin mJoin = StrokeJoin::Bevel;
    bool mThinFill;
    uint8_t mDirections;  // +x, -x, +y, -y of the tessellated edges
    GpuConvexProbe mProbe;
    State mState = {};
    Point mLeftTop = {0.0f, 0.0f};
    Point mRightBottom = {0.0f, 0.0f};
};

}  // namespace tvg

#endif /* _TVG_MESH_STROKER_H_ */
