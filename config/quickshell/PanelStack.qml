pragma Singleton
import QtQuick

QtObject {
	readonly property real baseTop: 56
	readonly property real gap: 8

	// Ordered list of open panel names (earliest opened first)
	property var openOrder: []

	// Panel heights (updated by each panel)
	property var heights: ({})

	// revision counter to force recalc on any change
	property int _rev: 0

	function panelOpened(name, height) {
		let order = openOrder.slice();
		let idx = order.indexOf(name);
		if (idx === -1) order.push(name);
		openOrder = order;
		let h = Object.assign({}, heights);
		h[name] = height;
		heights = h;
		_rev++;
	}

	function panelClosed(name) {
		let order = openOrder.slice();
		let idx = order.indexOf(name);
		if (idx !== -1) order.splice(idx, 1);
		openOrder = order;
		_rev++;
	}

	function updateHeight(name, height) {
		let h = Object.assign({}, heights);
		h[name] = height;
		heights = h;
		_rev++;
	}

	function topFor(name) {
		void _rev; // depend on revision
		let top = baseTop;
		let order = openOrder;
		for (let i = 0; i < order.length; i++) {
			if (order[i] === name) break;
			let h = heights[order[i]] || 0;
			top += h + gap;
		}
		return top;
	}
}
