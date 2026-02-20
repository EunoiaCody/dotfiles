// ============================================================
// 内存使用率组件
// 从 SketchyBar ram.lua 迁移
// 通过读取 /proc/meminfo 获取内存信息
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    implicitWidth: memBackground.width
    implicitHeight: Theme.barHeight

    property real memoryUsedGiB: 0
    property real memoryTotalGiB: 0
    property real memoryUsagePercent: 0

    // -------------------- 定时更新 --------------------
    Timer {
        interval: Theme.systemStatsInterval
        running: true
        repeat: true
        onTriggered: memProcess.running = true
    }

    Component.onCompleted: memProcess.running = true

    // -------------------- 读取内存数据 --------------------
    Process {
        id: memProcess
        command: ["sh", "-c", "awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {printf \"%d %d\", total, avail}' /proc/meminfo"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length >= 2) {
                    const totalKB = parseInt(parts[0])
                    const availKB = parseInt(parts[1])
                    if (totalKB > 0 && availKB >= 0) {
                        const usedKB = totalKB - availKB
                        root.memoryTotalGiB = totalKB / 1024 / 1024
                        root.memoryUsedGiB = usedKB / 1024 / 1024
                        root.memoryUsagePercent = (usedKB / totalKB) * 100
                    }
                }
            }
        }
    }

    // -------------------- 显示 --------------------
    Rectangle {
        id: memBackground
        width: memText.implicitWidth + Theme.widgetPadding * 2
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: Theme.surface0

        Text {
            id: memText
            anchors.centerIn: parent
            // Nerd Font 内存图标 + 使用率（与 SketchyBar 格式一致）
            text: "  " + root.memoryUsagePercent.toFixed(0) + "%"
            // 颜色随使用率变化（参考 Quickshell 标准写法）
            color: {
                if (root.memoryUsagePercent >= 85) return Theme.red
                if (root.memoryUsagePercent >= 60) return Theme.yellow
                return Theme.mauve
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize

            Behavior on color {
                ColorAnimation { duration: Theme.animationDuration }
            }
        }
    }
}
