pragma Singleton

import Quickshell

Singleton {
    readonly property string fontFamily: "Symbols Nerd Font"
    readonly property string fontFamilyMono: "JetBrainsMono Nerd Font"
    readonly property string fontIcon: "Symbols Nerd Font"
    readonly property string fontFamilyLyric: "LXGW WenKai"
    readonly property real cornerRadius: 10
    readonly property real barHeight: 44
    // Bar 令牌（迁移自 StatIndet HEAD）
    readonly property real barVisualThickness: 44
    readonly property real barPillThickness: 36
    readonly property real barPillHorizontalPadding: 8
    readonly property real barItemSpacing: 4
    readonly property real barLabelSpacing: 6
    readonly property real barIconSize: 20
    readonly property real barControlCircleSize: 28
    readonly property real barOuterEdgeMargin: 8
    readonly property real barShadowBuffer: 36
    readonly property real barPopupGap: 8
    readonly property real barPopupScreenMargin: 10
    readonly property real verticalBarWidth: barVisualThickness
    readonly property real sidebarScrollableListMaxHeight: 224

    readonly property real lockReferenceScale: 4 / 3
    readonly property real lockCardRadius: 33
    readonly property real lockCardPadding: 27
    readonly property real lockIconSize: 32
    readonly property real lockHeightMult: 0.7
    readonly property real lockRatio: 16 / 9
    readonly property real lockCenterWidth: 600
    readonly property real lockOuterPadding: 20
    readonly property real lockColumnGap: 53
    readonly property real lockCardGap: 16
    readonly property real lockCardRadiusSmall: 16
    readonly property real lockCardRadiusLarge: 33
    readonly property real lockIconPanelSize: 213
    readonly property real lockWeatherForecastHeight: 340
    readonly property real lockWeatherCompactHeight: 236
    readonly property real lockMediaHeight: 228
    readonly property real lockSystemGridHeight: 563
    readonly property real lockAuthHeight: 64
    readonly property real lockTimeFontSize: 112
    readonly property real lockTimeSuffixFontSize: 75
    readonly property real lockDateFontSize: 37
    readonly property real lockResourceTileRadius: 23
    readonly property real lockResourceProgressPadding: 60
    readonly property real lockResourceProgressStroke: 9
    readonly property real lockResourceProgressGap: 9
    readonly property real lockResourceIconMinSize: 56
    readonly property real lockResourceIconScale: 0.82
}
