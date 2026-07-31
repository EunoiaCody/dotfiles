import QtQuick
import Quickshell.Services.Notifications
import qs.Common

// Notification action button — based on RippleButton.
RippleButton {
    id: button
    property string buttonText: ""
    property string urgency: "normal"

    implicitHeight: 34
    leftPadding: 15
    rightPadding: 15
    buttonRadius: Appearance.rounding.small

    colBackground: urgency === "Critical" || urgency === "2"
        ? Appearance.colors.colSecondaryContainer
        : Appearance.colors.colLayer4
    colBackgroundHover: urgency === "Critical" || urgency === "2"
        ? Appearance.colors.colSecondaryContainerHover
        : Appearance.colors.colLayer4Hover
    colRipple: urgency === "Critical" || urgency === "2"
        ? Appearance.colors.colSecondaryContainerActive
        : Appearance.colors.colLayer4Active

    contentItem: Text {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: button.buttonText
        font.family: Sizes.fontFamily
        font.pixelSize: Appearance.font.pixelSize.small
        color: button.urgency === "Critical" || button.urgency === "2"
            ? Appearance.m3colors.m3onSurfaceVariant
            : Appearance.m3colors.m3onSurface
    }
}
