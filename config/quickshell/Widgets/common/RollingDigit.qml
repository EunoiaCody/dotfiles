import QtQuick
import qs.Common

Item {
    id: root
    property int targetDigit: 0
    property color digitColor: "white"
    property real digitRotation: 0
    property real digitOffset: 0

    width: digitText.implicitWidth
    height: 20
    clip: true
    rotation: digitRotation
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: digitOffset

    Text {
        id: digitText
        text: "0\n1\n2\n3\n4\n5\n6\n7\n8\n9"
        color: root.digitColor
        font.family: Sizes.fontFamily
        font.pixelSize: 18
        font.weight: Font.Black
        lineHeight: 20
        lineHeightMode: Text.FixedHeight
        y: -root.targetDigit * 20

        Behavior on y {
            SpringAnimation {
                spring: 3.5
                damping: 0.75
                mass: 1.0
            }
        }
    }
}
