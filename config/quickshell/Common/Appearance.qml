pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

// Appearance.qml — re-exports ColorMap (m3/colors/rounding/etc.) AND
// utility functions (clamp01/mix/transparentize/applyAlpha/solveOverlayColor)
// AND animation tokens (curves/animation).
// so StatIndet modules can call Appearance.mix() / Appearance.curves.* etc.

Singleton {
    id: root

    property real backgroundTransparency: 0
    property real contentTransparency: 0.9
    property string currentWallpaperPreview: ""

    // Re-export ColorMap properties
    property QtObject m3colors: ColorMap.m3colors
    property QtObject colors: ColorMap.colors
    property QtObject rounding: ColorMap.rounding
    property QtObject spacing: ColorMap.spacing
    property QtObject scrollBar: ColorMap.scrollBar

    // Re-export Animations (M3 motion tokens)
    property QtObject curves: Animations.curves
    property QtObject animation: Animations.animation
    property QtObject animationCurves: Animations.curves

    // Re-export utility functions so callers can use Appearance.mix() etc.
    function clamp01(value) { return ColorMap.clamp01(value); }
    function mix(c1, c2, p) { return ColorMap.mix(c1, c2, p); }
    function transparentize(c, p) { return ColorMap.transparentize(c, p); }
    function applyAlpha(c, a) { return ColorMap.applyAlpha(c, a); }
    function solveOverlayColor(b, t, o) { return ColorMap.solveOverlayColor(b, t, o); }
}
