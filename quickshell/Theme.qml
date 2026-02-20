// ============================================================
// Quickshell 主题配置 - Catppuccin Mocha 配色方案
// 与 SketchyBar colors.lua 完全一致
// ============================================================
pragma Singleton
import QtQuick

QtObject {
    // -------------------- Catppuccin Mocha 颜色 --------------------

    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color text: "#cdd6f4"
    readonly property color subtext1: "#bac2de"
    readonly property color subtext0: "#a6adc8"
    readonly property color overlay2: "#9399b2"
    readonly property color overlay1: "#7f849c"
    readonly property color overlay0: "#6c7086"
    readonly property color surface2: "#585b70"
    readonly property color surface1: "#45475a"
    readonly property color surface0: "#313244"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"
    readonly property color sapphire: "#74c7ec"
    readonly property color sky: "#89dceb"
    readonly property color teal: "#94e2d5"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color peach: "#fab387"
    readonly property color maroon: "#eba0ac"
    readonly property color red: "#f38ba8"
    readonly property color mauve: "#cba6f7"
    readonly property color pink: "#f5c2e7"
    readonly property color flamingo: "#f2cdcd"
    readonly property color rosewater: "#f5e0dc"

    // -------------------- 透明色 --------------------

    readonly property color transparent: "transparent"
    // 状态栏半透明背景
    readonly property color barBackground: Qt.rgba(30/255, 30/255, 46/255, 0.9)

    // -------------------- 字体配置 --------------------

    // 主字体（与 SketchyBar settings.lua 一致）
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    // 中文字体
    readonly property string cjkFontFamily: "Noto Sans CJK SC"
    // 图标字体
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    // 字体大小
    readonly property int fontSize: 14
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeLarge: 16

    // -------------------- 状态栏尺寸 --------------------

    // 状态栏高度（与 SketchyBar 的 40px 一致）
    readonly property int barHeight: 40
    // 组件内边距
    readonly property int widgetPadding: 10
    // 组件间距
    readonly property int widgetSpacing: 8
    // 圆角半径
    readonly property int radius: 8

    // -------------------- 更新间隔（毫秒） --------------------

    readonly property int clockInterval: 1000
    readonly property int systemStatsInterval: 5000
    readonly property int networkInterval: 5000
    readonly property int batteryInterval: 30000
    readonly property int brightnessInterval: 5000

    // -------------------- 动画配置 --------------------

    readonly property int animationDuration: 200
    readonly property int animationDurationFast: 100
    readonly property int animationDurationSlow: 300
}
