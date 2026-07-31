import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

// Notification popup — overlay panel on screen right side.
// Shows when popup notifications are available and screen is unlocked.
Scope {
    id: notificationPopup

    PanelWindow {
        id: root
        visible: NotificationManager.popupList
            ? (NotificationManager.popupList.length > 0)
            : false

        screen: Quickshell.screens[0] ?? null

        WlrLayershell.namespace: "qs-notification-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0

        anchors {
            top: true
            right: true
            bottom: true
        }

        mask: Region {
            item: listview.contentItem
        }

        color: "transparent"
        implicitWidth: Appearance.sizes.notificationPopupWidth

        NotificationListView {
            id: listview
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                rightMargin: 4
                topMargin: 4
            }
            implicitWidth: parent.width - Appearance.sizes.elevationMargin * 2
            popup: true
        }
    }
}
