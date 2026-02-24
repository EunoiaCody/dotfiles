// ============================================================
// 状态栏面板 - 主布局
// 从 SketchyBar 迁移：左侧工作区+窗口标题 | 中间时钟 | 右侧系统信息
// ============================================================
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "widgets"

PanelWindow {
    id: bar

    // 锚定到屏幕顶部（与 SketchyBar 位置一致）
    anchors {
        top: true
        left: true
        right: true
    }

    // 状态栏高度
    implicitHeight: Theme.barHeight

    // 半透明背景（与 SketchyBar 的模糊背景效果一致）
    color: Theme.barBackground

    // -------------------- 三栏布局 --------------------
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 0

        // ===== 左侧：工作区 + 活动窗口 =====
        // （对应 SketchyBar 的 spaces.lua + front_app.lua）
        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Theme.widgetSpacing

            Workspaces {
                screen: bar.screen
            }

            WindowTitle {}
        }

        // 弹性间距
        Item {
            Layout.fillWidth: true
        }

        // ===== 中间：时钟 =====
        // （对应 SketchyBar 的 clock.lua）
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            Clock {}
        }

        // 弹性间距
        Item {
            Layout.fillWidth: true
        }

        // ===== 右侧：系统信息 =====
        // （对应 SketchyBar 的 volume.lua + network.lua + ram.lua）
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Theme.widgetSpacing

            CpuWidget {}
            MemoryWidget {}
            NetworkWidget {}
            VolumeWidget {}
            BrightnessWidget {}
            BatteryWidget {}
            SystemTrayWidget {}
            PowerMenu {}
        }
    }
}
