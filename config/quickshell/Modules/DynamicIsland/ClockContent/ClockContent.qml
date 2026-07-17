import QtQuick
import qs.Common
import qs.Widgets.common

Item {
    id: root

    property string dateStr: ""

    property int h0: 0
    property int h1: 0
    property int m0: 0
    property int m1: 0

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date()
            root.dateStr = d.toLocaleString(Qt.locale("en_US"), "ddd dd MMM")
            let hStr = d.getHours().toString().padStart(2, '0')
            let mStr = d.getMinutes().toString().padStart(2, '0')
            root.h0 = parseInt(hStr[0])
            root.h1 = parseInt(hStr[1])
            root.m0 = parseInt(mStr[0])
            root.m1 = parseInt(mStr[1])
        }
    }

    // 待机模式：日期 | 滚动时钟
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -6
        spacing: 10

        Text {
            text: root.dateStr
            color: Appearance.colors.colPrimary
            font.family: Sizes.fontFamily
            font.pixelSize: 13
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "|"
            color: Appearance.colors.colOutlineVariant
            font.family: Sizes.fontFamily
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Row {
                spacing: -1
                RollingDigit { targetDigit: root.h0; digitColor: Appearance.colors.colInversePrimary; digitRotation: -3; digitOffset: -2 }
                RollingDigit { targetDigit: root.h1; digitColor: Appearance.colors.colPrimary; digitRotation: 3; digitOffset: 1 }
            }

            Column {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                Rectangle { width: 4; height: 4; radius: 2; color: Appearance.colors.colOutlineVariant }
                Rectangle { width: 4; height: 4; radius: 2; color: Appearance.colors.colOutlineVariant }
            }

            Row {
                spacing: 1
                RollingDigit { targetDigit: root.m0; digitColor: Appearance.colors.colInversePrimary; digitRotation: -2; digitOffset: -1 }
                RollingDigit { targetDigit: root.m1; digitColor: Appearance.colors.colPrimary; digitRotation: 2; digitOffset: 1 }
            }
        }
    }
}
