import QtQuick
import Quickshell
import qs.Services
import qs.Common
import qs.Widgets.common

// Bluetooth button — simple icon like tray items, same style as
// the Network button. No background, no hover expansion.
// Click opens the bluetooth panel in the RightSidebar.
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
 if (!BluetoothService.available) return "󰂲";
 if (BluetoothService.connected) return "󰂱";
 if (BluetoothService.enabled) return "󰂯";
 return "󰂲";
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
 if (WidgetState.qsOpen && WidgetState.qsView === "bluetooth") {
 WidgetState.qsOpen = false;
 } else {
 WidgetState.qsView = "bluetooth";
 WidgetState.qsOpen = true;
 }
 }

 PopupToolTip {
 extraVisibleCondition: root.containsMouse
 text: {
 if (!BluetoothService.available)
 return "蓝牙不可用\n点击查看详情";
 if (BluetoothService.connected)
 return "蓝牙: 已连接 " + (BluetoothService.connectedName || "")
 + "\n点击查看蓝牙设置";
 if (BluetoothService.enabled)
 return "蓝牙: 已开启\n点击查看蓝牙设置";
 return "蓝牙: 已关闭\n点击查看蓝牙设置";
 }
 }
}
