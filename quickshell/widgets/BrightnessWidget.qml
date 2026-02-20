// ============================================================
// 屏幕亮度组件
// 通过 brightnessctl 获取和控制亮度
// 支持滚轮调节
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    implicitWidth: brightBackground.width
    implicitHeight: Theme.barHeight

    property int brightness: 100
    property int maxBrightness: 100

    // -------------------- 定时更新 --------------------
    Timer {
        interval: Theme.brightnessInterval
        running: true
        repeat: true
        onTriggered: brightnessProcess.running = true
    }

    Component.onCompleted: brightnessProcess.running = true

    // -------------------- 获取亮度 --------------------
    Process {
        id: brightnessProcess
        command: ["sh", "-c", "brightnessctl info 2>/dev/null | awk '/Current brightness/ {gsub(/[^0-9]/, \"\", $NF); print $NF}'"]
        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim())
                if (!isNaN(val)) {
                    root.brightness = val
                }
            }
        }
    }

    // -------------------- 亮度控制 --------------------
    Process {
        id: brightnessSetProcess
        command: []
    }

    function setBrightness(delta) {
        const cmd = delta > 0 ? (delta + "%+") : ((-delta) + "%-")
        brightnessSetProcess.command = ["brightnessctl", "set", cmd]
        brightnessSetProcess.running = true
        brightnessProcess.running = true
    }

    // -------------------- 显示 --------------------
    Rectangle {
        id: brightBackground
        width: brightRow.implicitWidth + Theme.widgetPadding * 2
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: Theme.surface0

        MouseArea {
            anchors.fill: parent
            onWheel: (wheel) => {
                if (wheel.angleDelta.y > 0) {
                    root.setBrightness(5)
                } else {
                    root.setBrightness(-5)
                }
            }
        }

        Row {
            id: brightRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                // 亮度图标
                text: {
                    if (root.brightness >= 75) return " "
                    if (root.brightness >= 50) return " "
                    if (root.brightness >= 25) return " "
                    return " "
                }
                color: Theme.yellow
                font.family: Theme.iconFont
                font.pixelSize: Theme.fontSize
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.brightness + "%"
                color: Theme.yellow
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
