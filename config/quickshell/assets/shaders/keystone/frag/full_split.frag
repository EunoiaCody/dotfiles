#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
    vec4 fillColor;
    vec2 mainCenter;
    vec2 mainSize;
    float mainRadius;
    vec2 satelliteCenter;
    vec2 satelliteSize;
    float satelliteRadius;
    float blendRadius;
    float edgeSoftness;
    vec4 cutoutRect;
    float cutoutRadius;
    float attached;
    vec2 inwardDirection;
} ubuf;

float roundedBoxDistance(vec2 point, vec2 halfSize, float radius)
{
    vec2 edgeDistance = abs(point) - halfSize + vec2(radius);
    return min(max(edgeDistance.x, edgeDistance.y), 0.0)
        + length(max(edgeDistance, vec2(0.0)))
        - radius;
}

float smoothMinimum(float first, float second, float radius)
{
    if (radius <= 0.001)
        return min(first, second);

    float influence = max(radius - abs(first - second), 0.0) / radius;
    return min(first, second) - influence * influence * radius * 0.25;
}

float mainBarDistance(vec2 point)
{
    if (ubuf.attached < 0.5)
        return roundedBoxDistance(point, ubuf.mainSize * 0.5, ubuf.mainRadius);

    // Canonical coordinates: x follows the screen edge, y points inward.
    vec2 tangent = vec2(ubuf.inwardDirection.y, -ubuf.inwardDirection.x);
    vec2 p = vec2(dot(point, tangent), dot(point, ubuf.inwardDirection));
    vec2 halfSize = vec2(dot(ubuf.mainSize, abs(tangent)),
                        dot(ubuf.mainSize, abs(ubuf.inwardDirection))) * 0.5;
    float body = roundedBoxDistance(p, halfSize, p.y > 0.0 ? ubuf.mainRadius : 0.0);
    // Flat at the screen, concave shoulders outside the body, round inward corners.
    vec2 shoulder = vec2(abs(p.x) - halfSize.x, p.y + halfSize.y);
    vec2 extent = vec2(8.0, 14.0);
    float bounds = roundedBoxDistance(shoulder - extent * 0.5, extent * 0.5, 0.0);
    float ellipse = (length((shoulder - extent) / extent) - 1.0) * 8.0;
    return min(body, max(bounds, -ellipse));
}

void main()
{
    vec2 pixel = qt_TexCoord0 * ubuf.resolution;
    float mainDistance = mainBarDistance(pixel - ubuf.mainCenter);
    float satelliteDistance = roundedBoxDistance(
        pixel - ubuf.satelliteCenter,
        ubuf.satelliteSize * 0.5,
        ubuf.satelliteRadius
    );
    // The circular seed supplies the thinning neck after separation.
    float seedDistance = length(pixel - ubuf.mainCenter) - ubuf.mainRadius;
    float lobeDistance = smoothMinimum(
        seedDistance,
        satelliteDistance,
        ubuf.blendRadius
    );
    // While the panel overlaps the bar, blend the entire contact boundary:
    // a hard union leaves square shoulders at the two concave corners.
    // As the gap opens, reduce this fillet to the neck's root so the broad
    // contact area flows into a narrow neck instead of becoming a flat sheet.
    bool horizontal = ubuf.mainSize.x >= ubuf.mainSize.y;
    float centerDistance = horizontal
        ? abs(ubuf.satelliteCenter.y - ubuf.mainCenter.y)
        : abs(ubuf.satelliteCenter.x - ubuf.mainCenter.x);
    float halfDepths = horizontal
        ? (ubuf.mainSize.y + ubuf.satelliteSize.y) * 0.5
        : (ubuf.mainSize.x + ubuf.satelliteSize.x) * 0.5;
    float gap = centerDistance - halfDepths;
    float contact = 1.0 - smoothstep(0.0, 12.0, gap);
    float inward = horizontal
        ? (pixel.y - ubuf.mainCenter.y) * sign(ubuf.satelliteCenter.y - ubuf.mainCenter.y)
        : (pixel.x - ubuf.mainCenter.x) * sign(ubuf.satelliteCenter.x - ubuf.mainCenter.x);
    // Confine fusion to the inward edge; the buried seed must not swell the
    // opposite side of the bar above the clock.
    lobeDistance = max(lobeDistance, -inward);
    float joinRadius = ubuf.blendRadius * mix(0.30, 1.0, contact)
        * smoothstep(0.0, ubuf.mainRadius, inward);
    float distanceToSurface = smoothMinimum(mainDistance, lobeDistance, joinRadius);
    if (ubuf.cutoutRect.z > 0.0) {
        float cutoutDistance = roundedBoxDistance(
            pixel - ubuf.cutoutRect.xy - ubuf.cutoutRect.zw * 0.5,
            ubuf.cutoutRect.zw * 0.5,
            ubuf.cutoutRadius
        );
        // The keyhole belongs only to the child; it must never punch through
        // the persistent clock bar while the child is being absorbed.
        distanceToSurface = min(mainDistance, max(distanceToSurface, -cutoutDistance));
    }
    float alpha = 1.0 - smoothstep(
        -ubuf.edgeSoftness,
        ubuf.edgeSoftness,
        distanceToSurface
    );

    fragColor = ubuf.fillColor * alpha * ubuf.qt_Opacity;
}
