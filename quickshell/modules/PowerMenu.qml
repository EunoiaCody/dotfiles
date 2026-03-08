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

	onImplicitWidthChanged: Root.BarLayout.updateWidth("powermenu", implicitWidth)
	Component.onCompleted: Root.BarLayout.updateWidth("powermenu", implicitWidth)

	WlrLayershell.layer: WlrLayer.Top

	property bool panelOpen: false
	property bool _panelClosing: false

	Timer {
		id: closeDelayTimer
		interval: 380
		onTriggered: {
			Root.PanelStack.panelClosed("power");
			root._panelClosing = false;
		}
	}

	onPanelOpenChanged: {
		if (panelOpen) {
			Root.PanelStack.panelOpened("power", 0);
		} else {
			root._panelClosing = true;
			closeDelayTimer.start();
		}
	}

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

			property real panelTop: Root.PanelStack.topFor("power")
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
			implicitHeight: menuColumn.implicitHeight + 48
			color: "transparent"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "power-menu"

			onImplicitHeightChanged: Root.PanelStack.updateHeight("power", implicitHeight)
			Component.onCompleted: Root.PanelStack.updateHeight("power", implicitHeight)

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
						id: menuColumn
						anchors {
							left: parent.left
							right: parent.right
							top: parent.top
							margins: 16
						}
						spacing: 12

						// Header
						Text {
							text: "电源菜单"
							font.pointSize: 14
							font.bold: true
							color: Root.Color.lavender
							Layout.fillWidth: true
						}

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
								implicitHeight: 44
								radius: height / 2
								color: itemMouse.containsMouse ? (modelData.cmd === "systemctl poweroff" ? Root.Color.red : Root.Color.lavender) : Root.Color.mantle

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
										root.panelOpen = false;
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
	}

	Process {
		id: actionProcess
		running: false
	}
}
