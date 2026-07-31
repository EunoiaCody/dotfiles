import QtQuick
import qs.Common
import qs.Services

// Notification list container — scrollable list of grouped notifications.
// popup: true → overlay popup mode (shows popupAppNameList)
// popup: false → sidebar mode (shows all appNameList)
StyledListView {
    id: root
    property bool popup: false

    spacing: 3

    model: root.popup
        ? (NotificationManager.popupAppNameList || [])
        : (NotificationManager.appNameList || [])

    delegate: NotificationGroup {
        required property int index
        required property var modelData
        popup: root.popup
        width: ListView.view ? ListView.view.width : 0
        notificationGroup: root.popup
            ? (NotificationManager.popupGroupsByAppName
                ? (NotificationManager.popupGroupsByAppName[modelData] || null)
                : null)
            : (NotificationManager.groupsByAppName
                ? (NotificationManager.groupsByAppName[modelData] || null)
                : null)
    }
}
