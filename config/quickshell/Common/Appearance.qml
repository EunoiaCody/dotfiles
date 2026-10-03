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
    // 上游兼容（matugen 已禁用，固定 Catppuccin）
    property string matugenMode: "dark"
    property string matugenScheme: "scheme-tonal-spot"
    readonly property string effectiveMatugenMode: matugenMode === "light" ? "light" : "dark"
    function reloadColors() {}

    // Re-export ColorMap properties
    property QtObject m3colors: ColorMap.m3colors
    property QtObject colors: ColorMap.colors
    property QtObject rounding: ColorMap.rounding
    property QtObject spacing: ColorMap.spacing
    property QtObject scrollBar: ColorMap.scrollBar

    // Interaction tokens (ripple / state layers) — 迁移自 StatIndet HEAD Appearance.qml
    property QtObject interaction: QtObject {
        readonly property int rippleDuration: 700
        readonly property real rippleOpacity: 0.22
        readonly property int stateLayerTransitionDuration: Animations.durations.expressiveFastEffects
        readonly property real hoverStateLayerOpacity: 0.08
        readonly property real focusStateLayerOpacity: 0.10
        readonly property real pressedStateLayerOpacity: 0.12
        readonly property real selectedStateLayerOpacity: 0.10
        readonly property int rippleEasing: Easing.OutCubic
    }

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
