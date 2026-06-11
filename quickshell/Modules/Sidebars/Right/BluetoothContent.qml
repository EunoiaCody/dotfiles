import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import Quickshell
import Quickshell.Bluetooth
import qs.Services
import qs.Common
import qs.Widgets.common

// BluetoothContent — paired/expandable view of the Bluetooth stack,
// modelled after NetworkContent.qml so the panel feels consistent.
//
// Layout (top → bottom):
//1. Header toolbar: master switch + scan button
//2. Scanning progress strip (animates in while discovering)
//3. "Paired devices" section with the full list of paired/trusted
// devices; each row toggles connect/disconnect.
//4. "Available devices" section listing newly discovered hardware;
// each row pairs + connects.
//5. Empty states for "Bluetooth unavailable", "Bluetooth off",
// "Nothing paired", "No devices nearby".
WidgetPanel {
 id: root
 title: "蓝牙"
 icon: "bluetooth"
 closeAction: () => WidgetState.qsOpen = false

 contentImplicitHeight:640

 property bool isActive: WidgetState.qsOpen && WidgetState.qsView === "bluetooth"
 property string mdFont: "Material Symbols Outlined"

 // When the panel opens, power the adapter on and kick off a scan
 // so users immediately see content (same UX as the network panel).
 onIsActiveChanged: {
 if (isActive) {
 if (BluetoothService.adapter && !BluetoothService.enabled)
 BluetoothService.adapter.enabled = true;
 BluetoothService.startScan();
 }
 }

 // Stop scanning whenever the panel is dismissed so we don't keep
 // the radio hot in the background.
 Connections {
 target: WidgetState
 function onQsOpenChanged() {
 if (!WidgetState.qsOpen && BluetoothService.discovering)
 BluetoothService.stopScan();
 }
 }

 headerTools: RowLayout {
 spacing:8

 // Master switch — mirrors the network panel's switch styling.
 Rectangle {
 id: mainSwitch
 width:44; height:24; radius:12
 color: BluetoothService.enabled ? Appearance.colors.colPrimary : "transparent"
 border.width: BluetoothService.enabled ?0 :2
 border.color: Appearance.colors.colOutline
 enabled: BluetoothService.available
 opacity: enabled ?1 :0.4
 Behavior on opacity { NumberAnimation { duration:200 } }
 Behavior on color { ColorAnimation { duration:250 } }

 Rectangle {
 width: BluetoothService.enabled ?16 :12
 height: BluetoothService.enabled ?16 :12
 radius: width /2
 x: BluetoothService.enabled ? parent.width - width -4 :6
 anchors.verticalCenter: parent.verticalCenter
 color: BluetoothService.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colOutline

 Behavior on x { NumberAnimation { duration:300; easing.type: Easing.OutCubic } }
 Behavior on width { NumberAnimation { duration:300; easing.type: Easing.OutCubic } }
 Behavior on height { NumberAnimation { duration:300; easing.type: Easing.OutCubic } }
 Behavior on color { ColorAnimation { duration:250 } }

 Text {
 anchors.centerIn: parent
 text: "check"
 font.family: root.mdFont
 font.pixelSize:12
 font.bold: true
 color: Appearance.colors.colPrimary
 opacity: BluetoothService.enabled ?1 :0
 Behavior on opacity { NumberAnimation { duration:200 } }
 }
 }

 MouseArea {
 anchors.fill: parent; cursorShape: Qt.PointingHandCursor
 enabled: BluetoothService.available
 onClicked: {
 if (!BluetoothService.adapter) return;
 BluetoothService.adapter.enabled = !BluetoothService.adapter.enabled;
 }
 }
 }

 // Scan / refresh button — disabled while already scanning.
 Rectangle {
 id: scanButton
 implicitWidth: scanButtonLabel.implicitWidth +24
 implicitHeight:28
 radius: height /2
 color: BluetoothService.discovering
 ? Appearance.colors.colPrimaryContainer
 : Appearance.colors.colLayer2
 enabled: BluetoothService.available && BluetoothService.enabled
 opacity: enabled ?1 :0.4
 Behavior on color { ColorAnimation { duration:140 } }
 Behavior on opacity { NumberAnimation { duration:200 } }

 Text {
 id: scanButtonLabel
 anchors.centerIn: parent
 text: BluetoothService.discovering ? "扫描中…" : "扫描"
 font.pixelSize:12
 font.bold: true
 color: BluetoothService.discovering
 ? Appearance.colors.colOnPrimaryContainer
 : Appearance.colors.colOnLayer2
 Behavior on color { ColorAnimation { duration:140 } }
 }

 MouseArea {
 anchors.fill: parent; cursorShape: Qt.PointingHandCursor
 enabled: scanButton.enabled && !BluetoothService.discovering
 onClicked: BluetoothService.startScan()
 }
 }
 }

 // ----- main content column -----
 ColumnLayout {
 Layout.fillWidth: true
 Layout.fillHeight: true
 spacing:12

 // Strip animates in when a scan is running, like NetworkContent's
 // indeterminate ProgressBar. Implemented as a3px-tall pill.
 Item {
 id: scanStrip
 Layout.fillWidth: true
 Layout.preferredHeight: BluetoothService.discovering ?4 :0
 opacity: BluetoothService.discovering ?1 :0

 Behavior on Layout.preferredHeight { NumberAnimation { duration:180; easing.type: Easing.OutCubic } }
 Behavior on opacity { NumberAnimation { duration:120 } }

 Rectangle {
 anchors.fill: parent
 radius: height /2
 color: Appearance.colors.colLayer2
 clip: true

 Rectangle {
 id: scanIndicator
 width: parent.width *0.35
 height: parent.height
 radius: height /2
 color: Appearance.colors.colPrimary
 x: -width

 NumberAnimation on x {
 from: -scanIndicator.width
 to: scanStrip.width
 duration:1100
 running: BluetoothService.discovering
 loops: Animation.Infinite
 easing.type: Easing.InOutQuad
 }
 }
 }
 }

 // Status banner when Bluetooth is unavailable or off.
 Rectangle {
 id: statusBanner
 Layout.fillWidth: true
 Layout.preferredHeight: statusBannerText.implicitHeight +24
 visible: !BluetoothService.available || !BluetoothService.enabled
 color: Appearance.colors.colLayer1
 radius:10

 Behavior on Layout.preferredHeight { NumberAnimation { duration:200; easing.type: Easing.OutCubic } }

 Text {
 id: statusBannerText
 anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin:14; rightMargin:14 }
 text: !BluetoothService.available
 ? "本机未检测到蓝牙适配器"
 : "蓝牙已关闭 —打开上方开关开始扫描附近的设备"
 color: Appearance.colors.colOnLayer1
 font.pixelSize:13
 wrapMode: Text.WordWrap
 }
 }

 // ===== Paired devices section =====
 ColumnLayout {
 Layout.fillWidth: true
 Layout.fillHeight: BluetoothService.pairedDevices.length >0 && !statusBanner.visible
 spacing:6
 visible: BluetoothService.available && BluetoothService.enabled

 Text {
 text: "已配对设备"
 color: Appearance.colors.colOnLayer1
 font.pixelSize:13
 font.bold: true
 }

 StyledListView {
 id: pairedList
 Layout.fillWidth: true
 Layout.fillHeight: BluetoothService.pairedDevices.length >0
 Layout.preferredHeight: BluetoothService.pairedDevices.length ===0 ?80 : implicitHeight
 visible: BluetoothService.pairedDevices.length >0
 model: BluetoothService.pairedDevices
 interactive: false
 animateAppearance: true
 animateMovement: true
 showVerticalScrollBar: false

 delegate: BluetoothDeviceItem {
 required property var modelData
 required property int index
 width: ListView.view.width
 device: modelData
 showForgetAction: true
 }
 }
 }

 // ===== Available (unpaired) devices section =====
 ColumnLayout {
 Layout.fillWidth: true
 Layout.fillHeight: BluetoothService.unpairedDevices.length >0 && !statusBanner.visible
 spacing:6
 visible: BluetoothService.available && BluetoothService.enabled

 Text {
 text: "可用设备"
 color: Appearance.colors.colOnLayer1
 font.pixelSize:13
 font.bold: true
 }

 StyledListView {
 id: availableList
 Layout.fillWidth: true
 Layout.fillHeight: BluetoothService.unpairedDevices.length >0
 Layout.preferredHeight: BluetoothService.unpairedDevices.length ===0 ?80 : implicitHeight
 visible: BluetoothService.unpairedDevices.length >0
 model: BluetoothService.unpairedDevices
 interactive: false
 animateAppearance: true
 animateMovement: true
 showVerticalScrollBar: false

 delegate: BluetoothDeviceItem {
 required property var modelData
 required property int index
 width: ListView.view.width
 device: modelData
 showForgetAction: false
 }
 }
 }

 // Empty state hint when adapter is on but we have nothing to show.
 Text {
 Layout.fillWidth: true
 Layout.alignment: Qt.AlignHCenter
 visible: BluetoothService.available
 && BluetoothService.enabled
 && !BluetoothService.discovering
 && BluetoothService.pairedDevices.length ===0
 && BluetoothService.unpairedDevices.length ===0
 text: "暂无设备 — 点击右上角「扫描」查找附近蓝牙设备"
 color: Appearance.colors.colOnLayer1
 font.pixelSize:13
 wrapMode: Text.WordWrap
 horizontalAlignment: Text.AlignHCenter
 Layout.topMargin:24
 }
 }
 // ====================================================================
 // BluetoothDeviceItem — single device row.
 // Shows name, connection state, primary action (connect / disconnect),
 // and an optional forget button (paired devices only).
 // ====================================================================
 component BluetoothDeviceItem: Rectangle {
 id: itemRoot

 required property var device
 property bool showForgetAction: true

 readonly property bool deviceAvailable: device !== null && device !== undefined
 readonly property string deviceName: device && device.name ? device.name : (device && device.address ? device.address : "未知设备")
 readonly property string deviceAddress: device && device.address ? device.address : ""
 readonly property bool deviceConnected: device && device.connected
 readonly property bool devicePaired: device && (device.paired || device.trusted)
 readonly property bool devicePairing: device && device.pairing
 readonly property bool deviceHasBattery: device && device.batteryAvailable
 readonly property real deviceBattery: device && device.batteryAvailable ? device.battery :0
 readonly property int deviceStrength: device && typeof device.signalStrength === "number" ? device.signalStrength : -1
 readonly property real verticalPadding:12
 readonly property real baseHeight: deviceRow.implicitHeight + itemRoot.verticalPadding *2
 readonly property real busyTargetHeight: (itemRoot.devicePairing || itemRoot.deviceConnected === false && itemRoot.devicePaired) ?18 :0

 height: itemRoot.baseHeight + itemRoot.busyTargetHeight
 radius:10
 clip: true
 color: {
 if (itemRoot.deviceConnected || itemRoot.devicePairing)
 return Appearance.colors.colLayer3;
 if (mouseArea.pressed)
 return Appearance.colors.colLayer2Active;
 if (mouseArea.containsMouse)
 return Appearance.colors.colLayer2Hover;
 return "transparent";
 }
 enabled: BluetoothService.available && BluetoothService.enabled && itemRoot.deviceAvailable

 Behavior on color { ColorAnimation { duration:140 } }
 Behavior on height { ElementMoveAnimation {} }
 Behavior on y { ElementMoveAnimation {} }

 MouseArea {
 id: mouseArea
 anchors.fill: parent
 hoverEnabled: true
 cursorShape: Qt.PointingHandCursor
 // Primary click toggles connection state for paired devices; for
 // unpaired devices the same click pairs + connects.
 onClicked: {
 const d = itemRoot.device;
 if (!d) return;
 if (itemRoot.deviceConnected) {
 BluetoothService.disconnectDevice(d);
 } else if (itemRoot.devicePaired) {
 BluetoothService.connectDevice(d);
 } else {
 BluetoothService.pairDevice(d);
 }
 }
 }

 ColumnLayout {
 id: contentColumn
 anchors {
 left: parent.left
 right: parent.right
 top: parent.top
 leftMargin:14
 rightMargin:14
 topMargin: itemRoot.verticalPadding
 }
 spacing:0

 RowLayout {
 id: deviceRow
 Layout.fillWidth: true
 spacing:12

 // Status / type glyph in the leading slot.
 Text {
 Layout.alignment: Qt.AlignVCenter
 text: {
 if (!itemRoot.deviceAvailable) return "bluetooth_disabled";
 if (itemRoot.deviceConnected) return "bluetooth_connected";
 if (itemRoot.devicePairing) return "bluetooth_searching";
 if (itemRoot.devicePaired) return "bluetooth";
 return "bluetooth";
 }
 font.family: root.mdFont
 font.pixelSize:24
 color: itemRoot.deviceConnected
 ? Appearance.colors.colPrimary
 : Appearance.colors.colOnLayer1
 }

 ColumnLayout {
 Layout.fillWidth: true
 Layout.alignment: Qt.AlignVCenter
 spacing:2

 RowLayout {
 Layout.fillWidth: true
 spacing:6

 Text {
 text: itemRoot.deviceName
 textFormat: Text.PlainText
 elide: Text.ElideRight
 font.bold: true
 font.pixelSize:14
 color: itemRoot.deviceConnected
 ? Appearance.colors.colPrimary
 : Appearance.colors.colOnLayer2
 Layout.fillWidth: true
 }

 // Battery pill (only renders when the device reports a level).
 Rectangle {
 visible: itemRoot.deviceHasBattery && itemRoot.deviceBattery >=0
 implicitWidth: batteryLabel.implicitWidth +12
 implicitHeight:18
 radius: height /2
 color: Appearance.colors.colLayer2

 Text {
 id: batteryLabel
 anchors.centerIn: parent
 text: Math.round(itemRoot.deviceBattery *100) + "%"
 font.pixelSize:11
 font.bold: true
 color: Appearance.colors.colOnLayer1
 }
 }
 }

 // Sub-line: connection state + (optional) address.
 Text {
 Layout.fillWidth: true
 text: {
 if (!itemRoot.deviceAvailable) return "";
 if (itemRoot.devicePairing) return "正在配对…";
 if (itemRoot.deviceConnected) return "已连接" + (itemRoot.deviceAddress ? " · " + itemRoot.deviceAddress : "");
 if (itemRoot.devicePaired) return "未连接" + (itemRoot.deviceAddress ? " · " + itemRoot.deviceAddress : "");
 return itemRoot.deviceAddress || "可配对";
 }
 font.pixelSize:12
 color: Appearance.colors.colOnLayer1
 elide: Text.ElideRight
 }
 }

 // Trailing action: connect/disconnect toggle (paired) or pair (new).
 Text {
 Layout.alignment: Qt.AlignVCenter
 visible: {
 if (!itemRoot.deviceAvailable) return false;
 // Hide the toggle while a pairing handshake is in flight to
 // avoid double-clicks racing the D-Bus state machine.
 if (itemRoot.devicePairing) return false;
 return true;
 }
 text: itemRoot.deviceConnected
 ? "link"
 : itemRoot.devicePaired
 ? "link_off"
 : "link"
 font.family: root.mdFont
 font.pixelSize:22
 color: itemRoot.deviceConnected
 ? Appearance.colors.colPrimary
 : Appearance.colors.colOnLayer1
 }

 // Forget button — only for paired devices. Anchored to the right
 // edge of the row, kept small so the layout doesn't shift.
 Rectangle {
 Layout.alignment: Qt.AlignVCenter
 visible: itemRoot.showForgetAction && itemRoot.devicePaired
 implicitWidth: forgetLabel.implicitWidth +16
 implicitHeight:24
 radius: height /2
 color: forgetMouse.pressed
 ? Appearance.colors.colLayer4Active
 : forgetMouse.containsMouse
 ? Appearance.colors.colLayer4Hover
 : "transparent"

 Behavior on color { ColorAnimation { duration:140 } }

 Text {
 id: forgetLabel
 anchors.centerIn: parent
 text: "移除"
 font.pixelSize:11
 font.bold: true
 color: Appearance.colors.colError
 }

 MouseArea {
 id: forgetMouse
 anchors.fill: parent
 hoverEnabled: true
 cursorShape: Qt.PointingHandCursor
 onClicked: {
 if (itemRoot.device)
 BluetoothService.forgetDevice(itemRoot.device);
 }
 }
 }
 }

 // Subtle progress strip while a pairing is in progress.
 Item {
 id: busyStrip
 Layout.fillWidth: true
 Layout.preferredHeight: itemRoot.busyTargetHeight
 visible: itemRoot.devicePairing || height >0

 Behavior on Layout.preferredHeight { ElementMoveAnimation {} }
 Behavior on opacity { ElementMoveAnimation {} }

 RowLayout {
 anchors { left: parent.left; right: parent.right; top: parent.top; topMargin:6 }
 spacing:8

 ProgressBar {
 Layout.fillWidth: true
 Layout.preferredHeight:3
 indeterminate: true
 Material.accent: Appearance.colors.colPrimary
 }
 Text {
 text: "正在配对"
 font.pixelSize:11
 color: Appearance.colors.colOnLayer1
 }
 }
 }
 }
 }
}
