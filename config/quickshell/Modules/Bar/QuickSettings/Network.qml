import QtQuick
import Quickshell
import qs.Services
import qs.Common
import qs.Widgets.common

// Network button — simple icon like tray items.
// No background, no hover expansion. Click opens network panel.
MouseArea {
    id: root

    property var screen: null

    implicitWidth: 20
    implicitHeight: 20
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Text {
        anchors.centerIn: parent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: Appearance.colors.colOnLayer0
        text: {
            if (Network.activeConnectionType === "ETHERNET") return "󰈀";
            if (!Network.connected) return "󰤭";
            const s = Network.signalStrength;
            if (s >= 80) return "󰤨";
            if (s >= 60) return "󰤥";
            if (s >= 40) return "󰤢";
            if (s >= 20) return "󰤟";
            return "󰤯";
        }
    }

    onClicked: {
        const gpos = root.mapToGlobal(0, 0);
        WidgetState.qsAnchorGlobalX = gpos.x;
        WidgetState.qsAnchorGlobalY = gpos.y;
        WidgetState.qsAnchorWidth = root.width;
        WidgetState.qsAnchorHeight = root.height;
        if (root.screen && root.screen.name)
            WidgetState.qsScreenName = root.screen.name;
        if (WidgetState.qsOpen && WidgetState.qsView === "network") {
            WidgetState.qsOpen = false;
        } else {
            WidgetState.qsView = "network";
            WidgetState.qsOpen = true;
        }
    }

    PopupToolTip {
        extraVisibleCondition: root.containsMouse
        text: Network.connected
              ? ((Network.activeConnection || "网络已连接") + "\n点击打开网络设置")
              : "网络未连接\n点击打开网络设置"
    }
}
