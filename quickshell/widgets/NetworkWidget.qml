// ============================================================
// 网络状态组件
// 从 SketchyBar network.lua 迁移
// 显示网络连接状态和 IP 地址
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    implicitWidth: netBackground.width
    implicitHeight: Theme.barHeight

    property string networkName: ""
    property string ipAddress: ""
    property bool connected: false
    // WiFi / 有线 / 断开
    property string connectionType: "disconnected"

    // -------------------- 定时更新 --------------------
    Timer {
        interval: Theme.networkInterval
        running: true
        repeat: true
        onTriggered: networkProcess.running = true
    }

    Component.onCompleted: networkProcess.running = true

    // -------------------- 检测网络状态 --------------------
    property string netBuffer: ""

    Process {
        id: networkProcess
        command: ["sh", "-c", "ip -j route get 1.1.1.1 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => {
                root.netBuffer += data
            }
        }
        onExited: (exitCode) => {
            if (exitCode === 0 && root.netBuffer.trim().length > 0) {
                try {
                    const parsed = JSON.parse(root.netBuffer)
                    if (parsed && parsed.length > 0) {
                        const route = parsed[0]
                        root.ipAddress = route.prefsrc || ""
                        root.connected = true

                        // 检测连接类型
                        const dev = route.dev || ""
                        if (dev.startsWith("wl")) {
                            root.connectionType = "wifi"
                            wifiNameProcess.running = true
                        } else {
                            root.connectionType = "ethernet"
                            root.networkName = dev
                        }
                    } else {
                        setDisconnected()
                    }
                } catch (e) {
                    setDisconnected()
                }
            } else {
                setDisconnected()
            }
            root.netBuffer = ""
        }
    }

    function setDisconnected() {
        root.connected = false
        root.connectionType = "disconnected"
        root.networkName = ""
        root.ipAddress = ""
    }

    // -------------------- 获取 WiFi 名称 --------------------
    // 使用 nmcli 获取当前 WiFi 连接名称（比 iwctl 管道更简洁可靠）
    Process {
        id: wifiNameProcess
        command: ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"]
        stdout: SplitParser {
            onRead: data => {
                // 输出格式: "yes:MyWiFi" 或 "no:OtherWiFi"
                const line = data.trim()
                if (line.startsWith("yes:")) {
                    root.networkName = line.substring(4)
                }
            }
        }
    }

    // -------------------- 显示 --------------------
    Rectangle {
        id: netBackground
        width: netRow.implicitWidth + Theme.widgetPadding * 2
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: Theme.surface0

        Row {
            id: netRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                // 网络图标（与 SketchyBar 一致）
                text: {
                    if (root.connectionType === "wifi") return " "
                    if (root.connectionType === "ethernet") return "󰈀 "
                    return "󰤭 "
                }
                color: root.connected ? Theme.sapphire : Theme.overlay0
                font.family: Theme.iconFont
                font.pixelSize: Theme.fontSize

                Behavior on color {
                    ColorAnimation { duration: Theme.animationDuration }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!root.connected) return "断开"
                    if (root.networkName) return root.networkName
                    return root.ipAddress
                }
                color: root.connected ? Theme.sapphire : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize

                Behavior on color {
                    ColorAnimation { duration: Theme.animationDuration }
                }
            }
        }
    }
}
