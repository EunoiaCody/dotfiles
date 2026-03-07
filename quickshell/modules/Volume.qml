import QtQuick
import QtQuick.Layouts
import Quickshell
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
		right: 96
	}

	implicitWidth: volPill.width + 4
	implicitHeight: volPill.height + 12
	color: "transparent"

	WlrLayershell.layer: WlrLayer.Top

	property bool panelOpen: false
	property bool _panelClosing: false

	// Bind default audio sink
	PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

	property PwNode sink: Pipewire.defaultAudioSink
	property int volumePercent: sink ? Math.round(sink.audio.volume * 100) : 0

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
					// Middle click toggles mute
					if (root.sink) root.sink.audio.muted = !root.sink.audio.muted;
				} else {
					root.panelOpen = !root.panelOpen;
				}
			}

			onWheel: wheel => {
				if (!root.sink) return;
				const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
				root.sink.audio.volume = root.clampVolume(root.sink.audio.volume + delta);
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
										if (root.sink) root.sink.audio.muted = !root.sink.audio.muted;
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
									root.sink.audio.volume = ratio;
								}

								onPressed: mouse => updateVolume(mouse.x)
								onPositionChanged: mouse => {
									if (pressed) updateVolume(mouse.x);
								}

								onWheel: wheel => {
									if (!root.sink) return;
									const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
									root.sink.audio.volume = root.clampVolume(root.sink.audio.volume + delta);
								}
							}
						}

						// Sink name
						Text {
							Layout.fillWidth: true
							text: root.sink ? (root.sink.description || root.sink.name) : "未知设备"
							font.pointSize: 9
							color: Root.Color.overlay1
							elide: Text.ElideRight
						}
					}
				}
			}
		}
	}
}
