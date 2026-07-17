import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Components
import qs.Widgets.common

// WallpaperPage — Stripped version.
// Original had a "过渡效果 / Transition Effects" Section referencing
// BezierCurveEditor, BezierCurveLayerEditor, EasingGroupButton, EasingActionGroup,
// MaterialAccessibleSlider, and SplitMenuButton — those components are NOT being
// migrated from the remote ControlCenter. That entire section is removed.
// The simplified WallpaperBackground.qml displays wallpapers without transition effects.

StyledFlickable {
    id: root

    clip: true
    contentWidth: width
    contentHeight: contentColumn.y + contentColumn.implicitHeight + 20

    readonly property string currentWallpaperPath: WallpaperService.currentWallpaper || PersonalizationConfig.wallpaperPath
    readonly property bool currentWallpaperIsColor: WallpaperService.isColorSource(currentWallpaperPath)
    readonly property bool currentWallpaperIsImage: currentWallpaperPath !== "" && !currentWallpaperIsColor
    readonly property real pageContentWidth: 600
    property real fillModeGroupRestingWidth: 0

    function chooseWallpaperFile() {
        const base = root.currentWallpaperIsImage ? WallpaperService.parentFolder(root.currentWallpaperPath) : PersonalizationConfig.wallpaperFolder;
        wallpaperFileBrowser.openAt(base || PersonalizationConfig.wallpaperFolder);
    }

    function chooseWallpaperColor() {
        wallpaperColorPicker.showWithColor(root.currentWallpaperIsColor ? root.currentWallpaperPath : Appearance.colors.colPrimary);
    }

    component Section: ColumnLayout {
        id: section

        property string title: ""
        property string iconName: "settings"
        default property alias content: body.data

        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                text: section.iconName
                iconSize: 26
                fill: 1
                color: Appearance.colors.colOnSecondaryContainer
            }

            Text {
                Layout.fillWidth: true
                text: section.title
                color: Appearance.colors.colOnSecondaryContainer
                font.family: Sizes.fontFamily
                font.pixelSize: 18
                font.weight: Font.Medium
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 12
        }
    }

    component ActionPillButton: Item {
        id: pill

        property string text: ""
        property string iconName: ""

        signal clicked

        implicitWidth: Math.max(78, label.implicitWidth + (iconName !== "" ? 42 : 28))
        implicitHeight: 34
        opacity: enabled ? 1 : 0.45

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: pillMouse.containsMouse ? Appearance.colors.colLayer4 : Appearance.colors.colLayer2
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant
        }

        Row {
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                text: pill.iconName
                iconSize: 18
                color: Appearance.colors.colOnLayer2
                visible: pill.iconName !== ""
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: label
                text: pill.text
                color: Appearance.colors.colOnLayer2
                font.family: Sizes.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            enabled: pill.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    component HoverActionButton: Item {
        id: action

        property string iconName: ""
        property string tooltipText: ""

        signal clicked

        width: 32
        height: 32

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: actionMouse.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.9)
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: action.iconName
            iconSize: 18
            color: "black"
            fill: 1
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }

        StyledToolTip {
            extraVisibleCondition: actionMouse.containsMouse && action.tooltipText !== ""
            text: action.tooltipText
        }
    }

    ColumnLayout {
        id: contentColumn
        width: root.pageContentWidth
        x: Math.max(24, (root.width - width) / 2)
        y: 24
        spacing: 30

        Section {
            title: "当前壁纸"
            iconName: "wallpaper"

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                Item {
                    id: wallpaperPreview

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 340
                    Layout.preferredHeight: 200

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: root.currentWallpaperIsColor ? root.currentWallpaperPath : Appearance.colors.colLayer2
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: root.currentWallpaperIsImage ? Paths.fileUrl(root.currentWallpaperPath) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        smooth: true
                        visible: source !== ""
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: wallpaperMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1
                        }
                    }

                    Rectangle {
                        id: wallpaperMask
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Appearance.rounding.normal - 1
                        color: "black"
                        visible: false
                        layer.enabled: true
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "image"
                        iconSize: 34
                        color: Appearance.colors.colOnSurfaceVariant
                        visible: root.currentWallpaperPath === ""
                    }

                    HoverHandler {
                        id: previewHover
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: Qt.rgba(0, 0, 0, 0.7)
                        opacity: previewHover.hovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutSine
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            HoverActionButton {
                                iconName: "folder_open"
                                tooltipText: "选择文件夹"
                                onClicked: root.chooseWallpaperFile()
                            }

                            HoverActionButton {
                                iconName: "palette"
                                tooltipText: "选择颜色"
                                onClicked: root.chooseWallpaperColor()
                            }

                            HoverActionButton {
                                iconName: "clear"
                                tooltipText: "清除壁纸"
                                onClicked: WallpaperService.clearWallpaper()
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Math.min(450, Math.max(330, root.width - 420))
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: root.currentWallpaperPath !== "" ? WallpaperService.basename(root.currentWallpaperPath) : "未选择壁纸"
                        color: Appearance.colors.colOnSurface
                        font.family: Sizes.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideMiddle
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.currentWallpaperPath
                        color: Appearance.colors.colSubtext
                        font.family: Sizes.fontFamilyMono
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideMiddle
                        visible: root.currentWallpaperPath !== ""
                    }

                    SegmentedButtonGroup {
                        Layout.alignment: Qt.AlignLeft
                        model: [
                            ({ "value": "previous", "label": "上一张" }),
                            ({ "value": "random", "label": "随机" }),
                            ({ "value": "next", "label": "下一张" })
                        ]
                        currentValue: ""
                        onValueSelected: value => {
                            if (value === "previous")
                                WallpaperService.cyclePrevious();
                            else if (value === "random")
                                WallpaperService.cycleRandom();
                            else
                                WallpaperService.cycleNext();
                        }
                    }
                }
            }

            SegmentedButtonGroup {
                id: fillModeButtonGroup

                Layout.alignment: Qt.AlignHCenter
                model: PersonalizationConfig.fillModes
                currentValue: PersonalizationConfig.wallpaperFillMode
                Component.onCompleted: root.fillModeGroupRestingWidth = implicitWidth
                onValueSelected: value => WallpaperService.setWallpaperFillMode(value)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
        }
    }

    WallpaperFileBrowser {
        id: wallpaperFileBrowser
        startPath: PersonalizationConfig.wallpaperFolder
        onFolderSelected: path => {
            WallpaperService.setWallpaperFolder(path);
        }
        onFileSelected: path => {
            const folder = WallpaperService.parentFolder(path);
            if (folder !== "")
                WallpaperService.setWallpaperFolder(folder);
            WallpaperService.setWallpaper(path);
        }
    }

    WallpaperColorPicker {
        id: wallpaperColorPicker
        onColorSelected: color => WallpaperService.setWallpaper(color)
    }
}
