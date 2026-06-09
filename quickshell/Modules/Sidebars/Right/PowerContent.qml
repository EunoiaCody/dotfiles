import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets.common

// Power menu panel — shown in the RightSidebar when qsView === "power".
// Compact layout: items anchor to the top of the panel instead of
// filling the entire sidebar, since there are only 4 short actions.
WidgetPanel {
    id: root

    title: "电源"
    icon: "power_settings_new"
    closeAction: () => WidgetState.qsOpen = false

    // Dynamic: itemsColumn.implicitHeight (sum of items + spacings + top margin)
    // + the WidgetPanel's own padding + header. Bound dynamically so it
    // stays in sync if items change.
    contentImplicitHeight: itemsColumn.implicitHeight + 40 + 40 + 16

    readonly property var actions: [
        { label: "锁定", icon: "lock",        cmd: ["loginctl", "lock-session"],        isRed: false },
        { label: "注销", icon: "logout",      cmd: ["niri", "msg", "action", "quit"],   isRed: false },
        { label: "重启", icon: "restart_alt", cmd: ["systemctl", "reboot"],              isRed: false },
        { label: "关机", icon: "power_off",   cmd: ["systemctl", "poweroff"],            isRed: true  }
    ]

    // Anchor the item list to the top of the content area. The rest of
    // the 640px sidebar stays transparent (WidgetPanel itself is
    // transparent, so no visible empty block — only the 4 items take
    // up vertical space). Use an Item with explicit anchors because the
    // parent ColumnLayout's fillHeight on the contentLayout interferes
    // with Layout.alignment: AlignTop on a child ColumnLayout.
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
            id: itemsColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 4
            }
            spacing: 4

            Repeater {
                model: root.actions

                Rectangle {
                    id: menuItem
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 10
                    color: itemMouse.containsMouse
                        ? (modelData.isRed ? Appearance.colors.colError : Appearance.colors.colLayer1)
                        : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Appearance.animation.expressiveEffects.duration; easing.type: Appearance.animation.expressiveEffects.type; easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 14
                        }
                        spacing: 14

                        Text {
                            text: menuItem.modelData.icon
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: itemMouse.containsMouse && menuItem.modelData.isRed
                                ? Appearance.colors.colOnError
                                : Appearance.colors.colOnLayer0
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: menuItem.modelData.label
                            font.pixelSize: 14
                            font.family: Sizes.fontFamily
                            color: itemMouse.containsMouse && menuItem.modelData.isRed
                                ? Appearance.colors.colOnError
                                : Appearance.colors.colOnLayer0
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            WidgetState.qsOpen = false;
                            Quickshell.execDetached(menuItem.modelData.cmd[0], menuItem.modelData.cmd.slice(1));
                        }
                    }
                }
            }
        }
    }
}
