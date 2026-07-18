import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets.common

// ============================================================
// ClipboardContent — 剪贴板历史面板
// ============================================================
// 在统一 RightSidebar 中展示 cliphist 剪贴板历史。
// 支持搜索筛选、点击复制、单条删除和全部清空。
// 接入 ClipboardService 单例获取数据。
// ============================================================

WidgetPanel {
    id: root

    title: "剪贴板"
    icon: "content_paste"
    closeAction: () => { WidgetState.qsOpen = false }

    contentImplicitHeight: 640

    // -----------------------------------------------------------
    // 生命周期：面板激活时连接/断开 ClipboardService
    // -----------------------------------------------------------
    readonly property bool isActive: WidgetState.qsOpen && WidgetState.qsView === "clipboard"

    onIsActiveChanged: {
        ClipboardService.panelActive = root.isActive
    }

    Component.onCompleted: {
        if (root.isActive)
            ClipboardService.panelActive = true
    }
    Component.onDestruction: {
        ClipboardService.panelActive = false
    }

    // -----------------------------------------------------------
    // 筛选后的条目列表（搜索过滤）
    // -----------------------------------------------------------
    property string searchQuery: ""

    readonly property var filteredEntries: {
        if (!ClipboardService.entries || ClipboardService.entries.length === 0)
            return []
        if (searchQuery.trim() === "")
            return ClipboardService.entries.slice().reverse()  // 最新在前
        var q = searchQuery.toLowerCase()
        return ClipboardService.entries.filter(function(e) {
            return e.preview.toLowerCase().indexOf(q) >= 0
        }).reverse()
    }

    readonly property int count: filteredEntries.length

    // -----------------------------------------------------------
    // 复制状态反馈
    // -----------------------------------------------------------
    property int copiedId: -1
    property Timer copyFeedbackTimer: Timer {
        interval: 1500
        repeat: false
        onTriggered: root.copiedId = -1
    }

    // -----------------------------------------------------------
    // 头部工具栏：搜索栏 + 清空按钮
    // -----------------------------------------------------------
    headerTools: RowLayout {
        spacing: 8

        // 清空全部按钮
        Text {
            text: "delete_sweep"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 20
            color: root.count > 0
                ? Appearance.colors.colOnLayer1
                : Qt.rgba(
                    Appearance.colors.colOnLayer1.r,
                    Appearance.colors.colOnLayer1.g,
                    Appearance.colors.colOnLayer1.b,
                    0.35)
            opacity: wipeMouse.containsMouse ? 0.7 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            MouseArea {
                id: wipeMouse
                anchors.fill: parent
                cursorShape: root.count > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: root.count > 0
                onClicked: ClipboardService.wipe()
            }

            PopupToolTip {
                extraVisibleCondition: wipeMouse.containsMouse
                text: "清空全部剪贴板历史"
            }
        }
    }

    // -----------------------------------------------------------
    // 搜索栏 — 照搬 Launcher 模式
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: 13
        color: Appearance.colors.colLayer2
        border.color: searchInput.activeFocus
            ? Appearance.colors.colPrimary
            : Appearance.colors.colLayer2Border
        border.width: 1
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 18
                color: Appearance.colors.colOnSurfaceVariant
                opacity: 0.6
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: "搜索剪贴板历史…"
                    color: Appearance.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.5)
                    font.family: Sizes.fontFamily
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    visible: searchInput.text.length === 0
                }

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    color: Appearance.colors.colOnSurface
                    selectionColor: Appearance.colors.colPrimary
                    selectedTextColor: Appearance.colors.colOnPrimary
                    font.family: Sizes.fontFamily
                    font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true

                    onTextChanged: root.searchQuery = text

                    Keys.onEscapePressed: function(event) {
                        if (searchInput.text.length > 0) {
                            searchInput.text = ""
                            root.searchQuery = ""
                        } else {
                            WidgetState.qsOpen = false
                        }
                        event.accepted = true
                    }
                }
            }

            // 清除搜索按钮
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "close"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 18
                color: Appearance.colors.colOnSurfaceVariant
                visible: searchInput.text.length > 0
                opacity: clearSearchMouse.containsMouse ? 0.8 : 0.5

                MouseArea {
                    id: clearSearchMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        searchInput.text = ""
                        root.searchQuery = ""
                    }
                }
            }
        }
    }

    // -----------------------------------------------------------
    // 空状态
    // -----------------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.count === 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 14

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "content_paste_off"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 72
                color: Appearance.colors.colOutlineVariant
                opacity: 0.5
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: ClipboardService.lastError ? "cliphist 不可用" : "剪贴板为空"
                color: Appearance.colors.colOutlineVariant
                font.family: Sizes.fontFamily
                font.pixelSize: 18
                font.weight: Font.Medium
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: ClipboardService.lastError
                    ? ("错误: " + ClipboardService.lastError)
                    : "复制内容后将自动出现在这里"
                color: Appearance.colors.colOutlineVariant
                font.family: Sizes.fontFamily
                font.pixelSize: 13
                opacity: 0.7
                visible: text.length > 0
            }
        }
    }

    // -----------------------------------------------------------
    // 条目数量指示
    // -----------------------------------------------------------
    Text {
        Layout.fillWidth: true
        text: root.count + " 条记录"
        color: Appearance.colors.colOnSurfaceVariant
        font.family: Sizes.fontFamilyMono
        font.pixelSize: 11
        opacity: 0.6
        visible: root.count > 0
    }

    // -----------------------------------------------------------
    // 剪贴板条目列表
    // -----------------------------------------------------------
    StyledListView {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.count > 0
        clip: true
        spacing: 6
        model: root.filteredEntries
        interactive: true
        showVerticalScrollBar: false
        smoothWheelEnabled: true

        delegate: Rectangle {
            id: delegateRoot

            required property var modelData

            width: ListView.view ? ListView.view.width : 0
            height: Math.max(52, contentCol.implicitHeight + 20)
            radius: 12
            color: delegateMouse.containsMouse
                ? Appearance.colors.colLayer3
                : Appearance.colors.colLayer2
            Behavior on color { ColorAnimation { duration: 150 } }

            // 复制成功高亮边框
            readonly property bool justCopied: root.copiedId === modelData.id
            border.width: justCopied ? 1.5 : 0
            border.color: Appearance.colors.colPrimary
            Behavior on border.width { NumberAnimation { duration: 200 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // ID 徽章
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    radius: 8
                    color: delegateRoot.justCopied
                        ? Appearance.colors.colPrimaryContainer
                        : Appearance.colors.colLayer4

                    Text {
                        anchors.centerIn: parent
                        text: (modelData.id !== undefined) ? String(modelData.id) : "·"
                        color: delegateRoot.justCopied
                            ? Appearance.colors.colOnPrimaryContainer
                            : Appearance.colors.colOnSurfaceVariant
                        font.family: Sizes.fontFamilyMono
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                // 预览文本
                ColumnLayout {
                    id: contentCol
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: modelData.preview || "(空内容)"
                        color: Appearance.colors.colOnSurface
                        font.family: Sizes.fontFamilyMono
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WrapAnywhere
                    }

                }

                // 操作按钮组
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    // 复制按钮
                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        Text {
                            anchors.centerIn: parent
                            text: delegateRoot.justCopied ? "\ued7a" : "content_copy"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: delegateRoot.justCopied
                                ? Appearance.colors.colPrimary
                                : (copyMouse.containsMouse
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colOnSurfaceVariant)
                            opacity: copyMouse.containsMouse || delegateRoot.justCopied ? 1 : 0.6
                        }

                        MouseArea {
                            id: copyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ClipboardService.copyToClipboard(modelData.id)
                                root.copiedId = modelData.id
                                root.copyFeedbackTimer.restart()
                            }
                        }

                        PopupToolTip {
                            extraVisibleCondition: copyMouse.containsMouse
                            text: "复制到剪贴板"
                        }
                    }

                    // 删除按钮
                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        Text {
                            anchors.centerIn: parent
                            text: "delete"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: deleteMouse.containsMouse
                                ? Appearance.colors.colError
                                : Appearance.colors.colOnSurfaceVariant
                            opacity: deleteMouse.containsMouse ? 1 : 0.5
                        }

                        MouseArea {
                            id: deleteMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ClipboardService.deleteItem(modelData.id)
                        }

                        PopupToolTip {
                            extraVisibleCondition: deleteMouse.containsMouse
                            text: "删除此条目"
                        }
                    }
                }
            }

            MouseArea {
                id: delegateMouse
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // 点击行本身 = 复制
                onClicked: {
                    ClipboardService.copyToClipboard(modelData.id)
                    root.copiedId = modelData.id
                    root.copyFeedbackTimer.restart()
                }
            }
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0; to: 1
                    duration: 200
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.95; to: 1
                    duration: 220
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.6
                }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1; to: 0
                    duration: 160
                }
                NumberAnimation {
                    property: "scale"
                    from: 1; to: 0.95
                    duration: 160
                }
            }
        }
    }
}
