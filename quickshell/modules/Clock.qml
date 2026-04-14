import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
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

	property bool dashboardOpen: false
	property bool _dashboardClosing: false
	property int currentTab: 0
	property int activePlayerIndex: 0
	property var activePlayer: null
	property bool playerSelectorOpen: false

	// Wallpaper
	property int currentWallpaperIndex: 0
	property bool applying: false
	property string currentWallpaperPath: ""

	ListModel { id: wallpaperModel }

	QtObject {
		id: wallpaperLogic
		function loadWallpapers() {
			wallpaperListProcess.buf = ""
			wallpaperModel.clear()
			wallpaperListProcess.running = true
		}
		function addWallpaper(path) {
			if (!path || path.trim() === "") return
			var clean = path.trim()
			var lower = clean.toLowerCase()
			if (!(lower.endsWith(".png") || lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".webp"))) return
			var name = clean.split("/").pop()
			wallpaperModel.append({
				wallpaperPath: clean,
				wallpaperName: name
			})
		}
	}

	QtObject {
		id: wallpaperDetectLogic
		function detectCurrentWallpaper() {
			wallpaperDetectProcess.buf = ""
			wallpaperDetectProcess.running = true
		}
	}

	Process {
		id: wallpaperListProcess
		command: ["bash", "-lc", "ls -1 \"$HOME/Wallpapers\"/*.{png,jpg,jpeg,webp} 2>/dev/null | sort"]
		property string buf: ""
		stdout: SplitParser { onRead: data => { wallpaperListProcess.buf += data + "\n" } }
		onExited: (code, status) => {
			wallpaperModel.clear()
			var lines = wallpaperListProcess.buf.split(/\r?\n/)
			for (var i = 0; i < lines.length; i++) {
				wallpaperLogic.addWallpaper(lines[i])
			}
			wallpaperListProcess.buf = ""
			wallpaperDetectLogic.detectCurrentWallpaper()
		}
	}

	Process {
		id: wallpaperProcess
		command: [
			"bash", "-lc",
			"awww img \"$1\" --transition-type any --transition-bezier \".23,.43,.69,-0.29\" --transition-step 90 --transition-fps 120 >>/tmp/niri-wallpaper.log 2>&1",
			"",
			currentWallpaperPath
		]
		onExited: { applying = false; wallpaperDetectLogic.detectCurrentWallpaper() }
	}

	Process {
		id: wallpaperDetectProcess
		command: ["awww", "query"]
		property string buf: ""
		stdout: SplitParser { onRead: data => { wallpaperDetectProcess.buf += data } }
		onExited: {
			var currentPath = wallpaperDetectProcess.buf.trim()
			wallpaperDetectProcess.buf = ""
			var foundIdx = -1
			for (var i = 0; i < wallpaperModel.count; i++) {
				if (wallpaperModel.get(i).wallpaperPath === currentPath) {
					foundIdx = i
					break
				}
			}
			if (foundIdx !== -1) {
				currentWallpaperIndex = foundIdx
				wallpaperView.currentIndex = foundIdx
				wallpaperView.positionViewAtIndex(foundIdx, PathView.Center)
			}
		}
	}
	
	function applyWallpaper(path, index) {
		if (applying || !path || path === "") return
		applying = true
		currentWallpaperPath = path
		currentWallpaperIndex = index
		wallpaperProcess.running = true
	}

	// Media progress
	property real mediaProgressRatio: 0
	property real mediaPositionSec: 0
	property real mediaLengthSec: 0

	// Timer to poll position - needed because QML bindings don't auto-track
	// changes in nested object properties (like activePlayer.position)
	Timer {
		id: progressUpdateTimer
		interval: 100
		running: root.dashboardOpen && root.currentTab === 1 && !!root.activePlayer
		repeat: true
		onTriggered: updateMediaProgress()
	}

	function updateMediaProgress() {
		if (!root.activePlayer) {
			mediaProgressRatio = 0;
			mediaPositionSec = 0;
			mediaLengthSec = 0;
			return;
		}
		var pos = root.activePlayer.position || 0;
		var len = root.activePlayer.length || 0;
		if (len <= 0 || !root.activePlayer.lengthSupported) {
			mediaProgressRatio = 0;
			mediaPositionSec = 0;
			mediaLengthSec = 0;
			return;
		}
		// Handle microseconds vs seconds
		if (pos > 100000) pos = pos / 1000000;
		if (len > 100000) len = len / 1000000;
		mediaPositionSec = pos;
		mediaLengthSec = len;
		mediaProgressRatio = pos / len;
	}

	// Lyrics
	property var lyricsModel: []
	property int currentLineIndex: 0
	property string currentLoadedTitle: ""

	Process {
		id: lyricsFetcher
		command: ["python3", Quickshell.shellDir + "/scripts/lyrics_fetcher.py", root.activePlayer ? root.activePlayer.trackTitle : "", root.activePlayer ? root.activePlayer.trackArtist : ""]
		stdout: SplitParser {
			onRead: data => {
				try {
					var json = JSON.parse(data);
					if (json.length > 0) {
						root.lyricsModel = json;
						root.currentLineIndex = 0;
						root.currentLoadedTitle = root.activePlayer ? root.activePlayer.trackTitle : "";
					} else {
						root.lyricsModel = [{time: 0, text: "暂无歌词"}];
					}
				} catch (e) {
					root.lyricsModel = [{time: 0, text: "歌词加载失败"}];
				}
			}
		}
	}

	Timer {
		id: lyricsDebounce
		interval: 300
		repeat: false
		onTriggered: {
			if (root.activePlayer && root.activePlayer.trackTitle !== "") {
				root.lyricsModel = [];
				root.currentLineIndex = 0;
				lyricsFetcher.running = true;
			}
		}
	}

	Timer {
		id: lyricsSyncTimer
		interval: 100
		running: root.dashboardOpen && root.currentTab === 1 && root.lyricsModel.length > 1 && root.activePlayer
		repeat: true
		onTriggered: {
			if (!root.activePlayer) return;
			var rawPos = root.activePlayer.position;
			var currentSec = (rawPos > 100000) ? (rawPos / 1000000) : rawPos;
			var activeIdx = -1;
			for (var i = 0; i < root.lyricsModel.length; i++) {
				if (root.lyricsModel[i].time <= (currentSec + 0.3)) activeIdx = i;
				else break;
			}
			if (activeIdx !== -1 && activeIdx !== root.currentLineIndex) {
				root.currentLineIndex = activeIdx;
			}
		}
	}

	function triggerLyricsReload() {
		if (lyricsFetcher.running) lyricsFetcher.running = false;
		lyricsDebounce.restart();
	}

	Connections {
		target: root.activePlayer
		function onTrackTitleChanged() {
			root.triggerLyricsReload();
		}
	}

	function updateActivePlayer() {
		var v = Mpris.players.values;
		if (!v || v.length === 0) {
			activePlayer = null;
			activePlayerIndex = 0;
			return;
		}
		if (activePlayerIndex >= v.length) activePlayerIndex = 0;
		activePlayer = v[activePlayerIndex];
	}

	function selectPlayer(idx) {
		activePlayerIndex = idx;
		updateActivePlayer();
		playerSelectorOpen = false;
	}

	Connections {
		target: Mpris.players
		function onValuesChanged() { root.updateActivePlayer() }
	}

	Timer {
		id: closeDelayTimer
		interval: 380
		onTriggered: root._dashboardClosing = false
	}

	onDashboardOpenChanged: {
		if (dashboardOpen) {
			if (currentTab === 0) calendarLogic.generateCalendar();
			if (currentTab === 1 && root.activePlayer && root.activePlayer.trackTitle !== root.currentLoadedTitle) {
				triggerLyricsReload();
			}
			if (currentTab === 2) {
				wallpaperLogic.loadWallpapers();
			}
		} else {
			root._dashboardClosing = true;
			closeDelayTimer.start();
		}
	}

	onActivePlayerChanged: {
		if (root.activePlayer && root.activePlayer.trackTitle !== root.currentLoadedTitle) {
			triggerLyricsReload();
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
			onClicked: root.dashboardOpen = !root.dashboardOpen
		}
	}

	// ===== Slide-in dashboard =====
	LazyLoader {
		id: dashboardLoader
		active: root.dashboardOpen || root._dashboardClosing

		PanelWindow {
			id: dashboardWindow
			screen: root.screen

			anchors {
				top: true
			}

			exclusiveZone: -1
			margins.top: 56

			implicitWidth: root.currentTab === 2 ? 1200 : 800
			implicitHeight: root.currentTab === 2 ? 500 : 800
			color: "transparent"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "dashboard"

			Behavior on implicitWidth {
				NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
			}
			Behavior on implicitHeight {
				NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
			}

			Item {
				anchors.fill: parent
				clip: true

				Rectangle {
					id: dashboardContent
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
						function onDashboardOpenChanged() {
							if (!root.dashboardOpen) dashboardContent._showContent = false
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
								model: ListModel {
									ListElement { label: "日历"; icon: "󰃭" }
									ListElement { label: "媒体"; icon: "󰝚" }
									ListElement { label: "壁纸"; icon: "󰘦" }
								}

								Rectangle {
									required property string label
									required property string icon
									required property int index

									implicitWidth: tabRowLayout.implicitWidth + 20
									height: 30
									radius: height / 2
									color: root.currentTab === index
										? Root.Color.lavender
										: (tabMa.containsMouse ? Root.Color.lavender : Root.Color.surface0)
									Behavior on color { ColorAnimation { duration: 150 } }

									RowLayout {
										id: tabRowLayout
										anchors.centerIn: parent
										spacing: 4
										Text { text: icon; font.pointSize: 10; font.family: "Symbols Nerd Font" }
										Text {
											text: label; font.pointSize: 10
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
									anchors.centerIn: parent; text: "󰅖"; font.pointSize: 12; font.family: "Symbols Nerd Font"
									color: closeMA.containsMouse ? Root.Color.base : Root.Color.overlay1
									Behavior on color { ColorAnimation { duration: 150 } }
								}
								MouseArea { id: closeMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dashboardOpen = false }
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
										Text { anchors.centerIn: parent; text: "󰅁"; font.pointSize: 14; font.family: "Symbols Nerd Font"; color: Root.Color.overlay1 }
										MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: calendarLogic.changeMonth(-1) }
									}
									Item { Layout.fillWidth: true }
									Text { id: monthYearText; text: root.monthYearLabel; font.pointSize: 15; font.bold: true; color: Root.Color.lavender }
									Item { Layout.fillWidth: true }
									Rectangle {
										width: 30; height: 30; radius: width / 2
										color: nextMa.containsMouse ? Root.Color.surface1 : "transparent"
										Behavior on color { ColorAnimation { duration: 150 } }
										Text { anchors.centerIn: parent; text: "󰅂"; font.pointSize: 14; font.family: "Symbols Nerd Font"; color: Root.Color.overlay1 }
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

						// ===== Media tab =====
						Item {
							Layout.fillWidth: true
							Layout.fillHeight: true
							visible: root.currentTab === 1

							// No player state
							ColumnLayout {
								anchors.centerIn: parent
								spacing: 12
								visible: !root.activePlayer

								Text {
									text: "󰝚"
									font.pointSize: 36
									font.family: "Symbols Nerd Font"
									Layout.alignment: Qt.AlignHCenter
								}
								Text {
									text: "没有正在播放的媒体"
									font.pointSize: 12
									color: Root.Color.subtext0
									Layout.alignment: Qt.AlignHCenter
								}
							}

							// Player UI
						ColumnLayout {
							anchors.fill: parent
							anchors.margins: 8
							spacing: 8
							visible: !!root.activePlayer

							// Player selector
							Item {
								Layout.fillWidth: true
								Layout.preferredHeight: playerSelectorCol.implicitHeight
								visible: Mpris.players.values.length > 1

								ColumnLayout {
									id: playerSelectorCol
									anchors.left: parent.left
									anchors.right: parent.right
									spacing: 0

									Rectangle {
										Layout.fillWidth: true
										height: 32
										radius: root.playerSelectorOpen ? 8 : 16
										color: selectorMa.containsMouse ? Root.Color.surface1 : Root.Color.surface0
										Behavior on color { ColorAnimation { duration: 150 } }

										RowLayout {
											anchors.fill: parent
											anchors.leftMargin: 12
											anchors.rightMargin: 12
											spacing: 6

											Text {
												text: root.activePlayer ? root.activePlayer.identity : ""
												font.pointSize: 10
												color: Root.Color.subtext1
												elide: Text.ElideRight
												Layout.fillWidth: true
											}

											Text {
												text: root.playerSelectorOpen ? "󰅁" : "󰅂"
												font.pointSize: 10
												font.family: "Symbols Nerd Font"
												color: Root.Color.overlay1
												rotation: root.playerSelectorOpen ? 90 : -90
												Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
											}
										}

										MouseArea {
											id: selectorMa
											anchors.fill: parent
											hoverEnabled: true
											cursorShape: Qt.PointingHandCursor
											onClicked: root.playerSelectorOpen = !root.playerSelectorOpen
										}
									}

									// Dropdown list
									ColumnLayout {
										id: dropdownContent
										Layout.fillWidth: true
										spacing: 0
										clip: true

										property int fullHeight: root.playerSelectorOpen ? (1 + Mpris.players.values.length * 30) : 0
										Layout.preferredHeight: fullHeight

										Behavior on Layout.preferredHeight {
											NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
										}

										opacity: root.playerSelectorOpen ? 1.0 : 0.0
										Behavior on opacity {
											NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
										}

										Rectangle {
											Layout.fillWidth: true
											height: 1
											color: Root.Color.overlay0
											opacity: 0.2
										}

										Repeater {
											model: Mpris.players

											Rectangle {
												id: playerItem
												required property var modelData
												required property int index
												Layout.fillWidth: true
												height: 30
												color: index === root.activePlayerIndex
													? Root.Color.surface1
													: (playerItemMa.containsMouse ? Root.Color.surface0 : "transparent")
												Behavior on color { ColorAnimation { duration: 150 } }
												radius: 6

												RowLayout {
													anchors.fill: parent
													anchors.leftMargin: 12
													anchors.rightMargin: 12
													spacing: 8

													Rectangle {
														width: 6; height: 6; radius: 3
														color: playerItem.modelData.isPlaying ? Root.Color.lavender : Root.Color.overlay0
													}

													Text {
														text: playerItem.modelData.identity
														font.pointSize: 10
														font.bold: playerItem.index === root.activePlayerIndex
														color: playerItem.index === root.activePlayerIndex ? Root.Color.lavender : Root.Color.subtext1
														elide: Text.ElideRight
														Layout.fillWidth: true
													}

													Text {
														text: playerItem.modelData.trackTitle || ""
														font.pointSize: 9
														color: Root.Color.overlay0
														elide: Text.ElideRight
														Layout.maximumWidth: 180
													}
												}

												MouseArea {
													id: playerItemMa
													anchors.fill: parent
													hoverEnabled: true
													cursorShape: Qt.PointingHandCursor
													onClicked: root.selectPlayer(playerItem.index)
												}
											}
										}
									}
								}
							}

							RowLayout {
								Layout.fillWidth: true
								Layout.preferredHeight: 220
								spacing: 20
								// Left: cover art + song info
								ColumnLayout {
									Layout.preferredWidth: 180
									Layout.fillHeight: true
									spacing: 10

									Item { Layout.fillHeight: true }

									// Cover art
									Item {
								Layout.preferredWidth: 140
								Layout.preferredHeight: 140
										Layout.alignment: Qt.AlignHCenter

										Rectangle {
											id: coverBg
											anchors.fill: parent
											radius: 12
											color: Root.Color.surface0
											visible: coverArt.status !== Image.Ready

											Text {
												anchors.centerIn: parent
												text: "󰝚"
												font.pointSize: 32
												font.family: "Symbols Nerd Font"
											}
										}

										Image {
											id: coverArt
											anchors.fill: parent
											source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
											fillMode: Image.PreserveAspectCrop
											visible: false
										}

										Rectangle {
											id: coverMask
											anchors.fill: parent
											radius: 12
											visible: false
										}

										OpacityMask {
											anchors.fill: parent
											source: coverArt
											maskSource: coverMask
											visible: coverArt.status === Image.Ready
										}
									}

									// Song info
									ColumnLayout {
										Layout.fillWidth: true
										spacing: 2

										Text {
											text: root.activePlayer ? root.activePlayer.trackTitle : ""
											font.pointSize: 13
											font.bold: true
											color: Root.Color.lavender
											elide: Text.ElideRight
											Layout.fillWidth: true
											Layout.alignment: Qt.AlignHCenter
											horizontalAlignment: Text.AlignHCenter
										}
										Text {
											text: root.activePlayer ? root.activePlayer.trackArtist : ""
											font.pointSize: 11
											color: Root.Color.subtext1
											elide: Text.ElideRight
											Layout.fillWidth: true
											Layout.alignment: Qt.AlignHCenter
											horizontalAlignment: Text.AlignHCenter
										}
										Text {
											text: root.activePlayer ? root.activePlayer.trackAlbum : ""
											font.pointSize: 10
											color: Root.Color.overlay1
											elide: Text.ElideRight
											Layout.fillWidth: true
											Layout.alignment: Qt.AlignHCenter
											horizontalAlignment: Text.AlignHCenter
										}
									}

									Item { Layout.fillHeight: true }
								}

								// Right: progress bar + controls
								ColumnLayout {
									Layout.fillWidth: true
									Layout.fillHeight: true
									spacing: 12

									Item { Layout.fillHeight: true }

									// Progress bar
									ColumnLayout {
										Layout.fillWidth: true
										spacing: 4

										Item {
											Layout.fillWidth: true
											Layout.preferredHeight: 12

											Rectangle {
												id: progressTrack
												anchors.left: parent.left
												anchors.right: parent.right
												anchors.verticalCenter: parent.verticalCenter
												height: 4
												radius: 2
												color: Root.Color.surface0

												Rectangle {
													width: mediaProgressRatio * parent.width
													height: parent.height
													radius: 2
													color: Root.Color.lavender
												}
											}

											Rectangle {
												id: progressHandle
												width: 12; height: 12; radius: 6
												color: Root.Color.lavender
												y: (parent.height - height) / 2
												x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * mediaProgressRatio))
												visible: !!root.activePlayer && root.activePlayer.lengthSupported

												Behavior on x { enabled: !progressMa.pressed; NumberAnimation { duration: 200 } }
											}

											MouseArea {
												id: progressMa
												anchors.fill: parent
												enabled: !!root.activePlayer && root.activePlayer.canSeek && root.activePlayer.lengthSupported
												cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
												onClicked: function(mouse) {
													var ratio = mouse.x / width;
													ratio = Math.max(0, Math.min(1, ratio));
													root.activePlayer.position = ratio * root.activePlayer.length;
												}
											}
										}

										RowLayout {
											Layout.fillWidth: true
											Text {
												text: formatTime(mediaPositionSec)
												font.pointSize: 9
												color: Root.Color.overlay1
											}
											Item { Layout.fillWidth: true }
											Text {
												text: root.activePlayer && root.activePlayer.lengthSupported ? formatTime(mediaLengthSec) : "0:00"
												font.pointSize: 9
												color: Root.Color.overlay1
											}
										}
									}

									// Playback controls
									RowLayout {
										Layout.alignment: Qt.AlignHCenter
										spacing: 16

										// Previous
										Rectangle {
											width: 40; height: 40; radius: 20
											color: prevBtnMa.containsMouse ? Root.Color.surface1 : Root.Color.surface0
											opacity: root.activePlayer && root.activePlayer.canGoPrevious ? 1.0 : 0.3
											Behavior on color { ColorAnimation { duration: 150 } }
											Text {
											anchors.centerIn: parent; text: "󰒮"; font.pointSize: 14; font.family: "Symbols Nerd Font"
												color: Root.Color.text
											}
											MouseArea {
												id: prevBtnMa; anchors.fill: parent; hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												enabled: !!root.activePlayer && root.activePlayer.canGoPrevious
												onClicked: root.activePlayer.previous()
											}
										}

										// Play/Pause
										Rectangle {
											width: 48; height: 48; radius: 24
											color: playBtnMa.containsMouse ? Root.Color.lavender : Root.Color.surface0
											Behavior on color { ColorAnimation { duration: 150 } }
											Text {
												anchors.centerIn: parent
											text: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
											font.pointSize: 16; font.family: "Symbols Nerd Font"
												color: playBtnMa.containsMouse ? Root.Color.base : Root.Color.text
												Behavior on color { ColorAnimation { duration: 150 } }
											}
											MouseArea {
												id: playBtnMa; anchors.fill: parent; hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												enabled: !!root.activePlayer && root.activePlayer.canTogglePlaying
												onClicked: root.activePlayer.togglePlaying()
											}
										}

										// Next
										Rectangle {
											width: 40; height: 40; radius: 20
											color: nextBtnMa.containsMouse ? Root.Color.surface1 : Root.Color.surface0
											opacity: root.activePlayer && root.activePlayer.canGoNext ? 1.0 : 0.3
											Behavior on color { ColorAnimation { duration: 150 } }
											Text {
											anchors.centerIn: parent; text: "󰒭"; font.pointSize: 14; font.family: "Symbols Nerd Font"
												color: Root.Color.text
											}
											MouseArea {
												id: nextBtnMa; anchors.fill: parent; hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												enabled: !!root.activePlayer && root.activePlayer.canGoNext
												onClicked: root.activePlayer.next()
											}
										}
									}

										Item { Layout.fillHeight: true }
									}
								}

								// ===== Lyrics section =====
								Rectangle {
									Layout.fillWidth: true
									height: 1
									color: Root.Color.overlay0
									opacity: 0.2
									Layout.topMargin: 4
								}

								Item {
									Layout.fillWidth: true
									Layout.fillHeight: true
									Layout.minimumHeight: 200
									Layout.topMargin: 4
									clip: true

									ListView {
										id: lyricsView
										anchors.fill: parent
										interactive: false
										model: root.lyricsModel
										currentIndex: root.currentLineIndex
										cacheBuffer: 10000

										property bool userScrolling: false

										highlight: Item {}

										displaced: Transition {
											NumberAnimation { properties: "y"; duration: 500; easing.type: Easing.OutCubic }
										}

										onCurrentIndexChanged: {
											if (!userScrolling) scrollToCurrentLyric();
										}
										onModelChanged: Qt.callLater(scrollToCurrentLyric)

										function scrollToCurrentLyric() {
											if (currentIndex < 0 || count === 0) return;
											scrollAnim.stop();
											var oldY = contentY;
											positionViewAtIndex(currentIndex, ListView.Beginning);
											var targetY = contentY - height * 0.2;
											if (targetY < 0) targetY = 0;
											var maxY = contentHeight - height;
											if (maxY > 0 && targetY > maxY) targetY = maxY;
											if (maxY <= 0) targetY = 0;
											var distance = Math.abs(targetY - oldY);
											if (distance > height * 1.5) {
												// Large jump (e.g. seeking): snap near target, then short animation
												contentY = targetY + (oldY > targetY ? height * 0.3 : -height * 0.3);
												scrollAnim.duration = 350;
											} else {
												contentY = oldY;
												scrollAnim.duration = 600;
											}
											scrollAnim.to = targetY;
											scrollAnim.restart();
										}

										NumberAnimation {
											id: scrollAnim
											target: lyricsView
											property: "contentY"
											duration: 600
											easing.type: Easing.OutCubic
										}

										NumberAnimation {
											id: wheelAnim
											target: lyricsView
											property: "contentY"
											duration: 300
											easing.type: Easing.OutCubic
										}

										// Resume auto-scroll after user stops scrolling
										Timer {
											id: userScrollTimeout
											interval: 3000
											onTriggered: {
												lyricsView.userScrolling = false;
												lyricsView.scrollToCurrentLyric();
											}
										}

										MouseArea {
											anchors.fill: parent

											onWheel: function(wheel) {
												lyricsView.userScrolling = true;
												userScrollTimeout.restart();
												scrollAnim.stop();
												var delta = -wheel.angleDelta.y * 0.8;
												var newY = lyricsView.contentY + delta;
												if (newY < 0) newY = 0;
												var maxY = lyricsView.contentHeight - lyricsView.height;
												if (maxY > 0 && newY > maxY) newY = maxY;
												if (maxY <= 0) newY = 0;
												wheelAnim.to = newY;
												wheelAnim.restart();
											}

											onClicked: function(mouse) {
												var idx = lyricsView.indexAt(mouse.x, lyricsView.contentY + mouse.y);
												if (idx >= 0 && idx < root.lyricsModel.length && root.activePlayer) {
													var targetTime = root.lyricsModel[idx].time;
													root.activePlayer.position = targetTime;
													root.currentLineIndex = idx;
													lyricsView.userScrolling = false;
													userScrollTimeout.stop();
													lyricsView.scrollToCurrentLyric();
												}
											}
										}

										delegate: Item {
											width: ListView.view.width
											height: lyricText.implicitHeight + 20
											property bool isCurrent: ListView.isCurrentItem

											Text {
												id: lyricText
												anchors.left: parent.left
												anchors.leftMargin: 12
												anchors.right: parent.right
												anchors.rightMargin: 12
												anchors.verticalCenter: parent.verticalCenter
												text: modelData.text
												color: isCurrent ? Root.Color.lavender : Root.Color.overlay0
												font.pointSize: 22
												font.bold: isCurrent
												opacity: isCurrent ? 1.0 : 0.45
												scale: isCurrent ? 1.05 : 1.0
												transformOrigin: Item.Left
												wrapMode: Text.WordWrap
												lineHeight: 0.85
												lineHeightMode: Text.ProportionalHeight

												Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
												Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
												Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
											}
										}
									}

									// No lyrics fallback
									Text {
										anchors.centerIn: parent
										text: "暂无歌词"
										font.pointSize: 10
										color: Root.Color.overlay0
										visible: root.lyricsModel.length === 0
									}
								}
							}
						}

						// ===== Wallpaper tab =====
						Item {
							Layout.fillWidth: true
							Layout.fillHeight: true
							visible: root.currentTab === 2

							Timer {
								id: wallpaperLoadTimer
								interval: 50
								onTriggered: {
									wallpaperLogic.loadWallpapers();
									wallpaperView.forceActiveFocus();
								}
							}

							Connections {
								target: root
								function onCurrentTabChanged() {
									if (root.currentTab === 2) {
										wallpaperLoadTimer.restart();
									}
								}
							}

							PathView {
								id: wallpaperView
								anchors.fill: parent
								anchors.margins: 8
								pathItemCount: 3
								preferredHighlightBegin: 0.5
								preferredHighlightEnd: 0.5
								highlightRangeMode: PathView.StrictlyEnforceRange
								snapMode: PathView.SnapToItem
								dragMargin: 0
								model: wallpaperModel
								focus: true
								highlightMoveDuration: 300

								MouseArea {
									anchors.fill: parent
									onWheel: function(wheel) {
										if (wheel.angleDelta.y > 0) {
											wallpaperView.decrementCurrentIndex();
										} else {
											wallpaperView.incrementCurrentIndex();
										}
									}
								}

								path: Path {
									startX: -320
									startY: 145
									PathLine { x: 1520; y: 145 }
								}

								function decrementCurrentIndex() {
									if (wallpaperModel.count === 0) return;
									currentIndex = (currentIndex - 1 + wallpaperModel.count) % wallpaperModel.count;
								}

								function incrementCurrentIndex() {
									if (wallpaperModel.count === 0) return;
									currentIndex = (currentIndex + 1) % wallpaperModel.count;
								}

								delegate: Item {
									id: delegateItem
									property bool isCurrent: PathView.isCurrentItem
									width: 660
									height: 290

									Rectangle {
										id: wallpaperRect
										width: 640
										height: 274
										anchors.centerIn: parent
										radius: 16
										color: Root.Color.surface0
										border.width: isCurrent ? 4 : 2
										border.color: Root.Color.lavender
										scale: isCurrent ? 1.0 : 0.85
										opacity: isCurrent ? 1.0 : 0.6
										z: isCurrent ? 100 : 1

										Behavior on scale {
											NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
										}
										Behavior on opacity {
											NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
										}

										Image {
											anchors.fill: parent
											anchors.margins: 8
											source: "file://" + model.wallpaperPath
											fillMode: Image.PreserveAspectFit
											asynchronous: true
											cache: true
											sourceSize: Qt.size(320, 180)
											visible: status === Image.Ready
										}

										Rectangle {
											anchors.left: parent.left
											anchors.right: parent.right
											anchors.bottom: parent.bottom
											anchors.margins: 8
											height: 40
											color: Root.Color.mantle
											opacity: 0.9
											radius: 12

											Text {
												anchors.centerIn: parent
												text: model.wallpaperName
												color: Root.Color.text
												font.pointSize: 11
												elide: Text.ElideRight
												width: parent.width - 16
												horizontalAlignment: Text.AlignHCenter
											}
										}
									}

									MouseArea {
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: {
											wallpaperView.currentIndex = index;
											root.applyWallpaper(model.wallpaperPath, index);
											root.dashboardOpen = false;
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

	// ===== Helper function =====
	function formatTime(seconds) {
		if (!seconds || seconds < 0) return "0:00";
		var mins = Math.floor(seconds / 60);
		var secs = Math.floor(seconds % 60);
		return mins + ":" + (secs < 10 ? "0" : "") + secs;
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

	Component.onCompleted: {
		calendarLogic.generateCalendar();
		root.updateActivePlayer();
	}
}
