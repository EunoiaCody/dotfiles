import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
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
		right: Root.BarLayout.rightMarginFor("notifications")
	}

	implicitWidth: notifBtn.width + 4
	implicitHeight: notifBtn.height + 12
	color: "transparent"

	onImplicitWidthChanged: Root.BarLayout.updateWidth("notifications", implicitWidth)
	Component.onCompleted: Root.BarLayout.updateWidth("notifications", implicitWidth)

	WlrLayershell.layer: WlrLayer.Top

	property bool panelOpen: false
	property bool _panelClosing: false

	// Close animation delay timer (lives outside LazyLoader)
	Timer {
		id: closeDelayTimer
		interval: 380
		onTriggered: {
			Root.PanelStack.panelClosed("notifications");
			root._panelClosing = false;
		}
	}

	// Auto-close timer for when opened with no notifications
	Timer {
		id: emptyAutoCloseTimer
		interval: 5000
		onTriggered: {
			if (root.panelOpen && notifServer.trackedNotifications.values.length === 0) {
				root.panelOpen = false;
			}
		}
	}

	// Monitor notification count - auto-close when empty
	Connections {
		target: notifServer
		function onTrackedNotificationsChanged() {
			if (root.panelOpen && notifServer.trackedNotifications.values.length === 0) {
				root.panelOpen = false;
			}
		}
	}

	onPanelOpenChanged: {
		if (panelOpen) {
			Root.PanelStack.panelOpened("notifications", 0);
			if (notifServer.trackedNotifications.values.length === 0) {
				emptyAutoCloseTimer.start();
			}
		} else {
			emptyAutoCloseTimer.stop();
			root._panelClosing = true;
			closeDelayTimer.start();
		}
	}

	// Notification server
	NotificationServer {
		id: notifServer
		keepOnReload: true
		actionsSupported: true
		bodySupported: true
		bodyMarkupSupported: true
		imageSupported: true

		onNotification: notification => {
			notification.tracked = true;
			// Push toast
			toastModel.insert(0, {
				notifSummary: notification.summary || notification.appName,
				notifBody: notification.body || "",
				notifApp: notification.appName || "Unknown"
			});
			// Auto-dismiss toast after 4 seconds
			toastDismissTimer.restart();
		}
	}

	// Toast model
	ListModel {
		id: toastModel
	}

	Timer {
		id: toastDismissTimer
		interval: 4000
		onTriggered: {
			if (toastModel.count > 0) {
				toastModel.remove(toastModel.count - 1);
				if (toastModel.count > 0) restart();
			}
		}
	}

	property int notifCount: notifServer.trackedNotifications.values.length

	// Bell button
	Rectangle {
		id: notifBtn
		anchors.centerIn: parent
		width: 40
		height: 40
		radius: width / 2
		color: bellMouse.containsMouse ? Root.Color.lavender : Root.Color.base

		Behavior on color {
			ColorAnimation { duration: 150 }
		}

		Text {
			anchors.centerIn: parent
			text: "🔔"
			font.pointSize: 15
			color: bellMouse.containsMouse ? Root.Color.base : Root.Color.lavender
		}

		// Badge for unread count
		Rectangle {
			visible: root.notifCount > 0
			anchors {
				top: parent.top
				right: parent.right
				topMargin: -3
				rightMargin: -3
			}
			width: Math.max(badgeText.width + 6, 18)
			height: 18
			radius: height / 2
			color: Root.Color.red

			Text {
				id: badgeText
				anchors.centerIn: parent
				text: root.notifCount > 99 ? "99+" : root.notifCount
				font.pointSize: 9
				font.bold: true
				color: Root.Color.base
			}
		}

		MouseArea {
			id: bellMouse
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: root.panelOpen = !root.panelOpen
		}
	}

	// ===== Toast popup window =====
	LazyLoader {
		id: toastLoader
		active: toastModel.count > 0 && !root.panelOpen

		PanelWindow {
			screen: root.screen

			anchors {
				top: true
				right: true
			}

			exclusiveZone: -1
			margins {
				top: 44
				right: 8
			}

			implicitWidth: 320
			implicitHeight: toastColumn.height + 8
			color: "transparent"

			mask: Region {}

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "notification-toast"

			ColumnLayout {
				id: toastColumn
				width: parent.width
				spacing: 6

				Repeater {
					model: toastModel

					Rectangle {
						required property string notifSummary
						required property string notifBody
						required property string notifApp
						required property int index

						Layout.fillWidth: true
						implicitHeight: toastContent.height + 20
						radius: 14
						color: Root.Color.base
						border.width: 2
						border.color: Root.Color.lavender

						// Slide in from right
						x: 0
						opacity: 1.0

						Component.onCompleted: {
							slideIn.start();
						}

						ParallelAnimation {
							id: slideIn
							NumberAnimation {
								target: parent
								property: "x"
								from: 80
								to: 0
								duration: 350
								easing.type: Easing.OutBack
								easing.overshoot: 0.8
							}
							NumberAnimation {
								target: parent
								property: "opacity"
								from: 0
								to: 1.0
								duration: 300
								easing.type: Easing.OutCubic
							}
						}

						ColumnLayout {
							id: toastContent
							anchors {
								left: parent.left
								right: parent.right
								top: parent.top
								margins: 12
							}
							spacing: 3

							RowLayout {
								Layout.fillWidth: true

								Text {
									text: notifSummary
									font.pointSize: 11
									font.bold: true
									color: Root.Color.text
									elide: Text.ElideRight
									Layout.fillWidth: true
								}

								Text {
									text: notifApp
									font.pointSize: 8
									color: Root.Color.overlay1
								}
							}

							Text {
								visible: notifBody !== ""
								text: notifBody
								font.pointSize: 10
								color: Root.Color.subtext0
								elide: Text.ElideRight
								Layout.fillWidth: true
								maximumLineCount: 2
								wrapMode: Text.Wrap
							}
						}
					}
				}
			}
		}
	}

	// ===== Slide-in notification panel =====
	LazyLoader {
		id: panelLoader
		active: root.panelOpen || root._panelClosing

		PanelWindow {
			id: slidePanel
			screen: root.screen

			property real panelTop: Root.PanelStack.topFor("notifications")
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
			implicitHeight: Math.min(panelContentCol.implicitHeight + 32, 500)
			color: "transparent"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "notification-panel"

			onImplicitHeightChanged: Root.PanelStack.updateHeight("notifications", implicitHeight)
			Component.onCompleted: Root.PanelStack.updateHeight("notifications", implicitHeight)

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
						id: panelContentCol
						anchors {
							left: parent.left
							right: parent.right
							top: parent.top
							margins: 16
						}
						spacing: 12

						// Header
						RowLayout {
							id: headerRow
							Layout.fillWidth: true

							Text {
								text: "通知"
								font.pointSize: 14
								font.bold: true
								color: Root.Color.lavender
								Layout.fillWidth: true
							}

							// Clear all button
							Rectangle {
								visible: root.notifCount > 0
								width: clearText.width + 16
								height: clearText.height + 8
								radius: height / 2
								color: clearMouse.containsMouse ? Root.Color.red : Root.Color.surface0

								Behavior on color {
									ColorAnimation { duration: 150 }
								}

								Text {
									id: clearText
									anchors.centerIn: parent
									text: "清除全部"
									font.pointSize: 10
									color: clearMouse.containsMouse ? Root.Color.base : Root.Color.subtext1

									Behavior on color {
										ColorAnimation { duration: 150 }
									}
								}

								MouseArea {
									id: clearMouse
									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: {
										const notifs = notifServer.trackedNotifications.values;
										for (let i = notifs.length - 1; i >= 0; i--) {
											notifs[i].tracked = false;
										}
									}
								}
							}
						}

						// Empty state
						Text {
							visible: root.notifCount === 0
							text: "无历史通知"
							font.pointSize: 11
							color: Root.Color.subtext0
							Layout.alignment: Qt.AlignHCenter
							Layout.topMargin: 20
							Layout.bottomMargin: 20
						}

						// Notification list
						ColumnLayout {
							id: notifList
							visible: root.notifCount > 0
							Layout.fillWidth: true
							spacing: 6

							Repeater {
								model: notifServer.trackedNotifications

								Rectangle {
									id: notifItem
									required property var modelData

									Layout.fillWidth: true
									implicitHeight: notifRow.height + 16
									radius: 12
									color: notifMouse.containsMouse ? Root.Color.surface0 : Root.Color.mantle

									Behavior on color {
										ColorAnimation { duration: 150 }
									}

									RowLayout {
										id: notifRow
										anchors {
											left: parent.left
											right: parent.right
											verticalCenter: parent.verticalCenter
											leftMargin: 12
											rightMargin: 12
										}
										spacing: 10

										// App icon placeholder
										Rectangle {
											width: 36
											height: 36
											radius: 8
											color: Root.Color.surface1

											Text {
												anchors.centerIn: parent
												text: notifItem.modelData.appName.charAt(0).toUpperCase()
												font.pointSize: 14
												font.bold: true
												color: Root.Color.lavender
											}
										}

										ColumnLayout {
											Layout.fillWidth: true
											spacing: 2

											RowLayout {
												Layout.fillWidth: true

												Text {
													text: notifItem.modelData.summary || notifItem.modelData.appName
													font.pointSize: 11
													font.bold: true
													color: Root.Color.text
													elide: Text.ElideRight
													Layout.fillWidth: true
												}

												Text {
													text: notifItem.modelData.appName
													font.pointSize: 9
													color: Root.Color.overlay1
												}
											}

											Text {
												visible: text !== ""
												text: notifItem.modelData.body || ""
												font.pointSize: 10
												color: Root.Color.subtext0
												elide: Text.ElideRight
												Layout.fillWidth: true
												maximumLineCount: 2
												wrapMode: Text.Wrap
											}
										}

										// Dismiss button
										Rectangle {
											width: 24
											height: 24
											radius: width / 2
											color: dismissMouse.containsMouse ? Root.Color.red : "transparent"
											visible: notifMouse.containsMouse

											Behavior on color {
												ColorAnimation { duration: 150 }
											}

											Text {
												anchors.centerIn: parent
												text: "✕"
												font.pointSize: 9
												color: dismissMouse.containsMouse ? Root.Color.base : Root.Color.overlay1
											}

											MouseArea {
												id: dismissMouse
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onClicked: notifItem.modelData.tracked = false
											}
										}
									}

									MouseArea {
										id: notifMouse
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: {
											const appName = notifItem.modelData.appName;
											const notifs = notifServer.trackedNotifications.values;
											for (let i = notifs.length - 1; i >= 0; i--) {
												if (notifs[i].appName === appName) {
													notifs[i].tracked = false;
												}
											}
											if (notifItem.modelData.actions.length > 0) {
												notifItem.modelData.actions[0].invoke();
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
