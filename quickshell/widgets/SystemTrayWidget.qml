// ============================================================
// 系统托盘组件
// 使用 Quickshell 内置 SystemTray API
// ============================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import ".."

Item {
    id: root

    implicitWidth: trayRow.implicitWidth + Theme.widgetPadding
    implicitHeight: Theme.barHeight

    // -------------------- 托盘图标行 --------------------
    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: SystemTray.items

            // 单个托盘图标
            Image {
                id: trayIcon

                required property var modelData

                width: 16
                height: 16
                anchors.verticalCenter: parent.verticalCenter

                source: modelData.icon ?? ""
                sourceSize.width: 16
                sourceSize.height: 16

                // 悬停效果
                opacity: trayMouse.containsMouse ? 1.0 : 0.8
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animationDurationFast }
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton) {
                            modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
