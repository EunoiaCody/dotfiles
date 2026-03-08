import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
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
		right: Root.BarLayout.rightMarginFor("volume")
	}

	implicitWidth: volPill.width + 4
	implicitHeight: volPill.height + 12
	color: "transparent"

	onImplicitWidthChanged: Root.BarLayout.updateWidth("volume", implicitWidth)
	Component.onCompleted: Root.BarLayout.updateWidth("volume", implicitWidth)

	WlrLayershell.layer: WlrLayer.Top

	property bool panelOpen: false
	property bool _panelClosing: false
	property bool deviceSelectorOpen: false
	property bool appVolumeOpen: false

	// Track the active sink (not just defaultAudioSink)
	property PwNode sink: Pipewire.defaultAudioSink
	property bool userSelectedSink: false

	// Track sink nodes + audio output streams only
	PwObjectTracker {
		objects: {
			var result = [];
			var nodes = Pipewire.nodes.values;
			for (var i = 0; i < nodes.length; i++) {
				var n = nodes[i];
				if ((n.isSink && !n.isStream)
					|| (n.isStream && n.properties["media.class"] === "Stream/Output/Audio"))
					result.push(n);
			}
			return result;
		}
	}

	// Follow default sink changes when user hasn't manually selected one
	Connections {
		target: Pipewire
		function onDefaultAudioSinkChanged() {
			if (!root.userSelectedSink) {
				root.sink = Pipewire.defaultAudioSink;
			}
		}
	}

	function getSinkNodes() {
		var result = [];
		var nodes = Pipewire.nodes.values;
		for (var i = 0; i < nodes.length; i++) {
			if (nodes[i].isSink && !nodes[i].isStream) result.push(nodes[i]);
		}
		return result;
	}

	function getStreamNodes() {
		var result = [];
		var nodes = Pipewire.nodes.values;
		for (var i = 0; i < nodes.length; i++) {
			var n = nodes[i];
			if (n.isStream && n.properties["media.class"] === "Stream/Output/Audio")
				result.push(n);
		}
		return result;
	}

	function selectSink(node) {
		root.sink = node;
		root.userSelectedSink = true;
		Pipewire.preferredDefaultAudioSink = node;
		root.deviceSelectorOpen = false;
	}
	property int volumePercent: sink ? Math.round(sink.audio.volume * 100) : 0

	// Use wpctl to set volume (PwObjectTracker write-back doesn't work)
	Process {
		id: volumeProc
		command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "0"]
	}

	function setVolume(ratio) {
		if (!root.sink) return;
		var clamped = Math.max(0, Math.min(1, ratio));
		volumeProc.command = ["wpctl", "set-volume", root.sink.id.toString(), clamped.toFixed(2)];
		volumeProc.running = true;
	}

	Process {
		id: muteProc
		command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
	}

	function toggleMute() {
		if (!root.sink) return;
		muteProc.command = ["wpctl", "set-mute", root.sink.id.toString(), "toggle"];
		muteProc.running = true;
	}

	Process {
		id: streamVolumeProc
		command: ["wpctl", "set-volume", "0", "0"]
	}

	function setStreamVolume(nodeId, ratio) {
		var clamped = Math.max(0, Math.min(1, ratio));
		streamVolumeProc.command = ["wpctl", "set-volume", nodeId.toString(), clamped.toFixed(2)];
		streamVolumeProc.running = true;
	}

	Process {
		id: streamMuteProc
		command: ["wpctl", "set-mute", "0", "toggle"]
	}

	function toggleStreamMute(nodeId) {
		streamMuteProc.command = ["wpctl", "set-mute", nodeId.toString(), "toggle"];
		streamMuteProc.running = true;
	}

	function clampVolume(v) {
		if (v < 0) v = 0;
		if (v > 1) v = 1;
		return v;
	}

	function volumeIcon() {
		if (!sink || sink.audio.muted || volumePercent === 0) return "󰖁";
		if (volumePercent < 30) return "󰕿";
		if (volumePercent < 70) return "󰖀";
		return "󰕾";
	}

	// Close animation delay timer
	Timer {
		id: closeDelayTimer
		interval: 380
		onTriggered: {
			Root.PanelStack.panelClosed("volume");
			root._panelClosing = false;
		}
	}

	onPanelOpenChanged: {
		if (panelOpen) {
			Root.PanelStack.panelOpened("volume", 0);
		} else {
			root._panelClosing = true;
			closeDelayTimer.start();
		}
	}

	// Pill button
	Rectangle {
		id: volPill
		anchors.centerIn: parent
		width: volRow.width + 20
		height: volRow.height + 12
		radius: height / 2
		color: volMouse.containsMouse ? Root.Color.lavender : Root.Color.base

		Behavior on color {
			ColorAnimation { duration: 150 }
		}

		RowLayout {
			id: volRow
			anchors.centerIn: parent
			spacing: 4

			Text {
				text: root.volumeIcon()
				font.family: "Symbols Nerd Font Mono"
				font.pointSize: 15
				color: volMouse.containsMouse ? Root.Color.base : Root.Color.lavender

				Behavior on color {
					ColorAnimation { duration: 150 }
				}
			}

			Text {
				text: root.volumePercent + "%"
				font.pointSize: 12
				font.bold: true
				color: volMouse.containsMouse ? Root.Color.base : Root.Color.lavender

				Behavior on color {
					ColorAnimation { duration: 150 }
				}
			}
		}

		MouseArea {
			id: volMouse
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			acceptedButtons: Qt.LeftButton | Qt.MiddleButton

			onClicked: mouse => {
				if (mouse.button === Qt.MiddleButton) {
					root.toggleMute();
				} else {
					root.panelOpen = !root.panelOpen;
				}
			}

			onWheel: wheel => {
				if (!root.sink) return;
				const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
				root.setVolume(root.clampVolume(root.sink.audio.volume + delta));
			}
		}
	}

	// ===== Slide-in volume panel =====
	LazyLoader {
		id: panelLoader
		active: root.panelOpen || root._panelClosing

		PanelWindow {
			id: slidePanel
			screen: root.screen

			property real panelTop: Root.PanelStack.topFor("volume")
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
			implicitHeight: panelCol.implicitHeight + 32
			color: "transparent"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "volume-panel"

			onImplicitHeightChanged: Root.PanelStack.updateHeight("volume", implicitHeight)
			Component.onCompleted: Root.PanelStack.updateHeight("volume", implicitHeight)

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

					ColumnLayout {
						id: panelCol
						anchors {
							left: parent.left
							right: parent.right
							top: parent.top
							margins: 16
						}
						spacing: 16

						// Header
						RowLayout {
							Layout.fillWidth: true

							Text {
								text: "音量"
								font.pointSize: 14
								font.bold: true
								color: Root.Color.lavender
								Layout.fillWidth: true
							}

							// Mute toggle
							Rectangle {
								width: 32
								height: 32
								radius: width / 2
								color: root.sink && root.sink.audio.muted
									? Root.Color.red
									: (muteMouse.containsMouse ? Root.Color.surface1 : Root.Color.surface0)

								Behavior on color {
									ColorAnimation { duration: 150 }
								}

								Text {
									anchors.centerIn: parent
									text: root.sink && root.sink.audio.muted ? "󰖁" : "󰕾"
									font.family: "Symbols Nerd Font Mono"
									font.pointSize: 14
									color: root.sink && root.sink.audio.muted ? Root.Color.base : Root.Color.subtext1

									Behavior on color {
										ColorAnimation { duration: 150 }
									}
								}

								MouseArea {
									id: muteMouse
									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: {
										root.toggleMute();
									}
								}
							}
						}

						// Volume icon + percentage
						RowLayout {
							Layout.fillWidth: true
							spacing: 12

							Text {
								text: root.volumeIcon()
								font.family: "Symbols Nerd Font Mono"
								font.pointSize: 24
								color: root.sink && root.sink.audio.muted ? Root.Color.overlay1 : Root.Color.lavender

								Behavior on color {
									ColorAnimation { duration: 150 }
								}
							}

							Text {
								text: root.volumePercent + "%"
								font.pointSize: 20
								font.bold: true
								color: root.sink && root.sink.audio.muted ? Root.Color.overlay1 : Root.Color.text
								Layout.fillWidth: true

								Behavior on color {
									ColorAnimation { duration: 150 }
								}
							}
						}

						// Volume slider track
						Item {
							Layout.fillWidth: true
							height: 36

							// Track background
							Rectangle {
								id: sliderTrack
								anchors.verticalCenter: parent.verticalCenter
								width: parent.width
								height: 8
								radius: height / 2
								color: Root.Color.surface0

								// Filled portion
								Rectangle {
									width: root.sink ? parent.width * Math.min(root.sink.audio.volume, 1.0) : 0
									height: parent.height
									radius: height / 2
									color: root.sink && root.sink.audio.muted ? Root.Color.overlay1 : Root.Color.lavender

									Behavior on width {
										NumberAnimation {
											duration: 80
											easing.type: Easing.OutCubic
										}
									}

									Behavior on color {
										ColorAnimation { duration: 150 }
									}
								}
							}

							// Drag handle
							Rectangle {
								id: sliderHandle
								width: 20
								height: 20
								radius: width / 2
								color: sliderDrag.pressed
									? Root.Color.lavender
									: (sliderDrag.containsMouse ? Root.Color.text : Root.Color.subtext1)
								anchors.verticalCenter: parent.verticalCenter
								x: root.sink
									? Math.max(0, Math.min(parent.width - width, parent.width * Math.min(root.sink.audio.volume, 1.0) - width / 2))
									: 0

								Behavior on color {
									ColorAnimation { duration: 100 }
								}

								Behavior on x {
									enabled: !sliderDrag.pressed
									NumberAnimation {
										duration: 80
										easing.type: Easing.OutCubic
									}
								}
							}

							// Drag area covers the full track
							MouseArea {
								id: sliderDrag
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								preventStealing: true

								function updateVolume(mouseX) {
									if (!root.sink) return;
									const ratio = Math.max(0, Math.min(1, mouseX / width));
									root.setVolume(ratio);
								}

								onPressed: mouse => updateVolume(mouse.x)
								onPositionChanged: mouse => {
									if (pressed) updateVolume(mouse.x);
								}

								onWheel: wheel => {
									if (!root.sink) return;
									const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
								root.setVolume(root.clampVolume(root.sink.audio.volume + delta));
								}
							}
						}

						// ===== Device selector =====
						Item {
							Layout.fillWidth: true
							Layout.preferredHeight: deviceSelectorCol.implicitHeight

							ColumnLayout {
								id: deviceSelectorCol
								anchors.left: parent.left
								anchors.right: parent.right
								spacing: 0

								Rectangle {
									Layout.fillWidth: true
									height: 32
									radius: root.deviceSelectorOpen ? 8 : 16
									color: deviceSelectorMa.containsMouse ? Root.Color.surface1 : Root.Color.surface0
									Behavior on color { ColorAnimation { duration: 150 } }

									RowLayout {
										anchors.fill: parent
										anchors.leftMargin: 12
										anchors.rightMargin: 12
										spacing: 6

										Text {
											text: "󰕾"
											font.family: "Symbols Nerd Font Mono"
											font.pointSize: 10
											color: Root.Color.overlay1
										}

										Text {
											text: root.sink ? (root.sink.description || root.sink.name) : "未知设备"
											font.pointSize: 10
											color: Root.Color.subtext1
											elide: Text.ElideRight
											Layout.fillWidth: true
										}

										Text {
											text: root.deviceSelectorOpen ? "󰅁" : "󰅂"
											font.pointSize: 10
											font.family: "Symbols Nerd Font"
											color: Root.Color.overlay1
											rotation: root.deviceSelectorOpen ? 90 : -90
											Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
										}
									}

									MouseArea {
										id: deviceSelectorMa
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: root.deviceSelectorOpen = !root.deviceSelectorOpen
									}
								}

								// Dropdown list
								ColumnLayout {
									id: deviceDropdown
									Layout.fillWidth: true
									spacing: 0
									clip: true

									property var sinkNodes: root.getSinkNodes()
									property int fullHeight: root.deviceSelectorOpen ? (1 + sinkNodes.length * 34) : 0
									Layout.preferredHeight: fullHeight

								opacity: root.deviceSelectorOpen ? 1.0 : 0.0
								Behavior on opacity {
									NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
								}

								transform: Translate {
									y: root.deviceSelectorOpen ? 0 : -16
									Behavior on y {
										NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
									}
								}

								Rectangle {
									Layout.fillWidth: true
									height: 1
									color: Root.Color.overlay0
									opacity: 0.2
								}

									Repeater {
										model: deviceDropdown.sinkNodes.length

										Rectangle {
											required property int index
											property var node: deviceDropdown.sinkNodes[index]
											property bool isDefault: root.sink && node && root.sink.id === node.id

											Layout.fillWidth: true
											height: 34
											color: isDefault
												? Root.Color.surface0
												: (deviceItemMa.containsMouse ? Root.Color.surface0 : "transparent")
											Behavior on color { ColorAnimation { duration: 150 } }
											radius: 6

											RowLayout {
												anchors.fill: parent
												anchors.leftMargin: 10
												anchors.rightMargin: 10
												spacing: 6

												Text {
													text: isDefault ? "󰓃" : "󰕾"
													font.family: "Symbols Nerd Font Mono"
													font.pointSize: 10
													color: isDefault ? Root.Color.lavender : Root.Color.overlay1
												}

												Text {
													text: node ? (node.description || node.name) : ""
													font.pointSize: 10
													font.bold: isDefault
													color: isDefault ? Root.Color.lavender : Root.Color.subtext1
													elide: Text.ElideRight
													Layout.fillWidth: true
												}

												Text {
													visible: isDefault
													text: "✓"
													font.pointSize: 10
													color: Root.Color.green
												}
											}

											MouseArea {
												id: deviceItemMa
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onClicked: {
													if (node && !isDefault) {
														root.selectSink(node);
													}
												}
											}
										}
									}
								}
							}
						}

						// ===== App volume mixer =====
						Item {
							Layout.fillWidth: true
							Layout.preferredHeight: appVolumeCol.implicitHeight

							ColumnLayout {
								id: appVolumeCol
								anchors.left: parent.left
								anchors.right: parent.right
								spacing: 0

								Rectangle {
									Layout.fillWidth: true
									height: 32
									radius: root.appVolumeOpen ? 8 : 16
									color: appVolumeMa.containsMouse ? Root.Color.surface1 : Root.Color.surface0
									Behavior on color { ColorAnimation { duration: 150 } }

									RowLayout {
										anchors.fill: parent
										anchors.leftMargin: 12
										anchors.rightMargin: 12
										spacing: 6

										Text {
											text: "󰕾"
											font.family: "Symbols Nerd Font Mono"
											font.pointSize: 10
											color: Root.Color.overlay1
										}

										Text {
											text: "应用音量"
											font.pointSize: 10
											color: Root.Color.subtext1
											Layout.fillWidth: true
										}

										Text {
											text: root.appVolumeOpen ? "󰅁" : "󰅂"
											font.pointSize: 10
											font.family: "Symbols Nerd Font"
											color: Root.Color.overlay1
											rotation: root.appVolumeOpen ? 90 : -90
											Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
										}
									}

									MouseArea {
										id: appVolumeMa
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: root.appVolumeOpen = !root.appVolumeOpen
									}
								}

								// App list
								ColumnLayout {
									id: appDropdown
									Layout.fillWidth: true
									spacing: 0
									clip: true

									property var streamNodes: []
									property int fullHeight: root.appVolumeOpen ? (1 + streamNodes.length * 52) : 0
									Layout.preferredHeight: fullHeight

									function refresh() { streamNodes = root.getStreamNodes(); }

									// Refresh on open and periodically while open
									Timer {
										id: streamRefresh
										interval: 1500
										repeat: true
										running: root.appVolumeOpen
										onTriggered: appDropdown.refresh()
									}

									Connections {
										target: root
										function onAppVolumeOpenChanged() {
											if (root.appVolumeOpen) appDropdown.refresh();
										}
									}

								opacity: root.appVolumeOpen ? 1.0 : 0.0
								Behavior on opacity {
									NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
								}

								transform: Translate {
									y: root.appVolumeOpen ? 0 : -16
									Behavior on y {
										NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
									}
								}

								Rectangle {
									Layout.fillWidth: true
									height: 1
									color: Root.Color.overlay0
									opacity: 0.2
								}

									// Empty state
									Text {
										visible: appDropdown.streamNodes.length === 0
										text: "没有正在播放的应用"
										font.pointSize: 10
										color: Root.Color.overlay1
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										Layout.topMargin: 8
										Layout.bottomMargin: 8
									}

									Repeater {
										model: appDropdown.streamNodes.length

										Item {
											required property int index
											property var node: appDropdown.streamNodes[index]

											Layout.fillWidth: true
											height: 52

											ColumnLayout {
												anchors.fill: parent
												anchors.leftMargin: 4
												anchors.rightMargin: 4
												spacing: 2

												// App name + percentage + mute
												RowLayout {
													Layout.fillWidth: true
													spacing: 6

													Text {
														text: "󰎆"
														font.family: "Symbols Nerd Font Mono"
														font.pointSize: 9
														color: node && node.audio.muted ? Root.Color.overlay0 : Root.Color.peach
													}

													Text {
														text: node ? (node.description || node.name || "未知") : ""
														font.pointSize: 9
														color: node && node.audio.muted ? Root.Color.overlay0 : Root.Color.subtext1
														elide: Text.ElideRight
														Layout.fillWidth: true
													}

													Text {
														text: node ? Math.round(node.audio.volume * 100) + "%" : "0%"
														font.pointSize: 9
														font.bold: true
														color: node && node.audio.muted ? Root.Color.overlay0 : Root.Color.subtext0
													}

													// Per-app mute button
													Rectangle {
														width: 20
														height: 20
														radius: width / 2
														color: node && node.audio.muted
															? Root.Color.red
															: (appMuteMa.containsMouse ? Root.Color.surface1 : "transparent")
														Behavior on color { ColorAnimation { duration: 150 } }

														Text {
															anchors.centerIn: parent
															text: node && node.audio.muted ? "󰖁" : "󰕾"
															font.family: "Symbols Nerd Font Mono"
															font.pointSize: 9
															color: node && node.audio.muted ? Root.Color.base : Root.Color.overlay1
														}

														MouseArea {
															id: appMuteMa
															anchors.fill: parent
															hoverEnabled: true
															cursorShape: Qt.PointingHandCursor
															onClicked: {
																if (node) root.toggleStreamMute(node.id);
															}
														}
													}
												}

												// Per-app slider
												Item {
													Layout.fillWidth: true
													height: 20

													Rectangle {
														anchors.verticalCenter: parent.verticalCenter
														width: parent.width
														height: 4
														radius: height / 2
														color: Root.Color.surface0

														Rectangle {
															width: node ? parent.width * Math.min(node.audio.volume, 1.0) : 0
															height: parent.height
															radius: height / 2
															color: node && node.audio.muted ? Root.Color.overlay0 : Root.Color.peach

															Behavior on width {
																NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
															}
															Behavior on color {
																ColorAnimation { duration: 150 }
															}
														}
													}

													// Small handle
													Rectangle {
														width: 12
														height: 12
														radius: width / 2
														color: appSliderDrag.pressed
															? Root.Color.peach
															: (appSliderDrag.containsMouse ? Root.Color.text : Root.Color.subtext1)
														anchors.verticalCenter: parent.verticalCenter
														x: node
															? Math.max(0, Math.min(parent.width - width, parent.width * Math.min(node.audio.volume, 1.0) - width / 2))
															: 0

														Behavior on color { ColorAnimation { duration: 100 } }
														Behavior on x {
															enabled: !appSliderDrag.pressed
															NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
														}
													}

													MouseArea {
														id: appSliderDrag
														anchors.fill: parent
														hoverEnabled: true
														cursorShape: Qt.PointingHandCursor
														preventStealing: true

														onPressed: mouse => {
															if (node) {
																const ratio = Math.max(0, Math.min(1, mouse.x / width));
																root.setStreamVolume(node.id, ratio);
															}
														}
														onPositionChanged: mouse => {
															if (pressed && node) {
																const ratio = Math.max(0, Math.min(1, mouse.x / width));
																root.setStreamVolume(node.id, ratio);
															}
														}
														onWheel: wheel => {
															if (!node) return;
															const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
															root.setStreamVolume(node.id, root.clampVolume(node.audio.volume + delta));
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
		}
	}
}
