import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets.common

// Notifications panel — grouped Android-style notification list
// in the unified RightSidebar.
WidgetPanel {
    id: root

    title: "通知"
    icon: "notifications"
    closeAction: function() { WidgetState.qsOpen = false; }

    contentImplicitHeight: 640

    readonly property int count: NotificationManager.list ? NotificationManager.list.length : 0

    property bool isActive: WidgetState.qsOpen && WidgetState.qsView === "notifications"

    onIsActiveChanged: {
        if (isActive)
            NotificationManager.markAllRead();
    }

    // Header tools: DnD toggle + Clear All
    headerTools: RowLayout {
        spacing: 14

        // Do-Not-Disturb toggle switch
        Item {
            id: dndSwitch
            implicitWidth: 44
            implicitHeight: 24
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: UiPreferences.dndEnabled ? Appearance.colors.colPrimary : "transparent"
                border.width: UiPreferences.dndEnabled ? 0 : 2
                border.color: Appearance.colors.colOutline
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.width { NumberAnimation { duration: 200 } }
            }

            Rectangle {
                width: UiPreferences.dndEnabled ? 16 : 12
                height: UiPreferences.dndEnabled ? 16 : 12
                radius: width / 2
                x: UiPreferences.dndEnabled ? parent.width - width - 4 : 6
                anchors.verticalCenter: parent.verticalCenter
                color: UiPreferences.dndEnabled
                    ? Appearance.colors.colOnPrimary
                    : Appearance.colors.colOutline
                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: UiPreferences.setDndEnabled(!UiPreferences.dndEnabled)
            }
        }

        // Clear All button
        Text {
            text: "delete_sweep"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 20
            color: root.count > 0
                ? Appearance.colors.colOnLayer1
                : Qt.rgba(
                    Appearance.colors.colOnLayer1.r,
                    Appearance.colors.colOnLayer1.g,
                    Appearance.colors.colOnLayer1.b,
                    0.35)
            opacity: clearMouse.containsMouse ? 0.7 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                cursorShape: root.count > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: root.count > 0
                onClicked: {
                    NotificationManager.discardAllNotifications();
                }
            }
        }
    }

    // Empty state placeholder
    PagePlaceholder {
        shown: NotificationManager.list ? (NotificationManager.list.length === 0) : true
        icon: UiPreferences.dndEnabled ? "notifications_paused" : "notifications_active"
        description: UiPreferences.dndEnabled ? "勿扰模式已开启" : "暂无通知"
        descriptionHorizontalAlignment: Text.AlignHCenter
    }

    // Grouped notification list (sidebar mode)
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.count > 0

        NotificationListView {
            id: listview
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: statusRow.top
            anchors.bottomMargin: 5

            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: listview.width
                    height: listview.height
                    radius: Appearance.rounding.normal
                }
            }

            popup: false
        }

        // Bottom status row: mute + count + clear
        ButtonGroup {
            id: statusRow
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            NotificationStatusButton {
                Layout.fillWidth: false
                buttonIcon: "notifications_paused"
                toggled: NotificationManager.silent
                onClicked: function() {
                    NotificationManager.setSilent(!NotificationManager.silent);
                }
            }
            NotificationStatusButton {
                enabled: false
                Layout.fillWidth: true
                buttonText: root.count + " 条通知"
            }
            NotificationStatusButton {
                Layout.fillWidth: false
                buttonIcon: "delete_sweep"
                onClicked: function() {
                    NotificationManager.discardAllNotifications();
                }
            }
        }
    }
}
