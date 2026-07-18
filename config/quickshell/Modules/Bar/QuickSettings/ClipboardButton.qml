import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets.common

// ============================================================
// ClipboardButton — 剪贴板快捷按钮
// ============================================================
// 在顶栏 QuickSettings 区域显示剪贴板图标。
// 点击切换 RightSidebar 的剪贴板历史面板。
// 参照 NotificationButton 的模式实现。
// ============================================================

MouseArea {
    id: root

    property var screen: null

    implicitWidth: 20
    implicitHeight: 20
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    property bool hasEntries: ClipboardService.entryCount > 0
    property color iconColor: WidgetState.qsView === "clipboard"
        ? Appearance.colors.colPrimary
        : (hasEntries
            ? Appearance.colors.colPrimary
            : Appearance.colors.colOnLayer0)

    Text {
        anchors.centerIn: parent
        text: "\uf07f"            // Nerd Font save (nf-fa-floppy_o)
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: root.iconColor
    }

    // 数量角标（有内容时显示）
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -2
        anchors.rightMargin: -4
        width: 14; height: 14
        radius: 7
        color: Appearance.colors.colPrimary
        visible: root.hasEntries && WidgetState.qsView !== "clipboard"
        opacity: 0.9

        Text {
            anchors.centerIn: parent
            text: Math.min(ClipboardService.entryCount, 99).toString()
            color: Appearance.colors.colOnPrimary
            font.family: Sizes.fontFamilyMono
            font.pixelSize: 9
            font.bold: true
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

        if (WidgetState.qsOpen && WidgetState.qsView === "clipboard") {
            WidgetState.qsOpen = false;
        } else {
            WidgetState.qsView = "clipboard";
            WidgetState.qsOpen = true;
        }
    }

    PopupToolTip {
        extraVisibleCondition: root.containsMouse
        text: root.hasEntries
            ? "剪贴板 · " + ClipboardService.entryCount + " 条记录\n点击查看历史"
            : "剪贴板\n点击查看历史"
    }
}
