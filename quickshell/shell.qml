// ============================================================
// Quickshell 主入口文件
// 配置文件位置: ~/.config/quickshell/shell.qml
// 用于替代 Waybar，搭配 Niri 窗口管理器使用
// ============================================================
import Quickshell
import QtQuick

ShellRoot {
    // 为每个屏幕创建一个状态栏（与 SketchyBar 的多显示器支持一致）
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
