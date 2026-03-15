pragma Singleton
import QtQuick

QtObject {
	readonly property real baseRight: 8
	readonly property real gap: 8

	// Order of right-side modules, from rightmost to leftmost
	readonly property var order: ["powermenu", "notifications", "volume", "bluetooth", "network", "systemmonitor", "systemtray"]

	// Each module registers its width here
	property var widths: ({})
	property int _rev: 0

	function updateWidth(name, w) {
		let ww = Object.assign({}, widths);
		ww[name] = w;
		widths = ww;
		_rev++;
	}

	function rightMarginFor(name) {
		void _rev;
		let margin = baseRight;
		for (let i = 0; i < order.length; i++) {
			if (order[i] === name) break;
			margin += (widths[order[i]] || 0) + gap;
		}
		return margin;
	}
}
