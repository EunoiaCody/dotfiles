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

	exclusiveZone: centerContent.height
	margins.top: 0

	implicitWidth: centerContent.width + 4
	implicitHeight: centerContent.height + 16
	color: "transparent"

	mask: Region {}

	WlrLayershell.layer: WlrLayer.Top

	Rectangle {
		id: centerContent
		anchors.centerIn: parent
		width: timeRow.width + 32
		height: timeRow.height + 16
		radius: height / 2
		color: Root.Color.base

		RowLayout {
			id: timeRow
			anchors.centerIn: parent
			spacing: 8

			Text {
				id: dateText
				color: Root.Color.lavender
				font.pointSize: 12
				font.bold: true
			}

			Text {
				id: timeText
				color: Root.Color.lavender
				font.pointSize: 12
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
}
