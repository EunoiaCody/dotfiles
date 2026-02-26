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
		right: 8
	}

	implicitWidth: powerBtn.width + 4
	implicitHeight: powerBtn.height + 12
	color: "transparent"

	WlrLayershell.layer: WlrLayer.Top

	property bool menuOpen: false

	// Power button (circle with power icon)
	Rectangle {
		id: powerBtn
		anchors.centerIn: parent
		width: 40
		height: 40
		radius: width / 2
		color: powerMouse.containsMouse ? Root.Color.red : Root.Color.base

		Behavior on color {
			ColorAnimation { duration: 150 }
		}

		Text {
			anchors.centerIn: parent
			text: "⏻"
			font.pointSize: 16
			color: powerMouse.containsMouse ? Root.Color.base : Root.Color.lavender

			Behavior on color {
				ColorAnimation { duration: 150 }
			}
		}

		MouseArea {
			id: powerMouse
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: {
				root.menuOpen = !root.menuOpen;
			}
		}
	}

	// Popup menu (centered on screen)
	LazyLoader {
		id: menuLoader
		active: root.menuOpen

		PanelWindow {
			id: menuWindow
			screen: root.screen

			anchors {
				top: true
				bottom: true
				left: true
				right: true
			}

			exclusiveZone: -1
			color: "#80000000"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "power-menu"

			// Click backdrop to close
			MouseArea {
				anchors.fill: parent
				onClicked: root.menuOpen = false
			}

			// Menu card
			Rectangle {
				id: menuCard
				anchors.centerIn: parent
				width: menuColumn.width + 48
				height: menuColumn.height + 48
				radius: 20
				color: Root.Color.base

				// Appear animation
				scale: 0.8
				opacity: 0

				Component.onCompleted: {
					scale = 1.0;
					opacity = 1.0;
				}

				Behavior on scale {
					NumberAnimation {
						duration: 250
						easing.type: Easing.OutCubic
					}
				}

				Behavior on opacity {
					NumberAnimation {
						duration: 250
						easing.type: Easing.OutCubic
					}
				}

				// Stop clicks from passing through to backdrop
				MouseArea {
					anchors.fill: parent
				}

				ColumnLayout {
					id: menuColumn
					anchors.centerIn: parent
					spacing: 8

					Repeater {
						model: [
							{ label: "关机", icon: "⏻", cmd: "systemctl poweroff" },
							{ label: "重启", icon: "↻", cmd: "systemctl reboot" },
							{ label: "锁定", icon: "🔒", cmd: "loginctl lock-session" },
							{ label: "注销", icon: "↩", cmd: "niri msg action quit" }
						]

						Rectangle {
							required property var modelData
							required property int index

							Layout.fillWidth: true
							implicitWidth: 220
							implicitHeight: 44
							radius: height / 2
							color: itemMouse.containsMouse ? Root.Color.lavender : "transparent"

							Behavior on color {
								ColorAnimation { duration: 150 }
							}

							RowLayout {
								anchors {
									fill: parent
									leftMargin: 20
									rightMargin: 20
								}
								spacing: 12

								Text {
									text: modelData.icon
									font.pointSize: 14
									color: itemMouse.containsMouse ? Root.Color.base : Root.Color.lavender

									Behavior on color {
										ColorAnimation { duration: 150 }
									}
								}

								Text {
									text: modelData.label
									font.pointSize: 13
									color: itemMouse.containsMouse ? Root.Color.base : Root.Color.lavender
									Layout.fillWidth: true

									Behavior on color {
										ColorAnimation { duration: 150 }
									}
								}
							}

							MouseArea {
								id: itemMouse
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									root.menuOpen = false;
									actionProcess.command = ["bash", "-c", modelData.cmd];
									actionProcess.running = true;
								}
							}
						}
					}
				}
			}
		}
	}

	Process {
		id: actionProcess
		running: false
	}
}
