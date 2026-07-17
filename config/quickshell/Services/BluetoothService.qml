pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// BluetoothService — central facade over Quickshell's native Bluetooth
// module (which talks to BlueZ over D-Bus).
//
// Backwards-compatible API surface used by the existing Quick Toggles
// panel (Modules/Sidebars/Right/SettingsContent.qml) and QuickToggleConfig:
// - property bool available
// - property bool enabled
// - property bool connected
// - property string connectedName
// - function toggle()
//
// New API used by the Bluetooth panel/button:
// - property bool discovering
// - property var devices (raw adapter.devices ObjectModel)
// - property var pairedDevices (subset of paired/trusted devices)
// - property var unpairedDevices (subset of discovered-but-unpaired)
// - function startScan()
// - function stopScan()
// - function connectDevice(device)
// - function disconnectDevice(device)
// - function pairDevice(device)
// - function forgetDevice(device)
//
// Device objects are the native BluetoothDevice instances — they expose
// address, name, connected, paired, trusted, pairing, battery (0.0-1.0),
// batteryAvailable, signalStrength, state, icon.
//
// The legacy "toggle()" kept its semantics: toggling adapter power.
// startScan()/stopScan() deliberately just flips the adapter's
// `discovering` flag — BlueZ will report any new device as part of
// `adapter.devices` automatically.
Singleton {
 id: root

 readonly property var adapter: Bluetooth.defaultAdapter ?? null

 readonly property bool available: adapter !== null
 readonly property bool enabled: (adapter && adapter.enabled) ?? false
 readonly property bool discovering: (adapter && adapter.discovering) ?? false

 // Friendly: are *any* devices currently connected?
 readonly property bool connected: {
 if (!adapter || !adapter.devices)
 return false;
 for (const d of adapter.devices.values)
 if (d && d.connected)
 return true;
 return false;
 }

 // Name of the first connected device (matches the legacy
 // `connectedName` contract — picks head of the list).
 readonly property string connectedName: {
 if (!adapter || !adapter.devices)
 return "";
 for (const d of adapter.devices.values)
 if (d && d.connected && d.name && d.name.length >0)
 return d.name;
 return "";
 }

 // Full device list — exposed for the panel; the panel sorts and
 // filters these into paired / discovered buckets as needed.
 readonly property var devices: {
 if (!adapter || !adapter.devices)
 return [];
 return Array.from(adapter.devices.values).filter(d => d !== null);
 }

 // Convenience buckets used by BluetoothContent to render two
 // sections without re-filtering on every binding.
 readonly property var pairedDevices: {
 const list = [];
 for (const d of root.devices) {
 if (d.paired || d.trusted)
 list.push(d);
 }
 return list;
 }
 readonly property var unpairedDevices: {
 const list = [];
 for (const d of root.devices) {
 if (!(d.paired || d.trusted))
 list.push(d);
 }
 return list;
 }

 // -------- legacy API --------

 function toggle() {
 if (!root.available)
 return;
 if (root.adapter)
 root.adapter.enabled = !root.adapter.enabled;
 }

 // Backwards-compat alias for callers that already use `refresh()`
 // (none currently do, but kept for forward compat).
 function refresh() {
 // Native adapter updates itself through D-Bus signals; nothing
 // to do here. The function exists only so existing call sites
 // (if any are added later) don't break.
 }

 // -------- new API --------

 function startScan() {
 if (!root.available || !root.adapter)
 return;
 root.adapter.discovering = true;
 }

 function stopScan() {
 if (!root.available || !root.adapter)
 return;
 root.adapter.discovering = false;
 }

 function pairDevice(device) {
 if (!device)
 return;
 // Trusting first ensures the device auto-reconnects in future
 // sessions, which is the behaviour users expect from a typical
 // Bluetooth stack (macOS, Windows, GNOME, …).
 if (device.trusted !== undefined)
 device.trusted = true;
 if (typeof device.pair === "function")
 device.pair();
 else if (typeof device.connect === "function")
 device.connect();
 }

 function connectDevice(device) {
 if (!device)
 return;
 if (device.trusted !== undefined)
 device.trusted = true;
 if (typeof device.connect === "function")
 device.connect();
 }

 function disconnectDevice(device) {
 if (!device)
 return;
 if (typeof device.disconnect === "function")
 device.disconnect();
 }

 function forgetDevice(device) {
 if (!device)
 return;
 if (typeof device.forget === "function")
 device.forget();
 }
}
