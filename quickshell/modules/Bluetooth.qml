import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
		right: Root.BarLayout.rightMarginFor("bluetooth")
	}

	implicitWidth: btPill.width + 4
	implicitHeight: btPill.height + 12
	color: "transparent"

	onImplicitWidthChanged: Root.BarLayout.updateWidth("bluetooth", implicitWidth)
	Component.onCompleted: Root.BarLayout.updateWidth("bluetooth", implicitWidth)

	WlrLayershell.layer: WlrLayer.Top

	property bool panelOpen: false
	property bool _panelClosing: false

	// Bluetooth state
	property bool bluetoothPowered: false
	property string connectedDeviceName: ""
	property string connectedDeviceMAC: ""
	property bool scanning: false

	ListModel {
		id: pairedModel
	}

	// ===== Check adapter power state =====
	Process {
		id: checkPower
		command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}'"]
		property string buf: ""

		stdout: SplitParser {
			onRead: data => {
				checkPower.buf = data.trim();
			}
		}

		onExited: (code, status) => {
			root.bluetoothPowered = (checkPower.buf === "yes");
			checkPower.buf = "";
			if (root.bluetoothPowered) {
				listPaired.buf = "";
				listPaired.running = true;
			} else {
				pairedModel.clear();
				root.connectedDeviceName = "";
				root.connectedDeviceMAC = "";
			}
		}

		Component.onCompleted: running = true
	}

	// Periodic status check
	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: {
			checkPower.buf = "";
			checkPower.running = true;
		}
	}

	// ===== List paired devices with connection status =====
	Process {
		id: listPaired
		command: ["bash", "-c", "bluetoothctl devices Paired 2>/dev/null | while IFS= read -r line; do mac=$(echo \"$line\" | awk '{print $2}'); info=$(bluetoothctl info \"$mac\" 2>/dev/null); name=$(echo \"$info\" | grep '^\\s*Alias:' | sed 's/^\\s*Alias:\\s*//'); if [ -z \"$name\" ]; then name=$(echo \"$line\" | cut -d' ' -f3-); fi; connected=$(echo \"$info\" | grep 'Connected:' | awk '{print $2}'); icon=$(echo \"$info\" | grep 'Icon:' | awk '{print $2}'); printf '%s\\t%s\\t%s\\t%s\\n' \"$mac\" \"$name\" \"$connected\" \"$icon\"; done"]
		property string buf: ""

		stdout: SplitParser {
			onRead: data => {
				listPaired.buf += data + "\n";
			}
		}

		onExited: (code, status) => {
			pairedModel.clear();
			root.connectedDeviceName = "";
			root.connectedDeviceMAC = "";
			const lines = listPaired.buf.trim().split("\n");
			for (const line of lines) {
				if (!line.trim()) continue;
				const parts = line.split("\t");
				if (parts.length < 3) continue;
				const mac = parts[0];
				const name = parts[1] || mac;
				const isConnected = parts[2] === "yes";
				const iconType = parts.length >= 4 ? parts[3] : "";
				if (isConnected && !root.connectedDeviceName) {
					root.connectedDeviceName = name;
					root.connectedDeviceMAC = mac;
				}
				pairedModel.append({
					mac: mac,
					name: name,
					isConnected: isConnected,
					iconType: iconType
				});
			}
			listPaired.buf = "";
		}
	}

	// ===== Scan for devices =====
	Process {
		id: scanProcess
		command: ["bash", "-c", "bluetoothctl --timeout 8 scan on 2>/dev/null"]

		onExited: {
			root.scanning = false;
			listPaired.buf = "";
			listPaired.running = true;
		}
	}

	// ===== Connect =====
	Process {
		id: connectProcess

		onExited: {
			checkPower.buf = "";
			checkPower.running = true;
		}
	}

	// ===== Disconnect =====
	Process {
		id: disconnectProcess

		onExited: {
			checkPower.buf = "";
			checkPower.running = true;
		}
	}

	// ===== Toggle power =====
	Process {
		id: togglePowerProcess

		onExited: {
			checkPower.buf = "";
			checkPower.running = true;
		}
	}

	function startScan() {
		root.scanning = true;
		scanProcess.running = true;
	}

	function connectDevice(mac) {
		connectProcess.command = ["bluetoothctl", "connect", mac];
		connectProcess.running = true;
	}

	function disconnectDevice(mac) {
		disconnectProcess.command = ["bluetoothctl", "disconnect", mac];
		disconnectProcess.running = true;
	}

	function togglePower() {
		togglePowerProcess.command = ["bluetoothctl", "power", root.bluetoothPowered ? "off" : "on"];
		togglePowerProcess.running = true;
	}

	function deviceIcon(iconType) {
		if (iconType === "audio-headset" || iconType === "audio-headphones") return "󰋋";
		if (iconType === "audio-card") return "󰓃";
		if (iconType === "input-keyboard") return "󰌌";
		if (iconType === "input-mouse") return "󰍽";
		if (iconType === "input-gaming") return "󰊗";
		if (iconType === "phone") return "󰏲";
		if (iconType === "computer") return "󰌢";
		return "󰂯";
	}

	function statusIcon() {
		if (!root.bluetoothPowered) return "󰂲";
		if (root.connectedDeviceName) return "󰂱";
		return "󰂯";
	}

	// Close animation delay timer
	Timer {
		id: closeDelayTimer
		interval: 380
		onTriggered: {
			Root.PanelStack.panelClosed("bluetooth");
			root._panelClosing = false;
		}
	}

	onPanelOpenChanged: {
		if (panelOpen) {
			Root.PanelStack.panelOpened("bluetooth", 0);
			if (root.bluetoothPowered) {
				listPaired.buf = "";
				listPaired.running = true;
			}
		} else {
			root._panelClosing = true;
			closeDelayTimer.start();
		}
	}

	// ===== Pill button =====
	Rectangle {
		id: btPill
		anchors.centerIn: parent
		width: btRow.width + 20
		height: btRow.height + 12
		radius: height / 2
		color: btMouse.containsMouse ? Root.Color.lavender : Root.Color.base

		Behavior on color {
			ColorAnimation { duration: 150 }
		}

		RowLayout {
			id: btRow
			anchors.centerIn: parent
			spacing: 6

			Text {
				text: root.statusIcon()
				font.family: "Symbols Nerd Font Mono"
				font.pointSize: 15
				color: btMouse.containsMouse ? Root.Color.base : Root.Color.lavender

				Behavior on color {
					ColorAnimation { duration: 150 }
				}
			}

			Text {
				text: root.connectedDeviceName || "蓝牙"
				font.pointSize: 11
				font.bold: true
				color: btMouse.containsMouse ? Root.Color.base : Root.Color.lavender
				elide: Text.ElideRight

				Behavior on color {
					ColorAnimation { duration: 150 }
				}
			}
		}

		MouseArea {
			id: btMouse
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: root.panelOpen = !root.panelOpen
		}
	}

	// ===== Slide-in panel =====
	LazyLoader {
		id: panelLoader
		active: root.panelOpen || root._panelClosing

		PanelWindow {
			id: slidePanel
			screen: root.screen

			property real panelTop: Root.PanelStack.topFor("bluetooth")
			Behavior on panelTop {
				NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
			}

			anchors {
				top: true
				right: true
			}

			exclusiveZone: -1
			margins {
				top: Math.round(slidePanel.panelTop)
				right: 3
			}

			implicitWidth: 340
			implicitHeight: Math.min(panelCol.implicitHeight + 32, 500)
			color: "transparent"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "bluetooth-panel"

			onImplicitHeightChanged: Root.PanelStack.updateHeight("bluetooth", implicitHeight)
			Component.onCompleted: Root.PanelStack.updateHeight("bluetooth", implicitHeight)

			Item {
				anchors.fill: parent
				clip: true

				Rectangle {
					id: panelContent
					width: parent.width
					height: parent.height
					radius: 16
					color: Root.Color.base
					border.width: 3
					border.color: Root.Color.lavender
					clip: true

					property bool _showContent: false

					Component.onCompleted: _showContent = true

					Connections {
						target: root
						function onPanelOpenChanged() {
							if (!root.panelOpen) panelContent._showContent = false
						}
					}

					x: _showContent ? 0 : width

					Behavior on x {
						NumberAnimation {
							duration: 350
							easing.type: panelContent._showContent ? Easing.OutCubic : Easing.InCubic
						}
					}

					Flickable {
						anchors {
							fill: parent
							margins: 16
						}
						contentHeight: panelCol.implicitHeight
						clip: true

						ColumnLayout {
							id: panelCol
							width: parent.width
							spacing: 12

							// ===== Header + power + scan =====
							RowLayout {
								Layout.fillWidth: true

								Text {
									text: "蓝牙"
									font.pointSize: 14
									font.bold: true
									color: Root.Color.lavender
									Layout.fillWidth: true
								}

								// Power toggle
								Rectangle {
									width: 32
									height: 32
									radius: width / 2
									color: root.bluetoothPowered
										? (powerMouse.containsMouse ? Root.Color.surface1 : Root.Color.lavender)
										: (powerMouse.containsMouse ? Root.Color.surface1 : Root.Color.surface0)

									Behavior on color {
										ColorAnimation { duration: 150 }
									}

									Text {
										anchors.centerIn: parent
										text: "󰐥"
										font.family: "Symbols Nerd Font Mono"
										font.pointSize: 14
										color: root.bluetoothPowered
											? (powerMouse.containsMouse ? Root.Color.lavender : Root.Color.base)
											: Root.Color.subtext1

										Behavior on color {
											ColorAnimation { duration: 150 }
										}
									}

									MouseArea {
										id: powerMouse
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: root.togglePower()
									}
								}

								// Scan button
								Rectangle {
									width: 32
									height: 32
									radius: width / 2
									color: scanBtnMouse.containsMouse ? Root.Color.lavender : Root.Color.surface0
									visible: root.bluetoothPowered

									Behavior on color {
										ColorAnimation { duration: 150 }
									}

									Text {
										anchors.centerIn: parent
										text: "󰑐"
										font.family: "Symbols Nerd Font Mono"
										font.pointSize: 14
										color: scanBtnMouse.containsMouse ? Root.Color.base : Root.Color.subtext1

										RotationAnimation on rotation {
											running: root.scanning
											from: 0
											to: 360
											duration: 1000
											loops: Animation.Infinite
										}
									}

									MouseArea {
										id: scanBtnMouse
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: root.startScan()
									}
								}
							}

							// ===== Power off message =====
							Text {
								visible: !root.bluetoothPowered
								text: "蓝牙已关闭"
								font.pointSize: 11
								color: Root.Color.subtext0
								Layout.alignment: Qt.AlignHCenter
								Layout.topMargin: 12
								Layout.bottomMargin: 12
							}

							// ===== Connected device =====
							Rectangle {
								visible: root.bluetoothPowered && root.connectedDeviceName !== ""
								Layout.fillWidth: true
								implicitHeight: connRow.height + 20
								radius: 12
								color: Root.Color.mantle

								RowLayout {
									id: connRow
									anchors {
										left: parent.left
										right: parent.right
										verticalCenter: parent.verticalCenter
										leftMargin: 14
										rightMargin: 14
									}
									spacing: 10

									Text {
										text: "󰂱"
										font.family: "Symbols Nerd Font Mono"
										font.pointSize: 20
										color: Root.Color.green
									}

									ColumnLayout {
										Layout.fillWidth: true
										spacing: 2

										Text {
											text: root.connectedDeviceName
											font.pointSize: 12
											font.bold: true
											color: Root.Color.text
										}

										Text {
											text: "已连接"
											font.pointSize: 9
											color: Root.Color.green
										}
									}

									// Disconnect button
									Rectangle {
										width: 28
										height: 28
										radius: width / 2
										color: disconnMouse.containsMouse ? Root.Color.red : Root.Color.surface0

										Behavior on color {
											ColorAnimation { duration: 150 }
										}

										Text {
											anchors.centerIn: parent
											text: "✕"
											font.pointSize: 10
											color: disconnMouse.containsMouse ? Root.Color.base : Root.Color.overlay1
										}

										MouseArea {
											id: disconnMouse
											anchors.fill: parent
											hoverEnabled: true
											cursorShape: Qt.PointingHandCursor
											onClicked: {
												root.disconnectDevice(root.connectedDeviceMAC);
											}
										}
									}
								}
							}

							// ===== Scanning indicator =====
							Text {
								visible: root.scanning
								text: "正在扫描…"
								font.pointSize: 11
								color: Root.Color.subtext0
								Layout.alignment: Qt.AlignHCenter
							}

							// ===== No devices =====
							Text {
								visible: root.bluetoothPowered && pairedModel.count === 0 && !root.scanning
								text: "没有已配对的设备"
								font.pointSize: 11
								color: Root.Color.subtext0
								Layout.alignment: Qt.AlignHCenter
								Layout.topMargin: 12
								Layout.bottomMargin: 12
							}

							// ===== Paired devices list =====
							Repeater {
								model: root.bluetoothPowered ? pairedModel : null

								Rectangle {
									id: btItem
									required property string mac
									required property string name
									required property bool isConnected
									required property string iconType
									required property int index

									Layout.fillWidth: true
									implicitHeight: btRow.height + 14
									radius: 12
									color: btItemMouse.containsMouse ? Root.Color.surface0 : Root.Color.mantle

									Behavior on color {
										ColorAnimation { duration: 150 }
									}

									RowLayout {
										id: btRow
										anchors {
											left: parent.left
											right: parent.right
											verticalCenter: parent.verticalCenter
											leftMargin: 14
											rightMargin: 14
										}
										spacing: 10

										Text {
											text: root.deviceIcon(iconType)
											font.family: "Symbols Nerd Font Mono"
											font.pointSize: 16
											color: isConnected ? Root.Color.green : Root.Color.lavender
										}

										ColumnLayout {
											Layout.fillWidth: true
											spacing: 1

											Text {
												text: name
												font.pointSize: 11
												font.bold: true
												color: isConnected ? Root.Color.green : Root.Color.text
												elide: Text.ElideRight
												Layout.fillWidth: true
											}

											Text {
												text: isConnected ? "已连接" : "已配对"
												font.pointSize: 9
												color: isConnected ? Root.Color.green : Root.Color.overlay1
											}
										}

										Text {
											visible: isConnected
											text: "已连接"
											font.pointSize: 9
											color: Root.Color.green
										}
									}

									MouseArea {
										id: btItemMouse
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: {
											if (isConnected) {
												root.disconnectDevice(mac);
											} else {
												root.connectDevice(mac);
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
