// ============================================================
// CPU 使用率组件
// 通过读取 /proc/stat 计算 CPU 使用率
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    implicitWidth: cpuBackground.width
    implicitHeight: Theme.barHeight

    property real cpuUsagePercent: 0
    property real prevTotal: 0
    property real prevIdle: 0

    // -------------------- 定时更新 --------------------
    Timer {
        interval: Theme.systemStatsInterval
        running: true
        repeat: true
        onTriggered: cpuProcess.running = true
    }

    Component.onCompleted: cpuProcess.running = true

    // -------------------- 读取 CPU 数据 --------------------
    Process {
        id: cpuProcess
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length < 5) return

                const user = parseInt(parts[1]) || 0
                const nice = parseInt(parts[2]) || 0
                const system = parseInt(parts[3]) || 0
                const idle = parseInt(parts[4]) || 0
                const iowait = parseInt(parts[5]) || 0
                const irq = parseInt(parts[6]) || 0
                const softirq = parseInt(parts[7]) || 0
                const steal = parseInt(parts[8]) || 0

                const total = user + nice + system + idle + iowait + irq + softirq + steal
                const idleTotal = idle + iowait

                if (root.prevTotal > 0) {
                    const deltaTotal = total - root.prevTotal
                    const deltaIdle = idleTotal - root.prevIdle
                    if (deltaTotal > 0) {
                        root.cpuUsagePercent = ((deltaTotal - deltaIdle) / deltaTotal) * 100
                    }
                }

                root.prevTotal = total
                root.prevIdle = idleTotal
            }
        }
    }

    // -------------------- 显示 --------------------
    Rectangle {
        id: cpuBackground
        width: cpuText.implicitWidth + Theme.widgetPadding * 2
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: Theme.surface0

        Text {
            id: cpuText
            anchors.centerIn: parent
            // Nerd Font CPU 图标
            text: "  " + root.cpuUsagePercent.toFixed(0) + "%"
            // 颜色随使用率变化（参考 Quickshell 标准写法）
            color: {
                if (root.cpuUsagePercent >= 80) return Theme.red
                if (root.cpuUsagePercent >= 50) return Theme.yellow
                return Theme.sky
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize

            Behavior on color {
                ColorAnimation { duration: Theme.animationDuration }
            }
        }
    }
}
