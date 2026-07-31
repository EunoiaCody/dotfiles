import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Notifications
import qs.Common
import qs.Services

// Single notification item — inline (collapsed) or expanded view.
// Supports expand/collapse, drag-to-dismiss (when expanded), action buttons, copy.
Item {
    id: root
    property var notificationObject
    property bool expanded: false
    property bool onlyNotification: false
    property real fontSize: Appearance.font.pixelSize.small
    property real padding: onlyNotification ? 0 : 8
    property real summaryElideRatio: 0.85

    property real dragConfirmThreshold: 70
    property real dismissOvershoot: notificationIcon.implicitWidth + 20
    property var qmlParent: root?.parent?.parent
    property var parentDragIndex: qmlParent?.dragIndex ?? -1
    property var parentDragDistance: qmlParent?.dragDistance ?? 0
    property var dragIndexDiff: Math.abs(parentDragIndex - index)
    property real xOffset: dragIndexDiff === 0 ? parentDragDistance
        : Math.abs(parentDragDistance) > dragConfirmThreshold ? 0
        : dragIndexDiff === 1 ? (parentDragDistance * 0.3)
        : dragIndexDiff === 2 ? (parentDragDistance * 0.1) : 0

    implicitHeight: background.implicitHeight

    function destroyWithAnimation(left) {
        if (left === undefined) left = false;
        root.qmlParent.resetDrag();
        background.anchors.leftMargin = background.anchors.leftMargin;
        destroyAnimation.left = left;
        destroyAnimation.running = true;
    }

    TextMetrics {
        id: summaryTextMetrics
        font.pixelSize: root.fontSize
        text: root.notificationObject ? (root.notificationObject.summary || "") : ""
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
            if (notificationObject) {
                NotificationManager.discardNotification(notificationObject.notificationId);
            }
        }
    }

    DragManager {
        id: dragManager
        anchors.fill: root
        anchors.leftMargin: root.expanded ? -notificationIcon.implicitWidth : 0
        interactive: expanded
        automaticallyReset: false
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                root.destroyWithAnimation();
            }
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

    // Icon shown when expanded and has image
    NotificationAppIcon {
        id: notificationIcon
        opacity: (!onlyNotification && notificationObject
            && notificationObject.image !== "" && expanded) ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        image: notificationObject ? (notificationObject.image || "") : ""
        anchors.right: background.left
        anchors.top: background.top
        anchors.rightMargin: 10
    }

    // Main background
    Rectangle {
        id: background
        width: parent.width
        anchors.left: parent.left
        radius: Appearance.rounding.small
        anchors.leftMargin: root.xOffset

        Behavior on anchors.leftMargin {
            enabled: !dragManager.drag.active
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        color: (expanded && !onlyNotification)
            ? ((notificationObject && (notificationObject.urgency === "Critical" || notificationObject.urgency === "2"))
                ? Appearance.mix(Appearance.colors.colSecondaryContainer,
                    Appearance.colors.colLayer2, 0.35)
                : Appearance.colors.colLayer3)
            : Appearance.transparentize(Appearance.colors.colLayer3, 1.0)

        implicitHeight: expanded
            ? (contentColumn.implicitHeight + padding * 2)
            : summaryRow.implicitHeight

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: expanded ? root.padding : 0
            spacing: 3

            Behavior on anchors.margins {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            // Summary + collapsed body row
            RowLayout {
                id: summaryRow
                visible: !root.onlyNotification || !root.expanded
                Layout.fillWidth: true
                implicitHeight: summaryText.implicitHeight

                Text {
                    id: summaryText
                    Layout.fillWidth: summaryTextMetrics.width >= root.width * root.summaryElideRatio
                    visible: !root.onlyNotification
                    font.family: Sizes.fontFamily
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colOnLayer3
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    text: root.notificationObject ? (root.notificationObject.summary || "") : ""
                }
                Text {
                    opacity: !root.expanded ? 1 : 0
                    visible: opacity > 0
                    Layout.fillWidth: true
                    font.family: Sizes.fontFamily
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    maximumLineCount: 1
                    verticalAlignment: Text.AlignVCenter
                    textFormat: Text.StyledText
                    text: root.notificationObject
                        ? NotificationUtils.processNotificationBody(
                            notificationObject.body || "",
                            notificationObject.appName || notificationObject.summary || ""
                        ).replace(/\n/g, "<br/>")
                        : ""

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }
                }
            }

            // Expanded content
            ColumnLayout {
                id: expandedContentColumn
                Layout.fillWidth: true
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                // Full body text
                Text {
                    id: notificationBodyText
                    Layout.fillWidth: true
                    font.family: Sizes.fontFamily
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                    textFormat: Text.RichText
                    text: root.notificationObject
                        ? ("<style>img{max-width:" + expandedContentColumn.width + "px;}</style>"
                            + NotificationUtils.processNotificationBody(
                                notificationObject.body || "",
                                notificationObject.appName || notificationObject.summary || ""
                            ).replace(/\n/g, "<br/>"))
                        : ""

                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link);
                    }

                    HoverHandler {
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
                    }
                }

                // Action buttons row
                Item {
                    Layout.fillWidth: true
                    implicitWidth: actionsFlickable.implicitWidth
                    implicitHeight: actionsFlickable.implicitHeight

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: actionsFlickable.width
                            height: actionsFlickable.height
                            radius: Appearance.rounding.small
                        }
                    }

                    ScrollEdgeFade {
                        target: actionsFlickable
                        vertical: false
                    }

                    Flickable {
                        id: actionsFlickable
                        anchors.fill: parent
                        implicitHeight: actionRowLayout.implicitHeight
                        contentWidth: actionRowLayout.implicitWidth
                        interactive: contentWidth > width
                        clip: true

                        RowLayout {
                            id: actionRowLayout
                            Layout.alignment: Qt.AlignBottom

                            // Close button
                            NotificationActionButton {
                                Layout.fillWidth: true
                                buttonText: "Close"
                                urgency: notificationObject ? notificationObject.urgency : "normal"
                                implicitWidth: (notificationObject
                                    && (!notificationObject.actions || notificationObject.actions.length === 0))
                                    ? ((actionsFlickable.width - actionRowLayout.spacing) / 2)
                                    : (implicitHeight + leftPadding + rightPadding)

                                onClicked: {
                                    root.destroyWithAnimation();
                                }

                                contentItem: Text {
                                    text: "close"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: Appearance.font.pixelSize.larger
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: (notificationObject
                                        && (notificationObject.urgency === "Critical" || notificationObject.urgency === "2"))
                                        ? Appearance.m3colors.m3onSurfaceVariant
                                        : Appearance.m3colors.m3onSurface
                                }
                            }

                            // Action buttons from notification
                            Repeater {
                                id: actionRepeater
                                model: notificationObject ? (notificationObject.actions || []) : []
                                NotificationActionButton {
                                    id: notifAction
                                    required property var modelData
                                    Layout.fillWidth: true
                                    buttonText: modelData.text || ""
                                    urgency: notificationObject ? notificationObject.urgency : "normal"
                                    onClicked: {
                                        NotificationManager.attemptInvokeAction(
                                            notificationObject.notificationId,
                                            modelData.identifier);
                                    }
                                }
                            }

                            // Copy button
                            NotificationActionButton {
                                Layout.fillWidth: true
                                urgency: notificationObject
                                    ? notificationObject.urgency : "normal"
                                implicitWidth: (notificationObject
                                    && (!notificationObject.actions || notificationObject.actions.length === 0))
                                    ? ((actionsFlickable.width - actionRowLayout.spacing) / 2)
                                    : (implicitHeight + leftPadding + rightPadding)

                                onClicked: {
                                    if (notificationObject) {
                                        Quickshell.clipboardText = notificationObject.body || "";
                                        copyIcon.text = "inventory";
                                        copyIconTimer.restart();
                                    }
                                }

                                Timer {
                                    id: copyIconTimer
                                    interval: 1500
                                    repeat: false
                                    onTriggered: { copyIcon.text = "content_copy"; }
                                }

                                contentItem: Text {
                                    id: copyIcon
                                    text: "content_copy"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: Appearance.font.pixelSize.larger
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: (notificationObject
                                        && (notificationObject.urgency === "Critical" || notificationObject.urgency === "2"))
                                        ? Appearance.m3colors.m3onSurfaceVariant
                                        : Appearance.m3colors.m3onSurface
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
