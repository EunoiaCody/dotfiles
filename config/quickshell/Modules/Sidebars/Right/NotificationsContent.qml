import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets.common

// Notifications panel — added to the unified RightSidebar.
// Sits alongside NetworkContent, AudioContent, SettingsContent.
// Toggled via WidgetState.qsView === "notifications" (fixed from the
// NotificationButton bug that used to point at "network").
WidgetPanel {
    id: root

    title: "通知"
    icon: "notifications"
    closeAction: () => WidgetState.qsOpen = false

    contentImplicitHeight: 640

    // Sort notifications newest first; use the full list (not just popups)
    // so the user can see history, not only the active popup set.
    readonly property var sortedList: NotificationManager.list
        .slice()
        .sort((a, b) => b.time - a.time)
    readonly property int count: sortedList.length

    function iconSourceFor(notif) {
        if (!notif)
            return "";
        if (notif.image && notif.image !== "")
            return Paths.fileUrl(notif.image);
        if (notif.appIcon && notif.appIcon !== "") {
            if (notif.appIcon.startsWith("/") || notif.appIcon.startsWith("file://"))
                return Paths.fileUrl(notif.appIcon);
            return Quickshell.iconPath(notif.appIcon, "image-missing");
        }
        return "";
    }

    function formatTime(timestamp) {
        const date = new Date(Number(timestamp));
        if (isNaN(date.getTime()))
            return "";
        const now = new Date();
        if (date.toDateString() === now.toDateString())
            return Qt.formatTime(date, "HH:mm");
        return Qt.formatDate(date, "MM/dd") + " " + Qt.formatTime(date, "HH:mm");
    }

    property bool isActive: WidgetState.qsOpen && WidgetState.qsView === "notifications"

    onIsActiveChanged: {
        if (isActive)
            NotificationManager.unread = 0;
    }

    // Header tools: DnD toggle + Clear All
    headerTools: RowLayout {
        spacing: 14

        // Do-Not-Disturb switch
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
                x: UiPreferences.dndEnabled
                    ? parent.width - width - 4
                    : 6
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

        // Clear All (only enabled when there's something to clear)
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
                    // Copy because we mutate the underlying list while iterating
                    const ids = root.sortedList.map((n) => n.notificationId);
                    for (let i = 0; i < ids.length; i += 1)
                        NotificationManager.discardNotification(ids[i]);
                }
            }
        }
    }

    // Empty state
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.count === 0
        opacity: root.count === 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 14

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "notifications_off"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 72
                color: Appearance.colors.colOutlineVariant
                opacity: 0.5
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: UiPreferences.dndEnabled ? "勿扰模式已开启" : "暂无通知"
                color: Appearance.colors.colOutlineVariant
                font.family: Sizes.fontFamily
                font.pixelSize: 18
                font.weight: Font.Medium
            }
        }
    }

    // Notification list
    StyledListView {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.count > 0
        clip: true
        spacing: 8
        model: root.sortedList
        interactive: true
        showVerticalScrollBar: false
        smoothWheelEnabled: true

        delegate: Rectangle {
            id: delegateRoot

            required property var modelData

            width: ListView.view ? ListView.view.width : 0
            height: Math.max(76, contentRow.implicitHeight + 16)
            radius: 14
            color: delegateMouse.containsMouse
                ? Appearance.colors.colLayer3
                : Appearance.colors.colLayer2
            Behavior on color { ColorAnimation { duration: 150 } }

            readonly property string iconSource: root.iconSourceFor(modelData)

            RowLayout {
                id: contentRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    Layout.alignment: Qt.AlignTop
                    radius: 12
                    color: Appearance.colors.colLayer4
                    clip: true

                    Image {
                        id: iconImg
                        anchors.fill: parent
                        anchors.margins: delegateRoot.modelData && delegateRoot.modelData.image ? 0 : 8
                        source: delegateRoot.iconSource
                        fillMode: delegateRoot.modelData && delegateRoot.modelData.image
                            ? Image.PreserveAspectCrop
                            : Image.PreserveAspectFit
                        visible: delegateRoot.iconSource !== "" && status !== Image.Error
                        asynchronous: true
                        smooth: true
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "notifications"
                        visible: !iconImg.visible
                        color: Appearance.colors.colOnSurfaceVariant
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: delegateRoot.modelData
                                ? (delegateRoot.modelData.appName || "通知")
                                : ""
                            color: Appearance.colors.colPrimary
                            font.family: Sizes.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: delegateRoot.modelData
                                ? root.formatTime(delegateRoot.modelData.time)
                                : ""
                            color: Appearance.colors.colOnSurfaceVariant
                            font.family: Sizes.fontFamilyMono
                            font.pixelSize: 11
                            opacity: 0.7
                        }
                    }

                    Text {
                        text: delegateRoot.modelData
                            ? (delegateRoot.modelData.summary || "")
                            : ""
                        color: Appearance.colors.colOnSurface
                        font.family: Sizes.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: (delegateRoot.modelData ? delegateRoot.modelData.summary : "") !== ""
                    }

                    Text {
                        text: delegateRoot.modelData
                            ? (delegateRoot.modelData.body || "")
                            : ""
                        color: Appearance.colors.colOnSurfaceVariant
                        font.family: Sizes.fontFamily
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        maximumLineCount: 2
                        opacity: 0.85
                    }
                }

                Item {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        color: closeMouse.containsMouse
                            ? Appearance.colors.colError
                            : Appearance.colors.colOnSurfaceVariant
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 16
                        opacity: closeMouse.containsMouse ? 1 : 0.7
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.discardNotification(
                            delegateRoot.modelData.notificationId)
                    }
                }
            }

            MouseArea {
                id: delegateMouse
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Clicking the row (anywhere except the close button) is
                    // a no-op for now — keep the notification. Future: expand
                    // the body, fire default action, etc.
                }
            }
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.95
                    to: 1
                    duration: 220
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.6
                }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 160
                }
                NumberAnimation {
                    property: "scale"
                    from: 1
                    to: 0.95
                    duration: 160
                }
            }
        }
    }
}
