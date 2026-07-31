import QtQuick
import QtQuick.Layouts
import qs.Common

// Empty state placeholder shown when a list/page has no content.
Item {
    id: root
    property bool shown: true
    property string icon: "notifications_active"
    property string description: "Nothing"
    property int descriptionHorizontalAlignment: Text.AlignHCenter
    property int shape: 3  // MaterialShape.Shape.Ghostish equivalent

    visible: shown
    anchors.fill: parent

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 14

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.family: "Material Symbols Outlined"
            font.pixelSize: 72
            color: Appearance.colors.colOutlineVariant
            opacity: 0.5
        }

        Text {
            Layout.alignment: {
                switch (root.descriptionHorizontalAlignment) {
                    case Text.AlignHCenter: return Qt.AlignHCenter;
                    case Text.AlignLeft: return Qt.AlignLeft;
                    case Text.AlignRight: return Qt.AlignRight;
                    default: return Qt.AlignHCenter;
                }
            }
            text: root.description
            color: Appearance.colors.colOutlineVariant
            font.family: Sizes.fontFamily
            font.pixelSize: 18
            font.weight: Font.Medium
            horizontalAlignment: root.descriptionHorizontalAlignment
        }
    }
}
