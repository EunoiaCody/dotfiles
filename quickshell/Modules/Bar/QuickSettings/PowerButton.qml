import QtQuick
import Quickshell
import qs.Common
import qs.Widgets.common

Item {
    id: root

    property var screen: null
    property bool isHovered: mouseArea.containsMouse
    readonly property int buttonSize: 28
    readonly property int hoverButtonSize: 34

    implicitHeight: buttonSize
    implicitWidth: buttonSize

    Rectangle {
        id: background
        anchors.centerIn: parent
        width: root.isHovered ? root.hoverButtonSize : root.buttonSize
        height: width
        radius: height / 2
        color: Appearance.colors.colError

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Text {
            id: icon
            anchors.centerIn: parent
            text: "⏻"
            font.pixelSize: root.isHovered ? 16 : 14
            font.bold: true
            color: Appearance.colors.colOnError
            Behavior on font.pixelSize { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const gpos = root.mapToGlobal(0, 0);
            WidgetState.qsAnchorGlobalX = gpos.x;
            WidgetState.qsAnchorGlobalY = gpos.y;
            WidgetState.qsAnchorWidth = root.width;
            WidgetState.qsAnchorHeight = root.height;
            if (root.screen && root.screen.name)
                WidgetState.qsScreenName = root.screen.name;
            if (WidgetState.qsOpen && WidgetState.qsView === "power") {
                WidgetState.qsOpen = false;
            } else {
                WidgetState.qsView = "power";
                WidgetState.qsOpen = true;
            }
        }
    }

    PopupToolTip {
        extraVisibleCondition: mouseArea.containsMouse
        text: "电源"
    }
}
