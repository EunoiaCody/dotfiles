import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets.common

// Notification button — opens the notifications panel in the unified
// RightSidebar. The previous version had a bug where it pointed at the
// "network" view (NotificationsContent didn't exist yet). Now that the
// panel is wired in, this routes to the dedicated "notifications" view.
MouseArea {
    id: root

    property var screen: null

    implicitWidth: 20
    implicitHeight: 20
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    property bool hasNotifs: NotificationManager.list.length > 0
    property color iconColor: !hasNotifs
        ? Appearance.colors.colOnLayer0
        : Appearance.colors.colPrimary

    Text {
        anchors.centerIn: parent
        text: "\uf0f3"            // Nerd Font bell
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: root.iconColor
    }

    onClicked: {
        const gpos = root.mapToGlobal(0, 0);
        WidgetState.qsAnchorGlobalX = gpos.x;
        WidgetState.qsAnchorGlobalY = gpos.y;
        WidgetState.qsAnchorWidth = root.width;
        WidgetState.qsAnchorHeight = root.height;
        if (root.screen && root.screen.name)
            WidgetState.qsScreenName = root.screen.name;

        if (WidgetState.qsOpen && WidgetState.qsView === "notifications") {
            WidgetState.qsOpen = false;
        } else {
            WidgetState.qsView = "notifications";
            WidgetState.qsOpen = true;
        }
    }

    PopupToolTip {
        extraVisibleCondition: root.containsMouse
        text: {
            if (UiPreferences.dndEnabled)
                return "勿扰模式开启\n点击查看通知";
            if (NotificationManager.unread > 0)
                return NotificationManager.unread + " 条未读\n点击查看通知";
            return "通知\n点击查看通知";
        }
    }
}
