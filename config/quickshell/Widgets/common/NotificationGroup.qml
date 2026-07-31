import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.Common
import qs.Services

// Notification group card — groups notifications by app.
// Android-style: collapsed shows latest, expanded shows all.
// Drag-to-dismiss works when collapsed (dismisses entire group).
MouseArea {
    id: root
    property var notificationGroup
    property var notifications: notificationGroup ? (notificationGroup.notifications || []) : []
    property int notificationCount: notifications.length
    property bool multipleNotifications: notificationCount > 1
    property bool expanded: false
    property bool popup: false
    property real padding: 10
    implicitHeight: background.implicitHeight

    property real dragConfirmThreshold: 70
    property real dismissOvershoot: 20
    property var qmlParent: root?.parent?.parent
    property var parentDragIndex: qmlParent?.dragIndex
    property var parentDragDistance: qmlParent?.dragDistance
    property var dragIndexDiff: Math.abs((parentDragIndex ?? -1) - (index ?? 0))
    property real xOffset: dragIndexDiff === 0 ? (parentDragDistance ?? 0)
        : Math.abs(parentDragDistance ?? 0) > dragConfirmThreshold ? 0
        : dragIndexDiff === 1 ? ((parentDragDistance ?? 0) * 0.3)
        : dragIndexDiff === 2 ? ((parentDragDistance ?? 0) * 0.1) : 0

    function destroyWithAnimation(left) {
        if (left === undefined) left = false;
        if (root.qmlParent) root.qmlParent.resetDrag();
        background.anchors.leftMargin = background.anchors.leftMargin;
        destroyAnimation.left = left;
        destroyAnimation.running = true;
    }

    hoverEnabled: true
    onContainsMouseChanged: {
        if (!root.popup) return;
        if (root.containsMouse) {
            root.notifications.forEach(function(notif) {
                NotificationManager.cancelTimeout(notif.notificationId);
            });
        } else {
            root.notifications.forEach(function(notif) {
                NotificationManager.timeoutNotification(notif.notificationId);
            });
        }
    }

    SequentialAnimation {
        id: destroyAnimation
        property bool left: true
        running: false

        NumberAnimation {
            target: background.anchors
            property: "leftMargin"
            to: (root.width + root.dismissOvershoot) * (destroyAnimation.left ? -1 : 1)
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
        onFinished: {
            root.notifications.forEach(function(notif) {
                Qt.callLater(function() {
                    NotificationManager.discardNotification(notif.notificationId);
                });
            });
        }
    }

    function toggleExpanded() {
        if (expanded) implicitHeightAnim.enabled = true;
        else implicitHeightAnim.enabled = false;
        root.expanded = !root.expanded;
    }

    DragManager {
        id: dragManager
        anchors.fill: parent
        interactive: !expanded
        automaticallyReset: false
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onPressed: (event) => {
            if (event.button === Qt.RightButton)
                root.toggleExpanded();
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton)
                root.destroyWithAnimation();
        }

        onDraggingChanged: () => {
            if (dragManager.drag.active) {
                root.qmlParent.dragIndex = root.index ?? root.parent.children.indexOf(root);
            }
        }

        onDragDiffXChanged: () => {
            root.qmlParent.dragDistance = dragManager.dragDiffX;
        }

        onDragReleased: (diffX, diffY) => {
            if (Math.abs(diffX) > root.dragConfirmThreshold)
                root.destroyWithAnimation(diffX < 0);
            else
                dragManager.resetDrag();
        }
    }

    // Shadow for popup mode
    Loader {
        active: popup
        anchors.fill: background
        z: -1
        sourceComponent: StyledRectangularShadow {
            target: background
        }
    }

    // Background
    Rectangle {
        id: background
        anchors.left: parent.left
        width: parent.width
        color: popup
            ? Appearance.colors.colBackgroundSurfaceContainer
            : Appearance.colors.colLayer2
        radius: Appearance.rounding.normal
        anchors.leftMargin: root.xOffset

        Behavior on anchors.leftMargin {
            enabled: !dragManager.drag.active
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        clip: true
        implicitHeight: root.expanded
            ? row.implicitHeight + padding * 2
            : Math.min(80, row.implicitHeight + padding * 2)

        Behavior on implicitHeight {
            id: implicitHeightAnim
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        RowLayout {
            id: row
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.padding
            spacing: 10

            // App icon
            NotificationAppIcon {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: false
                image: root.multipleNotifications
                    ? ""
                    : (notificationGroup && notificationGroup.notifications
                        ? (notificationGroup.notifications[0]
                            ? (notificationGroup.notifications[0].image || "") : "")
                        : "")
                appIcon: root.notificationGroup ? (root.notificationGroup.appIcon || "") : ""
                summary: root.notificationGroup && root.notificationGroup.notifications
                    ? (root.notificationGroup.notifications[root.notificationCount - 1]
                        ? (root.notificationGroup.notifications[root.notificationCount - 1].summary || "") : "")
                    : ""
                urgency: root.notifications.some(function(n) {
                    return n && (n.urgency === "Critical" || n.urgency === "2");
                }) ? 2 : 0
            }

            // Content column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: expanded
                    ? (root.multipleNotifications
                        ? ((root.notificationGroup
                            && root.notificationGroup.notifications
                            && root.notificationGroup.notifications[root.notificationCount - 1]
                            && root.notificationGroup.notifications[root.notificationCount - 1].image !== "")
                            ? 35 : 5)
                        : 0)
                    : 0

                Behavior on spacing {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                // Top row: app name (or summary) + time + expand button
                Item {
                    id: topRow
                    Layout.fillWidth: true
                    property real fontSize: Appearance.font.pixelSize.smaller
                    property bool showAppName: root.multipleNotifications
                    implicitHeight: Math.max(topTextRow.implicitHeight, expandButton.implicitHeight)

                    RowLayout {
                        id: topTextRow
                        anchors.left: parent.left
                        anchors.right: expandButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            id: appName
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            font.family: Sizes.fontFamily
                            font.pixelSize: topRow.showAppName
                                ? topRow.fontSize
                                : Appearance.font.pixelSize.small
                            verticalAlignment: Text.AlignVCenter
                            text: topRow.showAppName
                                ? (root.notificationGroup ? (root.notificationGroup.appName || "") : "")
                                : (root.notificationGroup && root.notificationGroup.notifications
                                    ? (root.notificationGroup.notifications[0]
                                        ? (root.notificationGroup.notifications[0].summary || "") : "")
                                    : "")
                            color: topRow.showAppName
                                ? Appearance.colors.colSubtext
                                : Appearance.colors.colOnLayer2
                        }
                        Text {
                            id: timeText
                            Layout.rightMargin: 10
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            font.family: Sizes.fontFamily
                            font.pixelSize: topRow.fontSize
                            text: NotificationUtils.getFriendlyNotifTimeString(
                                root.notificationGroup ? root.notificationGroup.time : 0)
                            color: Appearance.colors.colSubtext
                        }
                    }
                    NotificationGroupExpandButton {
                        id: expandButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        count: root.notificationCount
                        expanded: root.expanded
                        fontSize: topRow.fontSize
                        onClicked: { root.toggleExpanded(); }
                        altAction: function() { root.toggleExpanded(); }
                    }
                }

                // Body list (expanded shows all, collapsed shows last 2)
                ListView {
                    id: notificationsColumn
                    implicitHeight: contentHeight
                    Layout.fillWidth: true
                    spacing: expanded ? 5 : 3
                    clip: false
                    interactive: false

                    Behavior on spacing {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    model: {
                        var reversed = root.notifications.slice().reverse();
                        return root.expanded
                            ? reversed
                            : reversed.slice(0, 2);
                    }

                    delegate: NotificationItem {
                        required property int index
                        required property var modelData
                        notificationObject: modelData
                        expanded: root.expanded
                        onlyNotification: (root.notificationCount === 1)
                        opacity: (!root.expanded && index === 1 && root.notificationCount > 2) ? 0.5 : 1
                        visible: root.expanded || (index < 2)
                        anchors.left: parent ? parent.left : undefined
                        anchors.right: parent ? parent.right : undefined
                    }
                }
            }
        }
    }
}
