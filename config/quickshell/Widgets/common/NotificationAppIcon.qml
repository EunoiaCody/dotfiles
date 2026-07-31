import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Notifications
import qs.Common

// Notification app icon with 3-tier fallback:
// 1. Image (if notification has image)
// 2. App icon (desktop entry)
// 3. Material Symbol (guessed from summary)
MaterialShape {
    id: root
    property string appIcon: ""
    property string summary: ""
    property int urgency: 0  // NotificationUrgency.Normal
    property bool isUrgent: urgency === 2  // NotificationUrgency.Critical
    property string image: ""
    property real materialIconScale: 0.57
    property real appIconScale: 0.8
    property real smallAppIconScale: 0.49
    property real materialIconSize: implicitSize * materialIconScale
    property real appIconSize: implicitSize * appIconScale
    property real smallAppIconSize: implicitSize * smallAppIconScale

    implicitSize: 38

    readonly property var urgentShapes: [
        MaterialShape.Shape.VerySunny,
        MaterialShape.Shape.SoftBurst,
    ]

    shape: isUrgent
        ? urgentShapes[Math.floor(Math.random() * urgentShapes.length)]
        : MaterialShape.Shape.Circle

    color: isUrgent
        ? Appearance.colors.colPrimaryContainer
        : Appearance.colors.colSecondaryContainer

    // Tier 1: Image from notification
    Loader {
        id: notifImageLoader
        active: root.image !== ""
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            Image {
                id: notifImage
                anchors.fill: parent
                readonly property int size: parent.width
                source: root.image
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                asynchronous: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: notifImage.size
                        height: notifImage.size
                        radius: Appearance.rounding.full
                    }
                }
            }
            // Small app icon badge on bottom-right of image
            Loader {
                id: notifImageAppIconLoader
                active: root.appIcon !== ""
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: IconImage {
                    implicitWidth: root.smallAppIconSize
                    implicitHeight: root.smallAppIconSize
                    asynchronous: true
                    source: Quickshell.iconPath(root.appIcon, "image-missing")
                }
            }
        }
    }

    // Tier 2: Desktop entry app icon
    Loader {
        id: appIconLoader
        active: root.image === "" && root.appIcon !== ""
        anchors.centerIn: parent
        sourceComponent: IconImage {
            implicitWidth: root.appIconSize
            implicitHeight: root.appIconSize
            asynchronous: true
            source: Quickshell.iconPath(root.appIcon, "image-missing")
        }
    }

    // Tier 3: Material Symbol (guessed by NotificationUtils)
    Loader {
        id: materialSymbolLoader
        active: root.appIcon === "" && root.image === ""
        anchors.fill: parent
        sourceComponent: Text {
            text: {
                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(root.summary)
                return (isUrgent && guessedIcon === defaultIcon)
                    ? "priority_high" : guessedIcon
            }
            anchors.fill: parent
            font.family: "Material Symbols Outlined"
            font.pixelSize: root.materialIconSize
            color: isUrgent
                ? Appearance.colors.colOnPrimaryContainer
                : Appearance.colors.colOnSecondaryContainer
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
