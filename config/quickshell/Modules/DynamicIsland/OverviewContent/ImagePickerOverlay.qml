import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Common

Item {
    id: root
    visible: root.isOpen

    // ============================================================
    // 信号
    // ============================================================
    signal imageSelected(string path)
    signal closed()

    // ============================================================
    // 状态
    // ============================================================
    property bool isOpen: false
    property var allImages: []
    property string illustDir: "/home/eunoia/Pictures/Illustraions"

    ListModel { id: imageModel }

    // ============================================================
    // 图片扫描
    // ============================================================
    Process {
        id: scanProcess
        command: ["bash", "-c",
            "if [ -d '" + root.illustDir + "' ]; then find '" + root.illustDir +
            "' -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort; fi"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (file) => {
                var f = file.trim()
                if (f !== "") {
                    root.allImages.push(f)
                    imageModel.append({ path: f })
                }
            }
        }
    }

    function filterImages(query) {
        imageModel.clear()
        var q = query.toLowerCase()
        for (var i = 0; i < root.allImages.length; i++) {
            var path = root.allImages[i]
            var name = path.substring(path.lastIndexOf("/") + 1).toLowerCase()
            if (name.includes(q)) {
                imageModel.append({ path: path })
            }
        }
        pickerView.currentIndex = 0
    }

    function open() {
        root.isOpen = true
        searchInput.text = ""
        if (imageModel.count === 0 && root.allImages.length === 0) {
            scanProcess.running = false
            scanProcess.running = true
        }
        searchInput.forceActiveFocus()
    }

    function close() {
        root.isOpen = false
        root.closed()
    }

    function selectCurrent() {
        if (imageModel.count === 0 || pickerView.currentIndex < 0) return
        var path = imageModel.get(pickerView.currentIndex).path
        root.imageSelected(path)
        root.close()
    }

    // ============================================================
    // Escape 关闭
    // ============================================================
    focus: root.isOpen
    onIsOpenChanged: { if (isOpen) forceActiveFocus() }
    Keys.onEscapePressed: root.close()
    Keys.onReturnPressed: root.selectCurrent()
    Keys.onEnterPressed: root.selectCurrent()

    // ============================================================
    // UI
    // ============================================================
    // 半透明遮罩
    Rectangle {
        anchors.fill: parent
        color: "#aa000000"
        opacity: root.isOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // 选择器面板
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(900, parent.width - 40)
        height: Math.min(420, parent.height - 60)
        radius: 24
        color: Appearance.colors.colLayer1
        opacity: root.isOpen ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // 标题栏
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            radius: 24
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20
                color: parent.color
            }

            Text {
                anchors.centerIn: parent
                text: "选择插图"
                font.family: Sizes.fontFamily
                font.pixelSize: 15
                font.bold: true
                color: Appearance.colors.colOnSurface
            }

            // 关闭按钮
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30; radius: 15
                color: closeMouse.containsMouse ? Appearance.colors.colLayer2Hover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: Appearance.colors.colOnSurfaceVariant
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        // ── PathView 轮盘 ──
        PathView {
            id: pickerView
            anchors.top: parent.top
            anchors.topMargin: 44
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: searchContainer.top
            anchors.bottomMargin: 8

            pathItemCount: 5
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            snapMode: PathView.SnapToItem
            dragMargin: pickerView.height

            model: imageModel
            focus: true
            Keys.onLeftPressed: decrementCurrentIndex()
            Keys.onRightPressed: incrementCurrentIndex()

            path: Path {
                startX: 20
                startY: pickerView.height / 2 + 15
                PathLine {
                    x: pickerView.width - 20
                    y: pickerView.height / 2 + 10
                }
            }

            delegate: Item {
                id: delegateRoot
                width: 200
                height: 240

                z: PathView.isCurrentItem ? 100 : 0
                property bool isCurrent: PathView.isCurrentItem

                Item {
                    id: imageWrapper
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -20

                    width: 160
                    height: 90

                    scale: isCurrent ? 1.5 : 1.0
                    opacity: isCurrent ? 1.0 : 0.6

                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "black"
                        visible: isCurrent
                        opacity: isCurrent ? 1.0 : 0.0

                        layer.enabled: true
                        layer.effect: DropShadow {
                            transparentBorder: true
                            radius: 20
                            samples: 41
                            color: Qt.rgba(0, 0, 0, 0.6)
                            verticalOffset: 6
                        }
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }

                    Item {
                        id: imgRect
                        anchors.fill: parent

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: imgRect.width
                                height: imgRect.height
                                radius: 10
                                visible: false
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Appearance.colors.colLayer2
                        }

                        Image {
                            anchors.fill: parent
                            source: "file://" + model.path
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 512
                            asynchronous: true
                            cache: true
                            visible: status === Image.Ready
                        }
                    }
                }

                // 文件名
                Text {
                    anchors.top: imageWrapper.bottom
                    anchors.topMargin: isCurrent ? 30 : 8
                    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 10

                    text: model.path.substring(model.path.lastIndexOf("/") + 1).split(".")[0]
                    color: Appearance.colors.colOnSurface
                    font.family: Sizes.fontFamily
                    font.pixelSize: 11
                    font.weight: isCurrent ? Font.Bold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                TapHandler {
                    onTapped: {
                        pickerView.currentIndex = index
                        if (pickerView.currentIndex === index) root.selectCurrent()
                    }
                }
            }
        }

        // ── 搜索容器 ──
        Rectangle {
            id: searchContainer
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 40
            radius: 10
            color: Appearance.colors.colLayer3

            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "🔍"
                    color: Appearance.colors.colOnSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14
                }

                TextInput {
                    id: searchInput
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                    color: Appearance.colors.colOnSurface
                    font.family: Sizes.fontFamily
                    font.pixelSize: 14
                    selectionColor: Appearance.colors.colPrimary

                    Text {
                        text: "> 搜索图片..."
                        color: Appearance.colors.colOnSurfaceVariant
                        visible: !searchInput.text && !searchInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    onTextChanged: root.filterImages(text)

                    Keys.onUpPressed: (event) => { pickerView.decrementCurrentIndex(); event.accepted = true }
                    Keys.onDownPressed: (event) => { pickerView.incrementCurrentIndex(); event.accepted = true }
                    Keys.onLeftPressed: (event) => {
                        if (text.length === 0 || cursorPosition === 0) {
                            pickerView.decrementCurrentIndex(); event.accepted = true
                        }
                    }
                    Keys.onRightPressed: (event) => {
                        if (text.length === 0 || cursorPosition === text.length) {
                            pickerView.incrementCurrentIndex(); event.accepted = true
                        }
                    }
                }
            }

            // 清除按钮
            MouseArea {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 30
                cursorShape: Qt.PointingHandCursor
                visible: searchInput.text !== ""

                Text {
                    text: "✕"
                    color: Appearance.colors.colOnSurfaceVariant
                    anchors.centerIn: parent
                    font.pixelSize: 12
                }
                onClicked: {
                    searchInput.text = ""
                    searchInput.forceActiveFocus()
                }
            }
        }
    }
}
