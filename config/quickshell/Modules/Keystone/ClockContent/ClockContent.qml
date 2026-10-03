import QtQuick
import qs.Common
import qs.Services
import qs.Widgets.common
import "../../../Common/functions/DateFormat.js" as DateFormat

Item {
    id: root

    property var player
    property string edge: "top"
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property bool hideDate: PersonalizationConfig.keystoneHideDate
    property string dateStr: ""
    property var verticalDateParts: []
    readonly property string clockFamily: Fonts.systemClock
    readonly property var verticalClockAxes: Fonts.familyAvailable(Fonts.systemClock) ? ({
                                                                                             "wght": 900,
                                                                                             "wdth": 85,
                                                                                             "opsz": 24,
                                                                                             "GRAD": 75,
                                                                                             "ROND": 25,
                                                                                             "slnt": 0
                                                                                         }) : ({})
    // 时间拆成 4 个整数驱动翻页动画；数字本体交给 RollingClock（与锁屏共用）
    readonly property int h0: rollingClock.h0
    readonly property int h1: rollingClock.h1
    readonly property int m0: rollingClock.m0
    readonly property int m1: rollingClock.m1
    readonly property string periodLead: rollingClock.periodLead

    function formatDate(date) {
        if (DateFormat.isChinese(I18nService.language))
            return String(date.getMonth() + 1).padStart(2, "0") + "月" + String(date.getDate()).padStart(2, "0")
                    + "日" + DateFormat.shortWeekdays(I18nService.language)[date.getDay()];

        return DateFormat.compactDate(date, I18nService.language, Qt.locale(I18nService.language),
                                      "ddd dd MMM");
    }

    // Side Keystone uses short horizontal rows: up to three Latin letters,
    // two digits, or one Han character per row. This keeps every glyph
    // upright while preserving the existing narrow pill geometry.
    function sideDateParts(date) {
        if (DateFormat.isChinese(I18nService.language)) {
            const weekday = DateFormat.shortWeekdays(I18nService.language)[date.getDay()];
            return [String(date.getMonth() + 1).padStart(2, "0"), "月", String(date.getDate()).padStart(2, "0"),
                    "日", weekday.slice(0, 1), weekday.slice(1, 2)];
        }
        const locale = Qt.locale(I18nService.language);
        return [date.toLocaleDateString(locale, "ddd").slice(0, 3), String(date.getDate()).padStart(2, "0"),
                date.toLocaleDateString(locale, "MMM").slice(0, 3)];
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const d = new Date();
            root.dateStr = root.formatDate(d);
            root.verticalDateParts = root.sideDateParts(d);
            // 数字与日期共用同一个时间点，避免跨秒错位
            rollingClock.tick(d);
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: root.hideDate ? 0 : 10
        visible: !root.vertical

        // --- 左侧日期部分 ---
        Text {
            text: root.dateStr
            visible: !root.hideDate
            width: root.hideDate ? 0 : implicitWidth
            color: Appearance.colors.colPrimary
            font.family: Fonts.ui
            font.pixelSize: 13
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            visible: !root.hideDate
            width: root.hideDate ? 0 : 8
            height: root.horizontalFontSize + 2
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.centerIn: parent
                width: 2
                height: 14
                radius: width / 2
                color: Appearance.colors.colOutlineVariant
            }
        }

        // --- 右侧滚动时钟（锁屏复用同一组件，设置里改一次两处生效）---
        RollingClock {
            id: rollingClock

            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Column {
        id: verticalClockLayout

        anchors.centerIn: parent
        spacing: 4
        visible: root.vertical

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
            visible: !root.hideDate

            Repeater {
                model: root.verticalDateParts

                Text {
                    required property string modelData

                    width: 28
                    height: 15
                    text: modelData
                    color: Appearance.colors.colPrimary
                    font.family: Fonts.ui
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 28
            height: 10
            visible: !root.hideDate

            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 2
                radius: height / 2
                color: Appearance.colors.colOutlineVariant
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: -1

            Text {
                width: 28
                height: 20
                text: String(root.h0) + String(root.h1)
                color: Appearance.colors.colPrimary
                font.family: root.clockFamily
                font.pixelSize: 20
                font.weight: Font.Black
                font.letterSpacing: -1.5
                font.variableAxes: root.verticalClockAxes
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                width: 28
                height: 10

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: 2

                        Rectangle {
                            required property int index

                            width: 3
                            height: 3
                            radius: width / 2
                            color: Appearance.colors.colOutlineVariant
                        }
                    }
                }
            }

            Text {
                width: 28
                height: 20
                text: String(root.m0) + String(root.m1)
                color: Appearance.colors.colPrimary
                font.family: root.clockFamily
                font.pixelSize: 20
                font.weight: Font.Black
                font.letterSpacing: -1.5
                font.variableAxes: root.verticalClockAxes
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: UiPreferences.useTwelveHourClock
                width: 28
                height: 15
                text: root.periodLead + "M"
                color: Appearance.colors.colPrimary
                font.family: root.clockFamily
                font.pixelSize: 14
                font.weight: Font.Black
                font.letterSpacing: -2
                font.variableAxes: root.verticalClockAxes
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

}
