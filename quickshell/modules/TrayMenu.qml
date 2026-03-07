import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import ".." as Root

PopupWindow {
    id: root

    property var rootMenuHandle: null
    property string trayName: ""

    implicitWidth: 280
    implicitHeight: Math.min(640, headerRect.implicitHeight + flickArea.contentHeight + 36)
    color: "transparent"

    // Appear animation (dropdown from above)
    ParallelAnimation {
        id: popupIn
        running: false
        NumberAnimation { id: animY; target: bg; property: "y"; duration: 340; easing.type: Easing.OutBack }
        NumberAnimation { id: animOpacity; target: bg; property: "opacity"; duration: 220; from: 0; to: 1; easing.type: Easing.OutCubic }
    }

    // Close animation (reverse of popupIn)
    ParallelAnimation {
        id: popupOut
        running: false
        NumberAnimation { target: bg; property: "y"; duration: 240; to: -12; easing.type: Easing.InCubic }
        NumberAnimation { target: bg; property: "opacity"; duration: 180; to: 0; easing.type: Easing.InCubic }
        onStopped: {
            root.visible = false
        }
    }

    function close() {
        if (!root.visible) return
        if (popupIn.running) popupIn.stop()
        popupOut.start()
    }

    onVisibleChanged: {
        if (visible) {
            menuStack.clear()
            if (bg) bg.opacity = 0
                var finalY = 0
                bg.y = -12
                animY.to = finalY
                popupIn.start()
        }
    }

    // --- state stack ---
    ListModel { id: menuStack }

    property var currentSubMenuHandle: {
        if (menuStack.count === 0) return null
        return menuStack.get(menuStack.count - 1).handle
    }

    QsMenuOpener { id: rootOpener; menu: root.rootMenuHandle }
    QsMenuOpener { id: subOpener; menu: root.currentSubMenuHandle }

    QsMenuAnchor {
        id: hydrator
        anchor.window: root
        anchor.item: mainLayout
        anchor.rect.x: root.width/2
        anchor.rect.y: root.height/2
        anchor.rect.width: 1
        anchor.rect.height: 1
    }

    function navigateToSubmenu(menuHandle, menuText) {
        if (!menuHandle) return
        menuStack.append({ "handle": menuHandle, "title": menuText })
        try {
            if (typeof menuHandle.aboutToShow === "function") menuHandle.aboutToShow()
            if (typeof menuHandle.updateLayout === "function") menuHandle.updateLayout()
            hydrator.menu = menuHandle
            hydrator.open()
            hydrator.close()
        } catch (e) {
            console.warn("Hydrator error:", e)
        }
    }

    function navigateBack() {
        if (menuStack.count > 0) menuStack.remove(menuStack.count - 1, 1)
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Root.Color.base
        radius: 12
        border.width: 3
        border.color: Root.Color.lavender
        clip: true

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                id: headerRect
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: "transparent"

                Text {
                    text: (menuStack.count === 0) ? (root.trayName || "Menu") : menuStack.get(menuStack.count - 1).title
                    anchors.centerIn: parent
                    font.bold: true
                    color: Root.Color.lavender
                    font.pixelSize: 18
                    width: parent.width - 60
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                // Back button for submenus
                Rectangle {
                    visible: menuStack.count > 0
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    radius: width / 2
                    color: backMouse.containsMouse ? Root.Color.surface1 : "transparent"

                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        font.pixelSize: 20
                        color: Root.Color.overlay1
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.navigateBack()
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Root.Color.overlay0
                    opacity: 0.18
                }
            }

            // Scrollable menu items area
            Flickable {
                id: flickArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8
                contentHeight: menuItemsCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: menuItemsCol
                    width: flickArea.width
                    spacing: 6

                    property var currentModel: (menuStack.count === 0) ? (rootOpener.children ? rootOpener.children.values : []) : (subOpener.children ? subOpener.children.values : [])

                    Text {
                        visible: (!parent.currentModel || parent.currentModel.length === 0)
                        text: (menuStack.count > 0) ? "Loading..." : "No Items"
                        color: Root.Color.subtext0
                        font.italic: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.margins: 10
                    }

                    Repeater {
                        model: parent.currentModel
                        delegate: Rectangle {
                            id: menuItem
                            property bool isSeparator: (modelData.isSeparator === true || modelData.text === "")
                            property bool hasSubMenu: (modelData.hasChildren === true)
                            property var effectiveHandle: (modelData.menu) ? modelData.menu : modelData
                            property int hoverOffset: 0

                            Layout.fillWidth: true
                            Layout.preferredHeight: isSeparator ? 10 : 44
                            radius: 10
                            color: isSeparator ? "transparent" : (menuItem.hoverOffset !== 0 ? Root.Color.surface1 : Root.Color.mantle)

                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            RowLayout {
                                visible: !parent.isSeparator
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                Item { Layout.preferredWidth: 18; Layout.preferredHeight: 18; visible: (modelData.icon||"") !== "";
                                    Image { anchors.fill: parent; source: modelData.icon || ""; fillMode: Image.PreserveAspectFit }
                                }

                                Text {
                                    text: modelData.text || ""
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    color: (modelData.enabled === false) ? Root.Color.overlay1 : Root.Color.text
                                    font.pixelSize: 15
                                }

                                Text { visible: hasSubMenu; text: "›"; font.pixelSize: 18; color: Root.Color.overlay1 }
                            }

                            MouseArea {
                                id: itemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: modelData.enabled !== false

                                onEntered: { menuItem.hoverOffset = -4 }
                                onExited: { menuItem.hoverOffset = 0 }

                                onPressed: {
                                    if (!hasSubMenu) {
                                        if (typeof modelData.triggered === 'function') modelData.triggered();
                                        root.visible = false
                                    }
                                }

                                onClicked: {
                                    if (hasSubMenu) root.navigateToSubmenu(effectiveHandle, modelData.text)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
