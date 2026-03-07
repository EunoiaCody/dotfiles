import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." as Root

PanelWindow {
	id: root

	property var modelData
	screen: modelData

	anchors {
		top: true
	}

	exclusiveZone: clockPill.height
	margins.top: 0

	implicitWidth: clockPill.width + 4
	implicitHeight: clockPill.height + 12

	property string monthYearLabel: ""
	color: "transparent"

	WlrLayershell.layer: WlrLayer.Top

	property bool panelOpen: false
	property bool _panelClosing: false
	property int currentTab: 0

	Timer {
		id: closeDelayTimer
		interval: 380
		onTriggered: root._panelClosing = false
	}

	onPanelOpenChanged: {
		if (panelOpen) {
			calendarLogic.generateCalendar();
		} else {
			root._panelClosing = true;
			closeDelayTimer.start();
		}
	}

	// ===== Clock pill =====
	Rectangle {
		id: clockPill
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.top
		anchors.topMargin: 6
		width: timeRow.width + 24
		height: timeRow.height + 16
		radius: height / 2
		color: clockMouse.containsMouse ? Root.Color.lavender : Root.Color.base

		Behavior on color { ColorAnimation { duration: 150 } }

		RowLayout {
			id: timeRow
			anchors.centerIn: parent
			spacing: 8

			Text {
				id: dateText
				color: clockMouse.containsMouse ? Root.Color.base : Root.Color.lavender
				font.pointSize: 12
				font.bold: true
				Behavior on color { ColorAnimation { duration: 150 } }
			}

			Text {
				id: timeText
				color: clockMouse.containsMouse ? Root.Color.base : Root.Color.lavender
				font.pointSize: 12
				Behavior on color { ColorAnimation { duration: 150 } }
			}
		}

		MouseArea {
			id: clockMouse
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: root.panelOpen = !root.panelOpen
		}
	}

	// ===== Slide-in dashboard panel =====
	LazyLoader {
		id: panelLoader
		active: root.panelOpen || root._panelClosing

		PanelWindow {
			id: dashPanel
			screen: root.screen

			anchors {
				top: true
			}

			exclusiveZone: -1
			margins.top: 56

			implicitWidth: 420
			implicitHeight: 460
			color: "transparent"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "dashboard-panel"

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

					scale: _showContent ? 1.0 : 0.85
					opacity: _showContent ? 1.0 : 0

					Behavior on scale {
						NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
					}
					Behavior on opacity {
						NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
					}

					ColumnLayout {
						anchors.fill: parent
						anchors.margins: 16
						spacing: 0

						// Header
						RowLayout {
							Layout.fillWidth: true
							Layout.preferredHeight: 40
							spacing: 8

							Text {
								text: dateText.text + "  " + timeText.text
								font.pointSize: 13
								font.bold: true
								color: Root.Color.lavender
							}

							Item { Layout.fillWidth: true }

							Repeater {
								model: [
									{ label: "日历", icon: "📅" }
								]

								Rectangle {
									required property var modelData
									required property int index

									width: tabRow.width + 20
									height: 30
									radius: height / 2
									color: root.currentTab === index
										? Root.Color.lavender
										: (tabMa.containsMouse ? Root.Color.surface1 : Root.Color.surface0)
									Behavior on color { ColorAnimation { duration: 150 } }

									RowLayout {
										id: tabRow
										anchors.centerIn: parent
										spacing: 4
										Text { text: modelData.icon; font.pointSize: 10 }
										Text {
											text: modelData.label; font.pointSize: 10
											font.bold: root.currentTab === index
											color: root.currentTab === index ? Root.Color.base : Root.Color.subtext1
											Behavior on color { ColorAnimation { duration: 150 } }
										}
									}
									MouseArea { id: tabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.currentTab = index }
								}
							}

							Rectangle {
								width: 30; height: 30; radius: width / 2
								color: closeMA.containsMouse ? Root.Color.red : Root.Color.surface0
								Behavior on color { ColorAnimation { duration: 150 } }
								Text {
									anchors.centerIn: parent; text: "✕"; font.pointSize: 10
									color: closeMA.containsMouse ? Root.Color.base : Root.Color.overlay1
									Behavior on color { ColorAnimation { duration: 150 } }
								}
								MouseArea { id: closeMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.panelOpen = false }
							}
						}

						Rectangle {
							Layout.fillWidth: true; height: 1
							color: Root.Color.overlay0; opacity: 0.2
							Layout.topMargin: 8; Layout.bottomMargin: 8
						}

						// ===== Calendar tab =====
						Item {
							Layout.fillWidth: true
							Layout.fillHeight: true
							visible: root.currentTab === 0

							ColumnLayout {
								anchors.fill: parent
								spacing: 10

								RowLayout {
									Layout.fillWidth: true

									Rectangle {
										width: 30; height: 30; radius: width / 2
										color: prevMa.containsMouse ? Root.Color.surface1 : "transparent"
										Behavior on color { ColorAnimation { duration: 150 } }
										Text { anchors.centerIn: parent; text: "‹"; font.pointSize: 18; color: Root.Color.overlay1 }
										MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: calendarLogic.changeMonth(-1) }
									}
									Item { Layout.fillWidth: true }
									Text { id: monthYearText; text: root.monthYearLabel; font.pointSize: 15; font.bold: true; color: Root.Color.lavender }
									Item { Layout.fillWidth: true }
									Rectangle {
										width: 30; height: 30; radius: width / 2
										color: nextMa.containsMouse ? Root.Color.surface1 : "transparent"
										Behavior on color { ColorAnimation { duration: 150 } }
										Text { anchors.centerIn: parent; text: "›"; font.pointSize: 18; color: Root.Color.overlay1 }
										MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: calendarLogic.changeMonth(1) }
									}
									Rectangle {
										width: todayLbl.width + 14; height: 26; radius: height / 2
										color: todayMa.containsMouse ? Root.Color.lavender : Root.Color.surface0
										visible: calendarLogic.viewMonth !== calendarLogic.realMonth || calendarLogic.viewYear !== calendarLogic.realYear
										Behavior on color { ColorAnimation { duration: 150 } }
										Text { id: todayLbl; anchors.centerIn: parent; text: "今天"; font.pointSize: 10; color: todayMa.containsMouse ? Root.Color.base : Root.Color.subtext1 }
										MouseArea { id: todayMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: calendarLogic.goToToday() }
									}
								}

								RowLayout {
									Layout.fillWidth: true; spacing: 0
									Repeater {
										model: ["一", "二", "三", "四", "五", "六", "日"]
										Item {
											Layout.fillWidth: true; Layout.preferredHeight: 22
											Text { anchors.centerIn: parent; text: modelData; font.pointSize: 11; font.bold: true; color: (index === 5 || index === 6) ? Root.Color.overlay0 : Root.Color.subtext0 }
										}
									}
								}

								GridLayout {
									Layout.fillWidth: true; Layout.fillHeight: true
									columns: 7; columnSpacing: 0; rowSpacing: 2
									Repeater {
										model: calendarModel
										Item {
											Layout.fillWidth: true; Layout.fillHeight: true
											Rectangle {
												width: 32; height: 32; radius: 16; anchors.centerIn: parent
												color: model.isToday ? Root.Color.lavender : (dayMa.containsMouse && model.isCurrentMonth ? Root.Color.surface1 : "transparent")
												Behavior on color { ColorAnimation { duration: 150 } }
											}
											Text {
												anchors.centerIn: parent; text: model.dayText; font.pointSize: 12; font.bold: model.isToday
												color: {
													if (model.isToday) return Root.Color.base;
													if (!model.isCurrentMonth) return Root.Color.surface2;
													if (model.isWeekend) return Root.Color.overlay1;
													return Root.Color.text;
												}
											}
											MouseArea { id: dayMa; anchors.fill: parent; hoverEnabled: true; cursorShape: model.isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor }
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

	// ===== Calendar logic =====
	ListModel { id: calendarModel }

	QtObject {
		id: calendarLogic
		property int viewYear: new Date().getFullYear()
		property int viewMonth: new Date().getMonth()
		property int realYear: new Date().getFullYear()
		property int realMonth: new Date().getMonth()

		function changeMonth(delta) {
			viewMonth += delta;
			if (viewMonth > 11) { viewMonth = 0; viewYear++; }
			if (viewMonth < 0) { viewMonth = 11; viewYear--; }
			generateCalendar();
		}
		function goToToday() {
			const now = new Date();
			viewYear = now.getFullYear();
			viewMonth = now.getMonth();
			generateCalendar();
		}
		function generateCalendar() {
			calendarModel.clear();
			const monthNames = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"];
			root.monthYearLabel = viewYear + "年 " + monthNames[viewMonth];
			const todayDate = new Date().getDate();
			const todayMonth = new Date().getMonth();
			const todayYear = new Date().getFullYear();
			const startDay = (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7;
			const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
			const daysInPrevMonth = new Date(viewYear, viewMonth, 0).getDate();
			for (let i = 0; i < startDay; i++) {
				const isWeekend = (i % 7 === 5 || i % 7 === 6);
				calendarModel.append({ dayText: daysInPrevMonth - startDay + 1 + i, isCurrentMonth: false, isToday: false, isWeekend: isWeekend });
			}
			for (let i = 1; i <= daysInMonth; i++) {
				const dow = (startDay + i - 1) % 7;
				const isWeekend = (dow === 5 || dow === 6);
				const isToday = (i === todayDate && viewMonth === todayMonth && viewYear === todayYear);
				calendarModel.append({ dayText: i, isCurrentMonth: true, isToday: isToday, isWeekend: isWeekend });
			}
			const remaining = 42 - calendarModel.count;
			for (let i = 1; i <= remaining; i++) {
				const dow = (startDay + daysInMonth + i - 1) % 7;
				const isWeekend = (dow === 5 || dow === 6);
				calendarModel.append({ dayText: i, isCurrentMonth: false, isToday: false, isWeekend: isWeekend });
			}
		}
	}

	Timer {
		interval: 1000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			const now = new Date();
			const month = String(now.getMonth() + 1).padStart(2, '0');
			const day = String(now.getDate()).padStart(2, '0');
			const weekdays = ["日", "一", "二", "三", "四", "五", "六"];
			const weekday = weekdays[now.getDay()];
			dateText.text = `${month}月${day}日 周${weekday}`;

			const hours = String(now.getHours()).padStart(2, '0');
			const minutes = String(now.getMinutes()).padStart(2, '0');
			timeText.text = `${hours}:${minutes}`;
		}
	}

	Component.onCompleted: calendarLogic.generateCalendar()
}
