import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Widgets.common
import qs.Common
import qs.Widgets.audio
import qs.Services

WidgetPanel {
    id: root
    title: "音频设备"
    icon: "speaker_group"
    closeAction: () => WidgetState.qsOpen = false

    contentImplicitHeight: 640
    property bool isActive: WidgetState.qsOpen && WidgetState.qsView === "audio"

    headerTools: Text {
        text: "\uf013"
        font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 20
        color: Appearance.colors.colOnLayer1
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Volume.openMixer() }
    }

    property var defaultSink: Pipewire.defaultAudioSink
    property var defaultSource: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    PwNodeLinkTracker { id: appTracker; node: root.defaultSink }

    // ============================================================
    // 【输出设备】
    // ============================================================
    Text {
        text: "输出设备"
        font.pixelSize: 13; font.bold: true
        color: Appearance.colors.colOnLayer1
        Layout.topMargin: 4
    }

    // 直接用 Pipewire.nodes 作为模型，在委托里过滤
    StyledListView {
        id: sinkList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(sinkList.contentHeight, 240)
        clip: true; spacing: 0
        model: Pipewire.nodes
        interactive: contentHeight > 240

        delegate: Item {
            id: sinkWrapper
            required property var modelData
            readonly property var nodeItem: modelData
            readonly property bool matches: nodeItem && nodeItem.isSink && !nodeItem.isStream

            width: ListView.view.width
            height: matches ? 72 : 0
            visible: matches

            AudioDeviceRow {
                anchors.fill: parent
                anchors.margins: 4
                node: sinkWrapper.nodeItem
                isActive: sinkWrapper.nodeItem === root.defaultSink
                deviceLabel: "输出"
                onClicked: { if (sinkWrapper.nodeItem) Volume.switchSink(sinkWrapper.nodeItem) }
            }
        }
    }

    // ============================================================
    // 【输入设备】
    // ============================================================
    Text {
        text: "输入设备"
        font.pixelSize: 13; font.bold: true
        color: Appearance.colors.colOnLayer1
        Layout.topMargin: 12
    }

    StyledListView {
        id: sourceList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(sourceList.contentHeight, 160)
        clip: true; spacing: 0
        model: Pipewire.nodes
        interactive: contentHeight > 160

        delegate: Item {
            id: sourceWrapper
            required property var modelData
            readonly property var nodeItem: modelData
            readonly property bool matches: nodeItem && !nodeItem.isSink && !nodeItem.isStream && nodeItem.audio

            width: ListView.view.width
            height: matches ? 72 : 0
            visible: matches

            AudioDeviceRow {
                anchors.fill: parent
                anchors.margins: 4
                node: sourceWrapper.nodeItem
                isActive: sourceWrapper.nodeItem === root.defaultSource
                deviceLabel: "输入"
                onClicked: { if (sourceWrapper.nodeItem) Volume.switchSource(sourceWrapper.nodeItem) }
            }
        }
    }

    // ============================================================
    // 【应用程序音量】
    // ============================================================
    Text {
        text: "应用程序"
        font.pixelSize: 13; font.bold: true
        color: Appearance.colors.colOnLayer1
        Layout.topMargin: 12
    }

    StyledListView {
        id: appList
        Layout.fillWidth: true; Layout.fillHeight: true
        Layout.preferredHeight: Math.max(60, implicitHeight)
        clip: true; spacing: 12
        model: appTracker.linkGroups
        animateAppearance: false
        animateMovement: false
        interactive: false

        delegate: Rectangle {
            required property PwLinkGroup modelData
            property var appNode: modelData.source

            width: ListView.view.width; height: 68
            radius: 12; color: "transparent"
            border.width: 1; border.color: "transparent"
            PwObjectTracker { objects: [ appNode ] }

            RowLayout {
                anchors.fill: parent; anchors.margins: 14; spacing: 14

                Image {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                    visible: source != ""
                    source: {
                        const iconProperty = (appNode.properties["application.icon-name"] || "").toLowerCase();
                        const binaryName = (appNode.properties["application.process.binary"] || "").toLowerCase();
                        const iconMap = {
                            "zen": "zen-browser",
                            "zen-bin": "zen-browser",
                            "zen-alpha": "zen-browser",
                            "splayer": "file:///usr/share/icons/hicolor/512x512/apps/SPlayer.png"
                        };
                        let finalIcon = iconMap[binaryName] || iconMap[iconProperty] || iconProperty || binaryName || "audio-card";
                        if (finalIcon.startsWith("file://") || finalIcon.startsWith("/"))
                            return finalIcon.startsWith("/") ? "file://" + finalIcon : finalIcon;
                        return `image://icon/${finalIcon}`;
                    }
                    onStatusChanged: { if (status === Image.Error) source = "image://icon/audio-card"; }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: appNode.properties["application.name"] || appNode.name; font.bold: true; font.pixelSize: 14; color: Appearance.colors.colOnLayer2; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    Item {
                        Layout.fillWidth: true; height: 16
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 6; radius: 3
                            color: Qt.rgba(Appearance.colors.colOnLayer2.r, Appearance.colors.colOnLayer2.g, Appearance.colors.colOnLayer2.b, 0.1)
                            Rectangle { height: parent.height; width: parent.width * appNode.audio.volume; radius: 3; color: Appearance.colors.colPrimary }
                        }
                        Rectangle {
                            width: 6; height: 16; radius: 3; color: Appearance.colors.colOnLayer2
                            x: Math.max(0, Math.min(parent.width * appNode.audio.volume - width / 2, parent.width - width))
                            anchors.verticalCenter: parent.verticalCenter
                            Item {
                                width: 32; height: 32
                                anchors.bottom: parent.top; anchors.bottomMargin: 4; anchors.horizontalCenter: parent.horizontalCenter
                                visible: sliderMouseArea.containsMouse || sliderMouseArea.pressed
                                Rectangle {
                                    anchors.fill: parent; radius: 16; color: Appearance.colors.colPrimary; rotation: 45
                                    Rectangle { width: 16; height: 16; x: 16; y: 16; color: parent.color }
                                }
                                Text { anchors.centerIn: parent; text: Math.round(appNode.audio.volume * 100); color: Appearance.colors.colLayer1; font.pixelSize: 11; font.bold: true }
                            }
                        }
                        MouseArea {
                            id: sliderMouseArea; anchors.fill: parent;
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            function updateVolume(mouse) {
                                let v = mouse.x / width;
                                if (v < 0) v = 0; if (v > 1) v = 1;
                                appNode.audio.volume = v
                            }
                            onPressed: (mouse) => updateVolume(mouse)
                            onPositionChanged: (mouse) => { if (pressed) updateVolume(mouse) }
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // 【设备行组件】（内联）
    // ============================================================
    component AudioDeviceRow: Rectangle {
        id: deviceRow

        property var node: null
        property bool isActive: false
        property string deviceLabel: ""
        signal clicked()

        readonly property bool isSinkDevice: node && node.isSink
        readonly property string nodeDesc: node ? (node.description || node.name || "未知设备") : ""
        readonly property string deviceIcon: {
            if (!node) return "\uf028"
            if (Volume.nodeIsHeadphone(node)) return "\uf025"
            if (isSinkDevice) return "\uf028"
            return "\uf130"
        }

        height: 64
        radius: 12
        color: isActive ? Appearance.colors.colLayer2 : (hoverArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent")
        border.width: isActive ? 1 : 0
        border.color: isActive ? Appearance.colors.colPrimary : "transparent"

        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: deviceRow.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Text {
                text: deviceRow.deviceIcon
                font.family: "Font Awesome 6 Free Solid"
                font.pixelSize: 20
                color: isActive ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 160 } }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: deviceRow.nodeDesc
                    font.bold: true; font.pixelSize: 14
                    color: Appearance.colors.colOnLayer2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: isActive ? ("当前" + deviceRow.deviceLabel + "设备") : "点击切换"
                    font.pixelSize: 11
                    color: isActive ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            Text {
                text: isActive ? "check_circle" : (hoverArea.containsMouse ? "swap_horiz" : "")
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: isActive ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
