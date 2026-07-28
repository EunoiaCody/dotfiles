import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets.common

// QuickSettingsPanel — exact copy of TrayMenu.qml structure and positioning.
// The content inside is network/audio/settings views instead of tray entries.
Item {
    id: root

    property var anchorItem: null
    property var screen: null
    property bool menuOpen: false
    property real padding: 10
    property real edgeMargin: 10
    property real anchorGap: 4
    property real menuX: edgeMargin
    property real menuY: edgeMargin

    signal menuClosed()

    function open() { menuOpen = true; }
    function close() { menuOpen = false; }

    Connections {
        target: WidgetState
        function onQsOpenChanged() {
            if (root.menuOpen !== WidgetState.qsOpen)
                root.menuOpen = WidgetState.qsOpen;
        }
        function onQsViewChanged() {
            Qt.callLater(() => rootWindow.updatePosition());
        }
    }

    PanelWindow {
        id: rootWindow

        visible: root.menuOpen
        screen: root.screen
        color: "transparent"
        exclusiveZone: -1

        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "clavis-quick-settings"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        mask: Region { item: inputRegion }

        function clamp(value, minimum, maximum) {
            return Math.max(minimum, Math.min(maximum, value));
        }

        function updatePosition() {
            const surfaceWidth = Math.max(1, menuSurface.implicitWidth);
            const surfaceHeight = Math.max(1, menuSurface.implicitHeight);
            const availableWidth = Math.max(surfaceWidth + root.edgeMargin * 2, rootWindow.width);
            const availableHeight = Math.max(surfaceHeight + root.edgeMargin * 2, rootWindow.height);

            // Use WidgetState anchor if available (set by the clicked button),
            // fall back to anchorItem
            let anchorX, anchorY, anchorWidth, anchorHeight;
            const screenX = root.screen ? (root.screen.x || 0) : 0;
            const screenY = root.screen ? (root.screen.y || 0) : 0;

            if (WidgetState.qsAnchorGlobalX !== 0 || WidgetState.qsAnchorGlobalY !== 0) {
                anchorX = WidgetState.qsAnchorGlobalX - screenX;
                anchorY = WidgetState.qsAnchorGlobalY - screenY;
                anchorWidth = WidgetState.qsAnchorWidth || 0;
                anchorHeight = WidgetState.qsAnchorHeight || 0;
            } else if (root.anchorItem) {
                const globalPos = root.anchorItem.mapToGlobal(0, 0);
                anchorX = globalPos.x - screenX;
                anchorY = globalPos.y - screenY;
                anchorWidth = root.anchorItem.width || 0;
                anchorHeight = root.anchorItem.height || 0;
            } else {
                root.menuX = rootWindow.clamp((availableWidth - surfaceWidth) / 2, root.edgeMargin, availableWidth - surfaceWidth - root.edgeMargin);
                root.menuY = root.edgeMargin;
                return;
            }

            root.menuX = rootWindow.clamp(
                anchorX + anchorWidth / 2 - surfaceWidth / 2,
                root.edgeMargin,
                availableWidth - surfaceWidth - root.edgeMargin
            );

            const belowY = anchorY + anchorHeight + root.anchorGap;
            const aboveY = anchorY - surfaceHeight - root.anchorGap;
            const maxY = availableHeight - surfaceHeight - root.edgeMargin;
            root.menuY = belowY <= maxY || aboveY < root.edgeMargin
                ? rootWindow.clamp(belowY, root.edgeMargin, maxY)
                : rootWindow.clamp(aboveY, root.edgeMargin, maxY);
        }

        onVisibleChanged: {
            if (visible) {
                Qt.callLater(() => {
                    rootWindow.updatePosition();
                    keyScope.forceActiveFocus();
                });
            }
        }

        Item {
            id: inputRegion
            anchors.fill: parent
        }

        MouseArea {
            anchors.fill: parent
            enabled: rootWindow.visible
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            z: -1

            onClicked: event => {
                const outsideMenu = event.x < menuSurface.x
                    || event.x > menuSurface.x + menuSurface.width
                    || event.y < menuSurface.y
                    || event.y > menuSurface.y + menuSurface.height;
                if (outsideMenu) {
                    root.close();
                    WidgetState.qsOpen = false;
                }
            }
        }

        FocusScope {
            id: keyScope

            anchors.fill: parent
            focus: rootWindow.visible

            Keys.onEscapePressed: event => {
                root.close();
                WidgetState.qsOpen = false;
                event.accepted = true;
            }

            Item {
                id: menuSurface

                x: root.menuX
                y: root.menuY
                implicitWidth: popupBackground.implicitWidth + root.padding * 2
                implicitHeight: popupBackground.implicitHeight + root.padding * 2
                width: implicitWidth
                height: implicitHeight

                onImplicitWidthChanged: Qt.callLater(rootWindow.updatePosition)
                onImplicitHeightChanged: Qt.callLater(rootWindow.updatePosition)

                StyledRectangularShadow {
                    target: popupBackground
                    opacity: popupBackground.opacity
                }

                Rectangle {
                    id: popupBackground

                    readonly property real popupPadding: 4

                    x: root.padding
                    y: root.padding
                    implicitWidth: Math.min(viewStack.implicitWidth + popupPadding * 2, 320)
                    implicitHeight: viewStack.implicitHeight + popupPadding * 2
                    color: Appearance.colors.colLayer0
                    radius: 18
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    clip: true
                    opacity: 0

                    Component.onCompleted: opacity = 1

                    Behavior on opacity {
                        NumberAnimation {
                            alwaysRunToEnd: true
                            duration: Appearance.animation.expressiveEffects.duration
                            easing.type: Appearance.animation.expressiveEffects.type
                            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                        }
                    }
                    Behavior on implicitWidth {
                        NumberAnimation {
                            alwaysRunToEnd: true
                            duration: Appearance.animation.elementResize.duration
                            easing.type: Appearance.animation.elementResize.type
                            easing.bezierCurve: Appearance.animation.elementResize.bezierCurve
                        }
                    }
                    Behavior on implicitHeight {
                        NumberAnimation {
                            alwaysRunToEnd: true
                            duration: Appearance.animation.elementResize.duration
                            easing.type: Appearance.animation.elementResize.type
                            easing.bezierCurve: Appearance.animation.elementResize.bezierCurve
                        }
                    }

                    // ===== Content =====
                    ColumnLayout {
                        id: viewStack

                        anchors {
                            fill: parent
                            margins: popupBackground.popupPadding
                        }
                        spacing: 0

                        // Title bar
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            Layout.leftMargin: 10
                            Layout.rightMargin: 6
                            Layout.bottomMargin: 4
                            spacing: 8

                            Text {
                                text: viewTitle()
                                color: Appearance.colors.colOnLayer0
                                font.pixelSize: 14
                                font.bold: true
                                font.family: Sizes.fontFamily
                                Layout.fillWidth: true
                            }

                            MaterialRippleButton {
                                id: closeBtn
                                implicitWidth: 28
                                implicitHeight: 28
                                buttonRadius: 14
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                rippleEnabled: false

                                contentItem: Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 14
                                    color: Appearance.colors.colOnLayer0
                                }

                                releaseAction: () => {
                                    root.close();
                                    WidgetState.qsOpen = false;
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Appearance.colors.colSubtext
                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                        }

                        // View content
                        Loader {
                            id: viewLoader
                            Layout.fillWidth: true
                            sourceComponent: viewComponent()
                        }
                    }
                }
            }
        }
    }

    function viewTitle() {
        switch (WidgetState.qsView) {
        case "network": return "网络";
        case "audio": return "音频";
        case "settings": return "设置";
        default: return "快速设置";
        }
    }

    function viewComponent() {
        switch (WidgetState.qsView) {
        case "network": return networkViewComp;
        case "audio": return audioViewComp;
        case "settings": return settingsViewComp;
        default: return null;
        }
    }

    // =========================== Network view ===========================
    Component {
        id: networkViewComp
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
                implicitHeight: 40
                Layout.leftMargin: 10
                Layout.rightMargin: 10

                RowLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 10

                    Rectangle {
                        implicitWidth: 8; implicitHeight: 8; radius: 4
                        color: Network.connected ? Appearance.colors.colPrimary : Appearance.colors.colError
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: Network.connected ? (Network.activeConnection || "已连接") : "未连接"
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: 13; font.family: Sizes.fontFamily
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            MaterialRippleButton {
                Layout.fillWidth: true
                implicitHeight: 36
                buttonRadius: 14
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colSecondaryContainer
                colRipple: Appearance.colors.colSecondaryContainerActive
                rippleEnabled: false

                contentItem: RowLayout {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10 }
                    spacing: 10

                    Text {
                        text: "󰈀"
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                        color: parent.parent.pointerHovered ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: "打开网络管理器"
                        color: parent.parent.pointerHovered ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                        font.family: Sizes.fontFamily; font.pixelSize: 13
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                    }
                }

                releaseAction: () => Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }

    // =========================== Audio view ===========================
    Component {
        id: audioViewComp
        ColumnLayout {
            id: audioRoot
            spacing: 0
            Layout.fillWidth: true

            // 输出设备列表
            Text {
                text: "输出设备"; font.pixelSize: 11; font.bold: true
                color: Appearance.colors.colOnLayer0; Layout.topMargin: 4
                Layout.leftMargin: 10; Layout.rightMargin: 10
            }

            // 直接用 Pipewire.nodes，Repeater 中过滤
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10; Layout.rightMargin: 10
                spacing: 2

                Repeater {
                    id: sinkRepeater
                    model: Pipewire.nodes
                    delegate: Rectangle {
                        required property var modelData
                        readonly property var node: modelData
                        readonly property bool matches: node && node.isSink && !node.isStream
                        readonly property bool active: matches && node === Pipewire.defaultAudioSink
                        readonly property string desc: matches ? (node.description || node.name || "未知") : ""

                        Layout.fillWidth: true
                        implicitHeight: matches ? 32 : 0
                        visible: matches
                        radius: 8
                        color: active ? Appearance.colors.colLayer2 : (hoverArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: hoverArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (node) Volume.switchSink(node) }
                        }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 6; spacing: 8
                            Text {
                                text: active ? "\u25c9" : "\u25cb"
                                font.pixelSize: 12
                                color: active ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            }
                            Text {
                                text: desc; font.pixelSize: 12; elide: Text.ElideRight
                                color: active ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            // 输入设备列表
            Text {
                text: "输入设备"; font.pixelSize: 11; font.bold: true
                color: Appearance.colors.colOnLayer0; Layout.topMargin: 8
                Layout.leftMargin: 10; Layout.rightMargin: 10
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10; Layout.rightMargin: 10
                spacing: 2

                Repeater {
                    id: sourceRepeater
                    model: Pipewire.nodes
                    delegate: Rectangle {
                        required property var modelData
                        readonly property var node: modelData
                        readonly property bool matches: node && !node.isSink && !node.isStream && node.audio
                        readonly property bool active: matches && node === Pipewire.defaultAudioSource
                        readonly property string desc: matches ? (node.description || node.name || "未知") : ""

                        Layout.fillWidth: true
                        implicitHeight: matches ? 32 : 0
                        visible: matches
                        radius: 8
                        color: active ? Appearance.colors.colLayer2 : (hoverArea2.containsMouse ? Appearance.colors.colLayer1Hover : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: hoverArea2; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (node) Volume.switchSource(node) }
                        }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 6; spacing: 8
                            Text {
                                text: active ? "\u25c9" : "\u25cb"
                                font.pixelSize: 12
                                color: active ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            }
                            Text {
                                text: desc; font.pixelSize: 12; elide: Text.ElideRight
                                color: active ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            // 按钮栏
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 1; color: Appearance.colors.colSubtext
                Layout.topMargin: 8; Layout.bottomMargin: 4
            }

            MaterialRippleButton {
                Layout.fillWidth: true
                implicitHeight: 34
                buttonRadius: 14
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colSecondaryContainer
                colRipple: Appearance.colors.colSecondaryContainerActive
                rippleEnabled: false

                contentItem: RowLayout {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10 }
                    spacing: 10

                    Text {
                        text: "󰓃"
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                        color: parent.parent.pointerHovered ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: "打开音频控制面板"
                        color: parent.parent.pointerHovered ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                        font.family: Sizes.fontFamily; font.pixelSize: 13
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                    }
                }

                releaseAction: () => Quickshell.execDetached(["pavucontrol"])
            }
        }
    }

    // =========================== Settings view ===========================
    Component {
        id: settingsViewComp
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            MaterialRippleButton {
                Layout.fillWidth: true
                implicitHeight: 36
                buttonRadius: 14
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colSecondaryContainer
                colRipple: Appearance.colors.colSecondaryContainerActive
                rippleEnabled: false

                contentItem: RowLayout {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10 }
                    spacing: 10

                    Text {
                        text: "󰌾"
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                        color: parent.parent.pointerHovered ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: "锁定屏幕"
                        color: parent.parent.pointerHovered ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                        font.family: Sizes.fontFamily; font.pixelSize: 13
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                    }
                }

                releaseAction: () => {
                    WidgetState.qsOpen = false;
                    root.close();
                    Quickshell.execDetached(["loginctl", "lock-session"]);
                }
            }
        }
    }
}
