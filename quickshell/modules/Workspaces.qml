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
		left: true
	}

	exclusiveZone: -1
	margins {
		top: 0
		left: 8
	}

	implicitWidth: pill.width + 4
	implicitHeight: pill.height + 16
	color: "transparent"

	WlrLayershell.layer: WlrLayer.Overlay

	// Workspace data model
	ListModel {
		id: workspaceModel
	}

	property int focusedId: -1

	function parseWorkspaces(data) {
		try {
			const list = JSON.parse(data);
			workspaceModel.clear();
			list.sort((a, b) => a.idx - b.idx);
			for (const ws of list) {
				workspaceModel.append({
					wsId: ws.id,
					wsIdx: ws.idx,
					wsActive: ws.is_active,
					wsFocused: ws.is_focused
				});
				if (ws.is_focused) root.focusedId = ws.id;
			}
		} catch (e) {}
	}

	// Fetch workspaces on startup
	Process {
		id: fetchWorkspaces
		command: ["bash", "-c", "niri msg -j workspaces"]

		property string buf: ""

		stdout: SplitParser {
			onRead: data => {
				fetchWorkspaces.buf += data;
			}
		}

		onExited: (code, status) => {
			if (fetchWorkspaces.buf.length > 0) {
				root.parseWorkspaces(fetchWorkspaces.buf);
				fetchWorkspaces.buf = "";
			}
		}

		Component.onCompleted: running = true
	}

	// Listen to niri event stream for workspace changes
	Process {
		id: eventStream
		command: ["bash", "-c", "niri msg -j event-stream"]

		stdout: SplitParser {
			onRead: data => {
				try {
					const event = JSON.parse(data);

					if (event.WorkspacesChanged) {
						const list = event.WorkspacesChanged.workspaces;
						workspaceModel.clear();
						list.sort((a, b) => a.idx - b.idx);
						for (const ws of list) {
							workspaceModel.append({
								wsId: ws.id,
								wsIdx: ws.idx,
								wsActive: ws.is_active,
								wsFocused: ws.is_focused
							});
							if (ws.is_focused) root.focusedId = ws.id;
						}
					}

					if (event.WorkspaceActivated) {
						root.focusedId = event.WorkspaceActivated.id;
					}
				} catch (e) {}
			}
		}

		Component.onCompleted: running = true
	}

	Rectangle {
		id: pill
		anchors.centerIn: parent
		width: wsRow.width + 8
		height: wsRow.height + 8
		radius: height / 2
		color: Root.Color.base

		// Sliding highlight
		Rectangle {
			id: highlight
			visible: highlightTarget !== null
			y: highlightTarget ? highlightTarget.y + wsRow.y : 0
			x: highlightTarget ? highlightTarget.x + wsRow.x : 0
			width: highlightTarget ? highlightTarget.width : 0
			height: highlightTarget ? highlightTarget.height : 0
			radius: height / 2
			color: Root.Color.lavender

			property Item highlightTarget: null

			Behavior on x {
				SmoothedAnimation {
					velocity: -1
					duration: 300
					easing.type: Easing.OutCubic
				}
			}

			Behavior on width {
				SmoothedAnimation {
					velocity: -1
					duration: 200
					easing.type: Easing.OutCubic
				}
			}
		}

		RowLayout {
			id: wsRow
			anchors.centerIn: parent
			spacing: 4

			Repeater {
				id: wsRepeater
				model: workspaceModel

				Rectangle {
					id: wsDelegate
					required property int wsId
					required property int wsIdx
					required property int index
					property bool isFocused: wsId === root.focusedId

					width: Math.max(wsLabel.width + 16, height)
					height: wsLabel.height + 8
					radius: height / 2
					color: "transparent"

					onIsFocusedChanged: {
						if (isFocused) {
							highlight.highlightTarget = wsDelegate;
						}
					}

					Component.onCompleted: {
						if (isFocused) {
							highlight.highlightTarget = wsDelegate;
						}
					}

					Text {
						id: wsLabel
						anchors.centerIn: parent
						text: wsIdx
						font.pointSize: 11
						font.bold: true
						color: isFocused ? Root.Color.base : Root.Color.lavender

						Behavior on color {
							ColorAnimation { duration: 200 }
						}
					}

					MouseArea {
						anchors.fill: parent
						onClicked: {
							focusProcess.command = ["niri", "msg", "action", "focus-workspace", String(wsIdx)];
							focusProcess.running = true;
						}
					}
				}
			}
		}
	}

	Process {
		id: focusProcess
		running: false
	}
}
