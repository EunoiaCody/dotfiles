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
            // 使用 .values 获取托盘项列表（Quickshell ObjectModel API）
            model: SystemTray.items ? SystemTray.items.values : []

            // 单个托盘图标
            Item {
                id: trayItemContainer

                required property var modelData
                required property int index

                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16

                    source: modelData?.icon ?? ""
                    sourceSize.width: 16
                    sourceSize.height: 16
                    smooth: true
                    visible: status === Image.Ready

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

                        onClicked: function(mouse) {
                            if (!modelData) return
                            if (mouse.button === Qt.LeftButton) {
                                modelData.activate()
                            } else if (mouse.button === Qt.MiddleButton) {
                                modelData.secondaryActivate()
                            } else if (mouse.button === Qt.RightButton) {
                                // 右键触发二级操作（通常为上下文菜单）
                                modelData.secondaryActivate()
                            }
                        }
                    }
                }

                // 图标加载失败时的备用文字
                Text {
                    anchors.centerIn: parent
                    text: "?"
                    color: Theme.overlay1
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    visible: trayIcon.status !== Image.Ready
                }
            }
        }
    }
}
