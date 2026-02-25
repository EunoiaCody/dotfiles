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
		right: 180
	}

	implicitWidth: netPill.width + 4
	implicitHeight: netPill.height + 12
	color: "transparent"

	WlrLayershell.layer: WlrLayer.Overlay

	property bool panelOpen: false
	property bool _panelClosing: false

	// Connection state
	property string connectedSSID: ""
	property bool isConnected: connectedSSID !== ""
	property bool scanning: false

	// WiFi list model
	ListModel {
		id: wifiModel
	}

	// Password input state
	property string pendingSSID: ""
	property bool showPasswordInput: false

	// ===== Processes =====

	// Check active connection
	Process {
		id: checkConnection
		command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
		property string buf: ""

		stdout: SplitParser {
			onRead: data => {
				checkConnection.buf += data + "\n";
			}
		}

		onExited: (code, status) => {
			root.connectedSSID = "";
			const lines = checkConnection.buf.trim().split("\n");
			for (const line of lines) {
				const parts = line.split(":");
				if (parts.length >= 2 && parts[1] === "802-11-wireless") {
					root.connectedSSID = parts[0];
					break;
				}
			}
			checkConnection.buf = "";

			// Auto-scan if panel is open
			if (root.panelOpen) {
				scanWifi.start();
			}
		}

		Component.onCompleted: running = true
	}

	// Periodic connection check
	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: {
			checkConnection.buf = "";
			checkConnection.running = true;
		}
	}

	// Scan WiFi
	Process {
		id: scanProcess
		command: ["nmcli", "device", "wifi", "rescan"]

		onExited: {
			listWifi.buf = "";
			listWifi.running = true;
		}
	}

	// List WiFi networks
	Process {
		id: listWifi
		command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list", "--rescan", "no"]
		property string buf: ""

		stdout: SplitParser {
			onRead: data => {
				listWifi.buf += data + "\n";
			}
		}

		onExited: (code, status) => {
			root.scanning = false;
			wifiModel.clear();

			const lines = listWifi.buf.trim().split("\n");
			const seen = {};
			const entries = [];

			for (const line of lines) {
				if (!line.trim()) continue;
				const parts = line.split(":");
				if (parts.length < 3) continue;

				const ssid = parts[0];
				if (!ssid || ssid === "--") continue;

				const signal = parseInt(parts[1]) || 0;
				const security = parts[2] || "";
				const inUse = parts.length >= 4 && parts[3] === "*";

				// Deduplicate by SSID, keep highest signal
				if (!seen[ssid] || seen[ssid].signal < signal) {
					seen[ssid] = { ssid, signal, security, inUse };
				}
			}

			// Sort by signal descending
			for (const key in seen) entries.push(seen[key]);
			entries.sort((a, b) => b.signal - a.signal);

			for (const e of entries) {
				wifiModel.append({
					ssid: e.ssid,
					signal: e.signal,
					security: e.security,
					inUse: e.inUse
				});
			}

			listWifi.buf = "";
		}
	}

	// Connect to WiFi (open network)
	Process {
		id: connectProcess
		property string buf: ""

		stdout: SplitParser {
			onRead: data => connectProcess.buf += data
		}

		onExited: (code, status) => {
			connectProcess.buf = "";
			// Refresh connection status
			checkConnection.buf = "";
			checkConnection.running = true;
		}
	}

	// Connect to WiFi (with password)
	Process {
		id: connectPasswordProcess
		property string buf: ""

		stdout: SplitParser {
			onRead: data => connectPasswordProcess.buf += data
		}

		onExited: (code, status) => {
			connectPasswordProcess.buf = "";
			root.showPasswordInput = false;
			root.pendingSSID = "";
			checkConnection.buf = "";
			checkConnection.running = true;
		}
	}

	function scanWifi() {
		root.scanning = true;
		scanProcess.running = true;
	}

	function connectToNetwork(ssid, security) {
		if (security && security !== "" && security !== "--") {
			// Needs password
			root.pendingSSID = ssid;
			root.showPasswordInput = true;
		} else {
			// Open network
			connectProcess.command = ["nmcli", "device", "wifi", "connect", ssid];
			connectProcess.running = true;
		}
	}

	function connectWithPassword(ssid, password) {
		connectPasswordProcess.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
		connectPasswordProcess.running = true;
	}

	function wifiIcon(signal) {
		if (signal >= 75) return "󰤨";
		if (signal >= 50) return "󰤥";
		if (signal >= 25) return "󰤢";
		return "󰤟";
	}

	function statusIcon() {
		if (!root.isConnected) return "󰤭";
		return "󰤨";
	}

	// Close animation delay timer
	Timer {
		id: closeDelayTimer
		interval: 380
		onTriggered: root._panelClosing = false
	}

	onPanelOpenChanged: {
		if (!panelOpen) {
			root._panelClosing = true;
			root.showPasswordInput = false;
			root.pendingSSID = "";
			closeDelayTimer.start();
		} else {
			scanWifi();
		}
	}

	// ===== Pill button =====
	Rectangle {
		id: netPill
		anchors.centerIn: parent
		width: netRow.width + 20
		height: netRow.height + 12
		radius: height / 2
		color: netMouse.containsMouse ? Root.Color.lavender : Root.Color.base

		Behavior on color {
			ColorAnimation { duration: 150 }
		}

		RowLayout {
			id: netRow
			anchors.centerIn: parent
			spacing: 6

			Text {
				text: root.statusIcon()
				font.family: "Symbols Nerd Font Mono"
				font.pointSize: 15
				color: netMouse.containsMouse ? Root.Color.base : Root.Color.lavender

				Behavior on color {
					ColorAnimation { duration: 150 }
				}
			}

			Text {
				text: root.isConnected ? root.connectedSSID : "未连接"
				font.pointSize: 11
				font.bold: true
				color: netMouse.containsMouse ? Root.Color.base : Root.Color.lavender
				elide: Text.ElideRight

				Behavior on color {
					ColorAnimation { duration: 150 }
				}
			}
		}

		MouseArea {
			id: netMouse
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

			anchors {
				top: true
				right: true
			}

			exclusiveZone: -1
			margins {
				top: 56
				right: 3
			}

			implicitWidth: 340
			implicitHeight: Math.min(panelCol.implicitHeight + 32, 600)
			color: "transparent"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "network-panel"

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

							// ===== Current connection =====
							Rectangle {
								visible: root.isConnected
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
										text: "󰤨"
										font.family: "Symbols Nerd Font Mono"
										font.pointSize: 20
										color: Root.Color.green
									}

									ColumnLayout {
										Layout.fillWidth: true
										spacing: 2

										Text {
											text: root.connectedSSID
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
												connectProcess.command = ["nmcli", "connection", "down", root.connectedSSID];
												connectProcess.running = true;
											}
										}
									}
								}
							}

							// ===== Header + scan button =====
							RowLayout {
								Layout.fillWidth: true

								Text {
									text: "无线网络"
									font.pointSize: 14
									font.bold: true
									color: Root.Color.lavender
									Layout.fillWidth: true
								}

								Rectangle {
									width: 32
									height: 32
									radius: width / 2
									color: scanBtnMouse.containsMouse ? Root.Color.lavender : Root.Color.surface0

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
										onClicked: root.scanWifi()
									}
								}
							}

							// ===== Password input =====
							Rectangle {
								id: passwordBox
								visible: root.showPasswordInput
								Layout.fillWidth: true
								implicitHeight: pwdCol.height + 20
								radius: 12
								color: Root.Color.surface0
								border.width: 2
								border.color: Root.Color.lavender

								ColumnLayout {
									id: pwdCol
									anchors {
										left: parent.left
										right: parent.right
										top: parent.top
										margins: 12
									}
									spacing: 8

									Text {
										text: "连接到 " + root.pendingSSID
										font.pointSize: 11
										font.bold: true
										color: Root.Color.text
									}

									Rectangle {
										Layout.fillWidth: true
										height: 36
										radius: 8
										color: Root.Color.mantle
										border.width: 1
										border.color: pwdInput.activeFocus ? Root.Color.lavender : Root.Color.surface1

										Behavior on border.color {
											ColorAnimation { duration: 150 }
										}

										TextInput {
											id: pwdInput
											anchors {
												fill: parent
												leftMargin: 10
												rightMargin: 10
												topMargin: 4
												bottomMargin: 4
											}
											verticalAlignment: TextInput.AlignVCenter
											color: Root.Color.text
											echoMode: TextInput.Password
											font.pointSize: 11

											Text {
												visible: !pwdInput.text
												text: "输入密码…"
												color: Root.Color.overlay0
												font.pointSize: 11
												anchors.verticalCenter: parent.verticalCenter
											}

											Keys.onReturnPressed: {
												if (pwdInput.text) {
													root.connectWithPassword(root.pendingSSID, pwdInput.text);
													pwdInput.text = "";
												}
											}
										}
									}

									RowLayout {
										Layout.fillWidth: true
										spacing: 8

										Item { Layout.fillWidth: true }

										Rectangle {
											width: cancelText.width + 16
											height: cancelText.height + 8
											radius: height / 2
											color: cancelPwdMouse.containsMouse ? Root.Color.surface1 : Root.Color.surface0

											Behavior on color { ColorAnimation { duration: 150 } }

											Text {
												id: cancelText
												anchors.centerIn: parent
												text: "取消"
												font.pointSize: 10
												color: Root.Color.subtext1
											}

											MouseArea {
												id: cancelPwdMouse
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onClicked: {
													root.showPasswordInput = false;
													root.pendingSSID = "";
													pwdInput.text = "";
												}
											}
										}

										Rectangle {
											width: connectText.width + 16
											height: connectText.height + 8
											radius: height / 2
											color: connectPwdMouse.containsMouse ? Root.Color.lavender : Root.Color.surface0

											Behavior on color { ColorAnimation { duration: 150 } }

											Text {
												id: connectText
												anchors.centerIn: parent
												text: "连接"
												font.pointSize: 10
												color: connectPwdMouse.containsMouse ? Root.Color.base : Root.Color.lavender
											}

											MouseArea {
												id: connectPwdMouse
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onClicked: {
													if (pwdInput.text) {
														root.connectWithPassword(root.pendingSSID, pwdInput.text);
														pwdInput.text = "";
													}
												}
											}
										}
									}
								}
							}

							// ===== WiFi list =====
							Text {
								visible: wifiModel.count === 0 && !root.scanning
								text: "未找到网络"
								font.pointSize: 11
								color: Root.Color.subtext0
								Layout.alignment: Qt.AlignHCenter
								Layout.topMargin: 12
								Layout.bottomMargin: 12
							}

							Text {
								visible: root.scanning
								text: "正在扫描…"
								font.pointSize: 11
								color: Root.Color.subtext0
								Layout.alignment: Qt.AlignHCenter
								Layout.topMargin: 12
								Layout.bottomMargin: 12
							}

							Repeater {
								model: wifiModel

								Rectangle {
									id: wifiItem
									required property string ssid
									required property int signal
									required property string security
									required property bool inUse
									required property int index

									Layout.fillWidth: true
									implicitHeight: wifiRow.height + 14
									radius: 12
									color: wifiItemMouse.containsMouse ? Root.Color.surface0 : Root.Color.mantle

									Behavior on color {
										ColorAnimation { duration: 150 }
									}

									RowLayout {
										id: wifiRow
										anchors {
											left: parent.left
											right: parent.right
											verticalCenter: parent.verticalCenter
											leftMargin: 14
											rightMargin: 14
										}
										spacing: 10

										Text {
											text: root.wifiIcon(signal)
											font.family: "Symbols Nerd Font Mono"
											font.pointSize: 16
											color: inUse ? Root.Color.green : Root.Color.lavender
										}

										ColumnLayout {
											Layout.fillWidth: true
											spacing: 1

											Text {
												text: ssid
												font.pointSize: 11
												font.bold: true
												color: inUse ? Root.Color.green : Root.Color.text
												elide: Text.ElideRight
												Layout.fillWidth: true
											}

											RowLayout {
												spacing: 6

												Text {
													text: signal + "%"
													font.pointSize: 9
													color: Root.Color.overlay1
												}

												Text {
													visible: security !== "" && security !== "--"
													text: "󰌾"
													font.family: "Symbols Nerd Font Mono"
													font.pointSize: 9
													color: Root.Color.overlay1
												}

												Text {
													visible: security !== "" && security !== "--"
													text: security
													font.pointSize: 9
													color: Root.Color.overlay1
												}
											}
										}

										Text {
											visible: inUse
											text: "已连接"
											font.pointSize: 9
											color: Root.Color.green
										}
									}

									MouseArea {
										id: wifiItemMouse
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: {
											if (!inUse) {
												root.connectToNetwork(ssid, security);
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
