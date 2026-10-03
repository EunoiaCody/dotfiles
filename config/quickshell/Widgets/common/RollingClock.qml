import QtQuick
import qs.Common
import qs.Services

// 与 bar 时钟同源的滚动数字时钟。
// 字形、可变轴、每个数字的位移/旋转/配色都取自 PersonalizationConfig，
// 所以设置里改一次，bar 与锁屏同时生效，两处永远不会走样。
Item {
    id: root

    // bar 走配置字号；锁屏等需要更大字的场景用 fontSizeOverride 覆盖
    property real fontSizeOverride: 0
    readonly property real fontSize: root.fontSizeOverride > 0 ? root.fontSizeOverride :
                                                                 PersonalizationConfig.horizontalClockFontSize
    readonly property real lineHeight: Math.max(18, root.fontSize + 2)
    readonly property string clockFamily: Fonts.systemClock
    readonly property bool showPeriod: UiPreferences.useTwelveHourClock

    property int h0: 0
    property int h1: 0
    property int m0: 0
    property int m1: 0
    property string periodLead: "A"

    implicitWidth: layout.width
    implicitHeight: layout.height

    // 外部（如 ClockContent 的竖排布局）可主动同步，避免多一个 Timer
    function tick(date) {
        const d = date || new Date();
        const hour24 = d.getHours();
        const displayHour = root.showPeriod ? ((hour24 + 11) % 12) + 1 : hour24;
        const hStr = displayHour.toString().padStart(2, "0");
        const mStr = d.getMinutes().toString().padStart(2, "0");
        root.periodLead = hour24 >= 12 ? "P" : "A";
        root.h0 = parseInt(hStr[0]);
        root.h1 = parseInt(hStr[1]);
        root.m0 = parseInt(mStr[0]);
        root.m1 = parseInt(mStr[1]);
    }

    function digitValue(id, field) {
        const digit = PersonalizationConfig.horizontalClockDigit(id);
        return digit && typeof digit[field] === "number" ? digit[field] : 0;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    Row {
        id: layout

        anchors.centerIn: parent
        spacing: 5

        // --- 小时 ---
        Row {
            spacing: -1

            RollingDigit {
                digitId: "h0"
                targetDigit: root.h0
            }

            RollingDigit {
                digitId: "h1"
                targetDigit: root.h1
            }
        }

        ClockLetter {
            letterId: "separator"
            value: ":"
        }

        // --- 分钟 ---
        Row {
            spacing: 1

            RollingDigit {
                digitId: "m0"
                targetDigit: root.m0
            }

            RollingDigit {
                digitId: "m1"
                targetDigit: root.m1
            }
        }

        Row {
            visible: root.showPeriod
            spacing: 0

            ClockLetter {
                letterId: "ap"
                value: root.periodLead
            }

            ClockLetter {
                letterId: "periodM"
                value: "M"
            }
        }
    }

    // ============================================================
    // 滚动数字：一次性渲染 0-9，靠 y 偏移 + 弹簧动画做机械翻页
    // ============================================================
    component RollingDigit: Item {
        id: digitContainer

        property string digitId: "h0"
        property int targetDigit: 0
        readonly property real digitXOffset: root.digitValue(digitId, "x")
        readonly property real digitYOffset: root.digitValue(digitId, "y")
        readonly property real digitRotation: root.digitValue(digitId, "rotation")

        width: digitText.implicitWidth
        height: root.lineHeight
        clip: true
        anchors.verticalCenter: parent.verticalCenter
        transform: [
            Translate {
                x: digitContainer.digitXOffset
                y: digitContainer.digitYOffset
            },
            Rotation {
                angle: digitContainer.digitRotation
                origin.x: digitContainer.width / 2
                origin.y: digitContainer.height / 2
            }
        ]

        Text {
            id: digitText

            text: "0\n1\n2\n3\n4\n5\n6\n7\n8\n9"
            color: PersonalizationConfig.horizontalClockDigitColor(digitContainer.digitId)
            font.family: root.clockFamily
            font.variableAxes: PersonalizationConfig.horizontalClockAxes
            font.pixelSize: root.fontSize
            lineHeight: root.lineHeight
            lineHeightMode: Text.FixedHeight
            y: -digitContainer.targetDigit * root.lineHeight

            // 弹性动画：带惯性回弹的翻页手感
            Behavior on y {
                SpringAnimation {
                    spring: 3.5
                    damping: 0.75
                    mass: 1
                }
            }
        }
    }

    component ClockLetter: Item {
        id: letterContainer

        required property string letterId
        required property string value
        readonly property real letterXOffset: root.digitValue(letterId, "x")
        readonly property real letterYOffset: root.digitValue(letterId, "y")
        readonly property real letterRotation: root.digitValue(letterId, "rotation")

        width: letterText.implicitWidth
        height: root.lineHeight
        anchors.verticalCenter: parent.verticalCenter
        transform: [
            Translate {
                x: letterContainer.letterXOffset
                y: letterContainer.letterYOffset
            },
            Rotation {
                angle: letterContainer.letterRotation
                origin.x: letterContainer.width / 2
                origin.y: letterContainer.height / 2
            }
        ]

        Text {
            id: letterText

            text: letterContainer.value
            color: PersonalizationConfig.horizontalClockDigitColor(letterContainer.letterId)
            font.family: root.clockFamily
            font.variableAxes: PersonalizationConfig.horizontalClockAxes
            font.pixelSize: root.fontSize
            lineHeight: root.lineHeight
            lineHeightMode: Text.FixedHeight
        }
    }
}