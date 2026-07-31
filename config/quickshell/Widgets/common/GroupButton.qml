import QtQuick
import QtQuick.Layouts
import qs.Common

// Button for use inside a ButtonGroup (notification status bar row).
RippleButton {
    id: button
    property string buttonIcon: ""
    property string buttonText: ""
    property color colText: toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1

    property real baseHeight: 36
    property real baseWidth: contentItem.implicitWidth + 46
    property real clickedWidth: baseWidth + 6

    implicitHeight: baseHeight
    implicitWidth: baseWidth

    buttonRadius: baseHeight / 2
    buttonRadiusPressed: Appearance.rounding?.small ?? 4

    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover ?? Appearance.colors.colLayer2
    colBackgroundToggled: Appearance.colors.colPrimary
    colBackgroundToggledHover: Appearance.colors.colPrimaryHover ?? Appearance.colors.colPrimary
    colRipple: Appearance.colors.colLayer2Active ?? Appearance.colors.colLayer2
    colRippleToggled: Appearance.colors.colPrimaryActive ?? Appearance.colors.colPrimary

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
                font.pixelSize: Appearance.font?.pixelSize?.huge ?? 24
                color: button.colText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: buttonText !== ""
                text: buttonText
                font.family: Sizes.fontFamily
                font.pixelSize: Appearance.font?.pixelSize?.small ?? 14
                color: button.colText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
