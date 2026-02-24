// ============================================================
// 时钟组件
// 从 SketchyBar clock.lua 迁移
// 格式与 SketchyBar 一致：YYYY.MM.DD HH:MM
// 增强：悬停展开显示星期，点击切换日期/时间格式
// ============================================================
import QtQuick
import ".."

Item {
    id: root

    implicitWidth: clockBackground.width
    implicitHeight: Theme.barHeight

    property date currentDate: new Date()
    property bool hovered: false
    // 点击切换格式
    property bool altFormat: false

    // -------------------- 定时更新 --------------------
    Timer {
        interval: Theme.clockInterval
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    // -------------------- 悬停检测 --------------------
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        // 点击切换格式
        onClicked: root.altFormat = !root.altFormat
    }

    // -------------------- 背景 --------------------
    Rectangle {
        id: clockBackground
        width: clockRow.implicitWidth + Theme.widgetPadding * 2
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: Theme.surface0

        // -------------------- 时钟文字 --------------------
        Row {
            id: clockRow
            anchors.centerIn: parent
            spacing: 6

            // 日期部分（与 SketchyBar 的 YYYY.MM.DD 格式一致）
            Text {
                id: dateText
                anchors.verticalCenter: parent.verticalCenter
                text: root.altFormat
                    ? Qt.formatDateTime(root.currentDate, "yyyy年MM月dd日 dddd")
                    : Qt.formatDateTime(root.currentDate, "yyyy.MM.dd")
                color: Theme.subtext1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }

            // 时间部分
            Text {
                id: timeText
                anchors.verticalCenter: parent.verticalCenter
                text: root.altFormat
                    ? Qt.formatDateTime(root.currentDate, "HH:mm:ss")
                    : Qt.formatDateTime(root.currentDate, "HH:mm")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }
    }
}
