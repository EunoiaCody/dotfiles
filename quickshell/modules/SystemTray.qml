import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray // Correct import
import ".." as Root

PanelWindow {
    id: root

    property var modelData
    screen: modelData

    anchors {
        top: true
        right: true
    }

    exclusiveZone: -1
    margins {
        top: 0
        right: 258
    }

    implicitWidth: trayPill.width + 4
    implicitHeight: trayPill.height + 12
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top

    // We'll use the local TrayMenu.qml for styled menus (see Modules/Bar/Tray/TrayMenu.qml)

    Rectangle {
        id: trayPill
        anchors.centerIn: parent
        width: trayRow.width + 12
        height: 40
        radius: height / 2
        color: Root.Color.base
        // visible: SystemTray.items.count > 0

        RowLayout {
            id: trayRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 6
            height: parent.height - 12
            spacing: 4

            Repeater {
                model: SystemTray.items // Correct model

                Item {
                    id: delegate
                    width: height
                    height: trayRow.height

                    // Use Image directly with the item's icon property
                    Image {
                        anchors.fill: parent
                        anchors.margins: 4 // A bit of padding for the icon
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        // --- 互斥逻辑: 关闭其他托盘图标的菜单 ---
                        function closeOtherMenus() {
                            var siblings = delegate.parent.children
                            for (var i = 0; i < siblings.length; i++) {
                                var s = siblings[i]
                                if (s === delegate) continue
                                if (s.trayMenuItem && typeof s.trayMenuItem.close === "function") {
                                    s.trayMenuItem.close()
                                } else if (s.trayMenuItem) {
                                    s.trayMenuItem.visible = false
                                }
                            }
                        }

                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                // Prefer platform menu if available
                                try {
                                    if (modelData && typeof modelData.display === 'function' && delegate.window) {
                                        var g = delegate.mapToItem(null, mouse.x, mouse.y)
                                        modelData.display(delegate.window, g.x, g.y)
                                        mouse.accepted = true
                                        return
                                    }
                                } catch (e) {
                                    // fallback to styled menu below
                                }

                                if (!delegate.trayMenuItem || !delegate.trayMenuItem.visible) {
                                    closeOtherMenus()
                                    if (delegate.trayMenuItem) delegate.trayMenuItem.visible = true
                                } else {
                                    if (delegate.trayMenuItem && typeof delegate.trayMenuItem.close === 'function') {
                                        delegate.trayMenuItem.close()
                                    } else if (delegate.trayMenuItem) {
                                        delegate.trayMenuItem.visible = false
                                    }
                                }
                                mouse.accepted = true
                            } else if (mouse.button === Qt.LeftButton) {
                                modelData.activate()
                            }
                        }
                    }

                    // Styled menu loaded from repository via Loader (absolute path)
                    property var trayMenuItem: null
                    Loader {
                        id: trayMenuLoader
                        asynchronous: true
                        source: "file:///home/eunoia/.config/quickshell/modules/TrayMenu.qml"
                        onLoaded: {
                            if (item) {
                                item.rootMenuHandle = modelData.menu
                                item.trayName = modelData.tooltipTitle || modelData.id || "Menu"
                                // anchor is a property on the loaded item (PopupWindow)
                                if (item.anchor) {
                                    item.anchor.item = delegate
                                    item.anchor.rect.y = (delegate.mapToItem(null, 0, 0).y > 500) ? -item.implicitHeight - 5 : delegate.height + 5
                                    item.anchor.rect.x = 0
                                }
                                item.visible = false
                                delegate.trayMenuItem = item
                            }
                        }
                    }
                }
            }
        }
    }
}
