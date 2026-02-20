// ============================================================
// 音量控制组件
// 从 SketchyBar volume.lua 迁移
// 使用 wpctl (WirePlumber) 获取和控制音量
// 支持滚轮调节和点击静音
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    implicitWidth: volBackground.width
    implicitHeight: Theme.barHeight

    property int volume: 0
    property bool muted: false

    // -------------------- 定时更新 --------------------
    Timer {
        interval: Theme.systemStatsInterval
        running: true
        repeat: true
        onTriggered: volumeProcess.running = true
    }

    Component.onCompleted: volumeProcess.running = true

    // -------------------- 获取音量 --------------------
    Process {
        id: volumeProcess
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                // 输出格式: "Volume: 0.50" 或 "Volume: 0.50 [MUTED]"
                const line = data.trim()
                root.muted = line.includes("[MUTED]")

                const match = line.match(/Volume:\s+([0-9.]+)/)
                if (match) {
                    root.volume = Math.round(parseFloat(match[1]) * 100)
                }
            }
        }
    }

    // -------------------- 音量控制命令 --------------------
    Process {
        id: volumeSetProcess
        command: []
    }

    function setVolume(delta) {
        const cmd = delta > 0 ? (delta + "%+") : ((-delta) + "%-")
        volumeSetProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", cmd]
        volumeSetProcess.running = true
        // 立即刷新
        volumeProcess.running = true
    }

    function toggleMute() {
        volumeSetProcess.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        volumeSetProcess.running = true
        volumeProcess.running = true
    }

    // -------------------- 显示 --------------------
    Rectangle {
        id: volBackground
        width: volRow.implicitWidth + Theme.widgetPadding * 2
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: Theme.surface0

        // 滚轮调节音量（与 SketchyBar 一致）
        MouseArea {
            anchors.fill: parent
            // 点击切换静音
            onClicked: root.toggleMute()

            onWheel: (wheel) => {
                if (wheel.angleDelta.y > 0) {
                    root.setVolume(5)
                } else {
                    root.setVolume(-5)
                }
            }
        }

        Row {
            id: volRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                // 动态音量图标（与 SketchyBar 一致）
                text: {
                    if (root.muted) return " "
                    if (root.volume >= 66) return " "
                    if (root.volume >= 33) return " "
                    return " "
                }
                color: root.muted ? Theme.overlay0 : Theme.peach
                font.family: Theme.iconFont
                font.pixelSize: Theme.fontSize

                Behavior on color {
                    ColorAnimation { duration: Theme.animationDurationFast }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.muted ? "静音" : root.volume + "%"
                color: root.muted ? Theme.overlay0 : Theme.peach
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize

                Behavior on color {
                    ColorAnimation { duration: Theme.animationDurationFast }
                }
            }
        }
    }
}
