import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Widgets.common
import qs.Common
import qs.Services
import QtQuick.Controls

WidgetPanel {
    id: root
    title: "亮度"
    icon: "brightness_medium"
    closeAction: () => WidgetState.qsOpen = false

    contentImplicitHeight: 640
    property bool isActive: WidgetState.qsOpen && WidgetState.qsView === "brightness"

    // --- 自动亮度开关（header 右侧） ---
    headerTools: RowLayout {
        spacing: 8

        Text {
            text: "自动"
            font.pixelSize: 13
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        StyledSwitch {
            id: autoSwitch
            checked: Brightness.autoBrightness
            scale: 0.8
            Layout.alignment: Qt.AlignVCenter

            onToggled: Brightness.setAutoBrightness(autoSwitch.checked)
        }
    }

    // --- 面板主体（可滚动）---
    StyledFlickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: availableWidth
        contentHeight: scrollCol.height

        Column {
            id: scrollCol
            width: parent.width
            spacing: 20

        // ============================================================
        // 自动亮度状态卡片
        // ============================================================
        Rectangle {
            width: parent.width
            height: autoCardContent.implicitHeight + 24
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: autoCardContent
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 4

                Text {
                    text: Brightness.autoBrightness ? "🌅 自动亮度已开启" : "🎛️ 手动模式"
                    font.pixelSize: 14
                    font.bold: true
                    color: Appearance.colors.colOnLayer2
                }

                Text {
                    text: Brightness.autoBrightness
                        ? "wluma 正在根据环境光和屏幕内容自动调节亮度。关闭后可手动控制。"
                        : "自动亮度已关闭。你可以手动拖动下方滑块调节亮度。"
                    font.pixelSize: 12
                    color: Appearance.colors.colOnLayer1
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // ============================================================
        // 亮度滑块
        // ============================================================
        Rectangle {
            width: parent.width
            height: brightnessContent.implicitHeight + 24
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1
            opacity: Brightness.autoBrightness ? 0.55 : 1.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.expressiveEffects.duration
                    easing.type: Appearance.animation.expressiveEffects.type
                    easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                }
            }

            ColumnLayout {
                id: brightnessContent
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 16
                }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "brightness_medium"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Appearance.colors.colPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "屏幕亮度"
                        font.pixelSize: 15
                        font.bold: true
                        color: Appearance.colors.colOnLayer2
                        Layout.fillWidth: true
                    }

                    Text {
                        text: Math.round(Brightness.brightnessValue * 100) + "%"
                        font.pixelSize: 15
                        font.bold: true
                        font.family: Sizes.fontFamilyMono
                        color: Appearance.colors.colPrimary
                    }
                }

                // 大号亮度滑块
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42

                    MaterialSplitSlider {
                        id: brightnessSlider
                        anchors.fill: parent
                        configuration: MaterialSplitSlider.Configuration.L
                        value: Brightness.brightnessValue
                        enabled: !Brightness.autoBrightness
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: Appearance.applyAlpha(Appearance.colors.colPrimary, 0.2)
                        handleColor: Appearance.colors.colPrimary

                        onMoved: Brightness.setBrightness(value)
                    }
                }
            }
        }

        // ============================================================
        // 对比度
        // ============================================================
        Rectangle {
            width: parent.width
            height: contrastContent.implicitHeight + 24
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: contrastContent
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 16
                }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "contrast"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Appearance.colors.colPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "对比度"
                        font.pixelSize: 15
                        font.bold: true
                        color: Appearance.colors.colOnLayer2
                        Layout.fillWidth: true
                    }

                    Text {
                        text: Math.round(Brightness.contrastValue * 100) + "%"
                        font.pixelSize: 15
                        font.bold: true
                        font.family: Sizes.fontFamilyMono
                        color: Appearance.colors.colPrimary
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42

                    MaterialSplitSlider {
                        anchors.fill: parent
                        configuration: MaterialSplitSlider.Configuration.L
                        value: Brightness.contrastValue
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: Appearance.applyAlpha(Appearance.colors.colPrimary, 0.2)
                        handleColor: Appearance.colors.colPrimary

                        onMoved: Brightness.setContrast(value)
                    }
                }
            }
        }

        // ============================================================
        // RGB 色彩增益
        // ============================================================
        Rectangle {
            width: parent.width
            height: rgbContent.implicitHeight + 24
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: rgbContent
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 16
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "palette"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Appearance.colors.colPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "色彩增益"
                        font.pixelSize: 15
                        font.bold: true
                        color: Appearance.colors.colOnLayer2
                        Layout.fillWidth: true
                    }
                }

                // 红色增益
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "R"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Sizes.fontFamilyMono
                        color: "#f38ba8"
                        Layout.preferredWidth: 20
                    }

                    MaterialSplitSlider {
                        Layout.fillWidth: true
                        configuration: MaterialSplitSlider.Configuration.S
                        value: Brightness.redGainValue
                        highlightColor: "#f38ba8"
                        trackColor: Appearance.applyAlpha("#f38ba8", 0.2)
                        handleColor: "#f38ba8"

                        onMoved: Brightness.setRedGain(value)
                    }

                    Text {
                        text: Math.round(Brightness.redGainValue * 100)
                        font.pixelSize: 13
                        font.family: Sizes.fontFamilyMono
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // 绿色增益
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "G"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Sizes.fontFamilyMono
                        color: "#a6e3a1"
                        Layout.preferredWidth: 20
                    }

                    MaterialSplitSlider {
                        Layout.fillWidth: true
                        configuration: MaterialSplitSlider.Configuration.S
                        value: Brightness.greenGainValue
                        highlightColor: "#a6e3a1"
                        trackColor: Appearance.applyAlpha("#a6e3a1", 0.2)
                        handleColor: "#a6e3a1"

                        onMoved: Brightness.setGreenGain(value)
                    }

                    Text {
                        text: Math.round(Brightness.greenGainValue * 100)
                        font.pixelSize: 13
                        font.family: Sizes.fontFamilyMono
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // 蓝色增益
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "B"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Sizes.fontFamilyMono
                        color: "#89b4fa"
                        Layout.preferredWidth: 20
                    }

                    MaterialSplitSlider {
                        Layout.fillWidth: true
                        configuration: MaterialSplitSlider.Configuration.S
                        value: Brightness.blueGainValue
                        highlightColor: "#89b4fa"
                        trackColor: Appearance.applyAlpha("#89b4fa", 0.2)
                        handleColor: "#89b4fa"

                        onMoved: Brightness.setBlueGain(value)
                    }

                    Text {
                        text: Math.round(Brightness.blueGainValue * 100)
                        font.pixelSize: 13
                        font.family: Sizes.fontFamilyMono
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }

        // ============================================================
        // 色温 / 夜览
        // ============================================================
        Rectangle {
            width: parent.width
            height: colorTempContent.implicitHeight + 24
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: colorTempContent
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 16
                }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "wb_twilight"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Appearance.colors.colPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "色温 / 夜览"
                        font.pixelSize: 15
                        font.bold: true
                        color: Appearance.colors.colOnLayer2
                        Layout.fillWidth: true
                    }

                    Text {
                        text: Wlsunset.gamma >= 100 ? "关闭" : Wlsunset.gamma + "%"
                        font.pixelSize: 15
                        font.bold: true
                        font.family: Sizes.fontFamilyMono
                        color: Wlsunset.gamma >= 100
                            ? Appearance.colors.colOnLayer1
                            : Appearance.colors.colPrimary
                    }
                }

                // 色温调节滑块
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42

                    MaterialSplitSlider {
                        id: colorTempSlider
                        anchors.fill: parent
                        configuration: MaterialSplitSlider.Configuration.L
                        from: Wlsunset.gammaLowerLimit
                        to: 100
                        value: Wlsunset.gamma
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: Appearance.applyAlpha(Appearance.colors.colPrimary, 0.2)
                        handleColor: Appearance.colors.colPrimary

                        onMoved: Wlsunset.setGamma(value)
                    }
                }

                // 预设按钮组
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "冷色", gamma: 100 },
                            { label: "自然", gamma: 75 },
                            { label: "暖色", gamma: 56 },
                            { label: "暗夜", gamma: 30 }
                        ]

                        Rectangle {
                            required property var modelData
                            readonly property bool isActive: {
                                if (modelData.gamma === 100)
                                    return Wlsunset.gamma >= 100;
                                return Math.abs(Wlsunset.gamma - modelData.gamma) <= 5;
                            }

                            Layout.fillWidth: true
                            height: 36
                            radius: Appearance.rounding.normal
                            color: isActive
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer2
                            border.width: isActive ? 0 : 1
                            border.color: Appearance.colors.colOutline

                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.animation.expressiveEffects.duration
                                    easing.type: Appearance.animation.expressiveEffects.type
                                    easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 13
                                font.bold: isActive
                                color: isActive
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colOnLayer1
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Wlsunset.setGamma(modelData.gamma)
                            }
                        }
                    }
                }
            }
        }

        // 底部弹性空间
        Item { width: parent.width; height: 8 }
    }
    }
}
