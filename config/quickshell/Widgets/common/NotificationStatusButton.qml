import QtQuick
import QtQuick.Layouts
import qs.Common

// Notification status bar button — used in the sidebar bottom row.
// For mute-toggle and clear-all.
GroupButton {
    id: button
    property string buttonIcon: ""
    property string buttonText: ""
    property color colText: toggled
        ? Appearance.m3colors.m3onPrimary
        : Appearance.colors.colOnLayer1

    baseHeight: 36
    baseWidth: contentItem.implicitWidth + 46
    clickedWidth: baseWidth + 6

    buttonRadius: baseHeight / 2
    buttonRadiusPressed: Appearance.rounding.small
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colBackgroundToggled: Appearance.colors.colPrimary
    colBackgroundToggledHover: Appearance.colors.colPrimaryHover
    colRipple: Appearance.colors.colLayer2Active
    colRippleToggled: Appearance.colors.colPrimaryActive

    contentItem: Item {
        id: contentItem
        anchors.fill: parent
        implicitWidth: contentRowLayout.implicitWidth
        implicitHeight: contentRowLayout.implicitHeight

        RowLayout {
            id: contentRowLayout
            anchors.centerIn: parent
            spacing: 5

            Text {
                visible: buttonIcon !== ""
                text: buttonIcon
                font.family: "Material Symbols Outlined"
                font.pixelSize: Appearance.font.pixelSize.huge
                color: button.colText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                visible: buttonText !== ""
                text: buttonText
                font.family: Sizes.fontFamily
                font.pixelSize: Appearance.font.pixelSize.small
                color: button.colText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
