// ============================================================
// 电源菜单组件
// 从 SketchyBar apple.lua 迁移
// 点击执行 wlogout 电源菜单
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    implicitWidth: powerBackground.width
    implicitHeight: Theme.barHeight

    // -------------------- 电源命令 --------------------
    Process {
        id: powerProcess
        command: []
    }

    // -------------------- 显示 --------------------
    Rectangle {
        id: powerBackground
        width: powerText.implicitWidth + Theme.widgetPadding * 2
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: Theme.surface0

        // 悬停变色动画
        property bool hovered: false
        Behavior on color {
            ColorAnimation { duration: Theme.animationDuration }
        }

        Text {
            id: powerText
            anchors.centerIn: parent
            text: "⏻"
            color: powerBackground.hovered ? Theme.base : Theme.red
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontSizeLarge

            Behavior on color {
                ColorAnimation { duration: Theme.animationDuration }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                powerBackground.hovered = true
                powerBackground.color = Theme.red
            }
            onExited: {
                powerBackground.hovered = false
                powerBackground.color = Theme.surface0
            }
            onClicked: {
                // 打开电源菜单（需安装 wlogout）
                powerProcess.command = ["wlogout"]
                powerProcess.running = true
            }
        }
    }
}
