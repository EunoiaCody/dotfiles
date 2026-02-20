// ============================================================
// 电池状态组件
// 通过读取 /sys/class/power_supply 获取电池信息
// 低电量警告着色
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    implicitWidth: batBackground.width
    implicitHeight: Theme.barHeight

    property int capacity: 100
    property string status: "Unknown"
    property bool charging: false
    property bool hasBattery: true

    // -------------------- 定时更新 --------------------
    Timer {
        interval: Theme.batteryInterval
        running: true
        repeat: true
        onTriggered: batteryProcess.running = true
    }

    Component.onCompleted: batteryProcess.running = true

    // -------------------- 读取电池数据 --------------------
    Process {
        id: batteryProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status 2>/dev/null || echo 'no_battery'"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (line === "no_battery") {
                    root.hasBattery = false
                    return
                }

                // 第一行是容量，第二行是状态
                const val = parseInt(line)
                if (!isNaN(val)) {
                    root.capacity = val
                } else {
                    root.status = line
                    root.charging = (line === "Charging" || line === "Full")
                }
            }
        }
    }

    // -------------------- 显示 --------------------
    // 如果没有电池则不显示
    visible: hasBattery

    Rectangle {
        id: batBackground
        width: batRow.implicitWidth + Theme.widgetPadding * 2
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: Theme.surface0

        Row {
            id: batRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                // 电池图标
                text: {
                    if (root.charging) return " "
                    if (root.capacity >= 90) return " "
                    if (root.capacity >= 60) return " "
                    if (root.capacity >= 40) return " "
                    if (root.capacity >= 10) return " "
                    return " "
                }
                color: {
                    if (root.charging) return Theme.green
                    if (root.capacity <= 15) return Theme.red
                    if (root.capacity <= 30) return Theme.yellow
                    return Theme.green
                }
                font.family: Theme.iconFont
                font.pixelSize: Theme.fontSize

                Behavior on color {
                    ColorAnimation { duration: Theme.animationDuration }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.capacity + "%"
                color: {
                    if (root.charging) return Theme.green
                    if (root.capacity <= 15) return Theme.red
                    if (root.capacity <= 30) return Theme.yellow
                    return Theme.green
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize

                Behavior on color {
                    ColorAnimation { duration: Theme.animationDuration }
                }
            }
        }
    }
}
