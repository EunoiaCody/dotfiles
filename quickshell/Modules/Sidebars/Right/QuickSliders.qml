import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Components
import qs.Services
import qs.Widgets.common

Rectangle {
    id: root

    readonly property real gammaCutoff: 0.3
    property var screen: null
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property real brightnessValue: brightnessMonitor ? brightnessMonitor.brightness : Brightness.brightnessValue
    property real verticalPadding: 4
    property real horizontalPadding: 12

    Layout.fillWidth: true
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    ColumnLayout {
        id: contentItem

        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }
        spacing: 0

        QuickSlider {
            materialSymbol: "light_mode"
            secondaryMaterialSymbol: "wb_twilight"
            stopIndicatorValues: Wlsunset.gamma !== 100 && root.brightnessValue > 0 ? [root.gammaCutoff + root.brightnessValue * (1 - root.gammaCutoff)] : []
            value: Wlsunset.gamma === 100 ? root.gammaCutoff + root.brightnessValue * (1 - root.gammaCutoff) : (Wlsunset.gamma - Wlsunset.gammaLowerLimit) / (100 - Wlsunset.gammaLowerLimit) * root.gammaCutoff
            percentText: Wlsunset.gamma === 100 ? `${Math.round(root.brightnessValue * 100)}%` : `${Wlsunset.gamma}%`
            tooltipContent: Wlsunset.gamma === 100 ? `${Math.round(root.brightnessValue * 100)}%` : `Gamma ${Wlsunset.gamma}%`
            onMoved: {
                if (value >= root.gammaCutoff) {
                    Brightness.setBrightnessForScreen(root.screen, (value - root.gammaCutoff) / (1 - root.gammaCutoff));
                    if (Wlsunset.gamma !== 100)
                        Wlsunset.setGamma(100);
                } else {
                    if (root.brightnessValue > 0)
                        Brightness.setBrightnessForScreen(root.screen, 0, true);
                    Wlsunset.setGamma(value / root.gammaCutoff * (100 - Wlsunset.gammaLowerLimit) + Wlsunset.gammaLowerLimit);
                }
            }
        }

        QuickSlider {
            materialSymbol: "volume_up"
            value: Volume.sinkVolume
            onMoved: Volume.setSinkVolume(value)
        }

        QuickSlider {
            materialSymbol: "mic"
            value: Volume.sourceVolume
            onMoved: Volume.setSourceVolume(value)
        }
    }

    component QuickSlider: MaterialSplitSlider {
        id: quickSlider

        required property string materialSymbol
        property string secondaryMaterialSymbol: ""
        property string percentText: `${Math.round(((value - from) / (to - from)) * 100)}%`

        configuration: MaterialSplitSlider.Configuration.M
        stopIndicatorValues: []
        dividerValues: secondaryMaterialSymbol.length > 0 ? [secondaryIcon.iconLocation] : []
        Layout.fillWidth: true

        Text {
            id: percentLabel

            readonly property bool nearEmpty: quickSlider.visualPosition * quickSlider.effectiveDraggingWidth <= implicitWidth + 20

            anchors {
                verticalCenter: quickSlider.verticalCenter
                left: nearEmpty ? quickSlider.handle.left : quickSlider.left
                leftMargin: nearEmpty ? 14 : 8
            }
            text: quickSlider.percentText
            color: nearEmpty ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimary
            font.family: Sizes.fontFamilyMono
            font.pixelSize: 12
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            z: 1

            Behavior on color {
                ColorAnimation {
                    duration: quickSlider.fastAnimation.duration
                    easing.type: quickSlider.fastAnimation.type
                    easing.bezierCurve: quickSlider.fastAnimation.bezierCurve
                }
            }

            Behavior on anchors.leftMargin {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: quickSlider.fastAnimation.duration
                    easing.type: quickSlider.fastAnimation.type
                    easing.bezierCurve: quickSlider.fastAnimation.bezierCurve
                }
            }
        }

        MaterialSymbol {
            id: icon

            property bool nearFull: quickSlider.value >= 0.9

            anchors {
                verticalCenter: quickSlider.verticalCenter
                right: nearFull ? quickSlider.handle.right : quickSlider.right
                rightMargin: nearFull ? 14 : 8
            }
            text: quickSlider.materialSymbol
            iconSize: 20
            fill: 0
            color: nearFull ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer

            Behavior on color {
                ColorAnimation {
                    duration: quickSlider.fastAnimation.duration
                    easing.type: quickSlider.fastAnimation.type
                    easing.bezierCurve: quickSlider.fastAnimation.bezierCurve
                }
            }

            Behavior on anchors.rightMargin {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: quickSlider.fastAnimation.duration
                    easing.type: quickSlider.fastAnimation.type
                    easing.bezierCurve: quickSlider.fastAnimation.bezierCurve
                }
            }
        }

        MaterialSymbol {
            id: secondaryIcon

            visible: quickSlider.secondaryMaterialSymbol.length > 0
            property real iconLocation: root.gammaCutoff
            property bool nearIcon: iconLocation - quickSlider.value <= 0.1 && iconLocation - quickSlider.value > (quickSlider.handleWidth + 8 - 14) / quickSlider.effectiveDraggingWidth

            anchors {
                verticalCenter: quickSlider.verticalCenter
                right: nearIcon ? quickSlider.handle.right : quickSlider.right
                rightMargin: nearIcon ? 14 : (1 - iconLocation) * quickSlider.effectiveDraggingWidth + quickSlider.rightPadding + 8
            }
            text: quickSlider.secondaryMaterialSymbol
            iconSize: 20
            fill: 0
            color: quickSlider.value >= iconLocation - 0.1 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer

            Behavior on color {
                ColorAnimation {
                    duration: quickSlider.fastAnimation.duration
                    easing.type: quickSlider.fastAnimation.type
                    easing.bezierCurve: quickSlider.fastAnimation.bezierCurve
                }
            }

            Behavior on anchors.rightMargin {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: quickSlider.fastAnimation.duration
                    easing.type: quickSlider.fastAnimation.type
                    easing.bezierCurve: quickSlider.fastAnimation.bezierCurve
                }
            }
        }
    }
}
