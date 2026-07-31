import QtQuick
import QtQuick.Layouts
import qs.Common

// Expand/collapse button for a notification group.
// Shows count badge and a chevron that rotates when expanded.
RippleButton {
    id: root
    required property int count
    required property bool expanded
    property real fontSize: Appearance.font.pixelSize.small
    property real iconSize: Appearance.font.pixelSize.normal

    implicitHeight: fontSize + 8
    implicitWidth: Math.max(contentItem.implicitWidth + 10, 30)
    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false

    buttonRadius: Appearance.rounding.full
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.colors.colLayer2Active

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 3

            Text {
                Layout.leftMargin: 4
                visible: root.count > 1
                text: String(root.count)
                font.family: Sizes.fontFamily
                font.pixelSize: root.fontSize
                color: Appearance.colors.colOnLayer2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: "keyboard_arrow_down"
                font.family: "Material Symbols Outlined"
                font.pixelSize: root.iconSize
                color: Appearance.colors.colOnLayer2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }
        }
    }
}
