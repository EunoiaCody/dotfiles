pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    signal brightnessChanged()

    property var ddcMonitors: []
    property var pendingDdcMonitors: []
    property real fallbackBrightnessValue: 0.5
    property var monitors: []
    // Tool availability - detected by a one-shot `which` Process on startup.
    // Defaults to "false" so the first render cycle doesn't call a missing
    // binary. The check Process then sets these to true if found.
    property bool hasDdcutil: false
    property bool hasBrightnessctl: false

    // 自动亮度 —— 由 wluma systemd 服务控制
    property bool autoBrightness: false
    readonly property int brightnessMax: root.activeMonitor ? root.activeMonitor.rawMaxBrightness : 100
    // 全局代理属性 — 对比度 / RGB 增益
    readonly property real contrastValue: root.activeMonitor ? root.activeMonitor.contrast : 0.5
    readonly property real redGainValue: root.activeMonitor ? root.activeMonitor.redGain : 0.5
    readonly property real greenGainValue: root.activeMonitor ? root.activeMonitor.greenGain : 0.5
    readonly property real blueGainValue: root.activeMonitor ? root.activeMonitor.blueGain : 0.5

    Process {
        id: toolCheck
        command: ["sh", "-c", "command -v ddcutil >/dev/null 2>&1 && echo ddcutil; command -v brightnessctl >/dev/null 2>&1 && echo brightnessctl"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const out = (this.text || "").trim();
                const found = new Set(out.split(/\s+/).filter(s => s.length > 0));
                root.hasDdcutil = found.has("ddcutil");
                root.hasBrightnessctl = found.has("brightnessctl");
                // 检测到 ddcutil 后，立即扫描 DDC 显示器
                if (root.hasDdcutil)
                    root.rescanDdcMonitors();
            }
        }
    }

    Component.onCompleted: {
        toolCheck.running = true;
        root.rebuildMonitors();
        root.refreshFocusedOutput();
    }
    property string focusedScreenName: ""
    readonly property var activeScreen: root.getScreenByName(root.focusedScreenName) || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    readonly property var activeMonitor: root.getMonitorByName(root.focusedScreenName) || (root.monitors.length > 0 ? root.monitors[0] : null)
    readonly property real brightnessValue: root.activeMonitor ? root.activeMonitor.brightness : root.fallbackBrightnessValue

    Connections {
        target: Quickshell

        function onScreensChanged() {
            root.rebuildMonitors();
        }
    }

    function rebuildMonitors() {
        for (let i = 0; i < root.monitors.length; i += 1)
            root.monitors[i].destroy();

        const next = [];
        for (let i = 0; i < Quickshell.screens.length; i += 1)
            next.push(monitorComponent.createObject(root, {
                screen: Quickshell.screens[i]
            }));

        root.monitors = next;
        root.rescanDdcMonitors();
    }

    function refreshFocusedOutput() {
        if (!focusedOutputProcess.running)
            focusedOutputProcess.running = true;
    }

    function parseFocusedOutput(text) {
        const firstLine = String(text || "").split("\n")[0] || "";
        const match = firstLine.match(/\(([^)]+)\)/);
        if (!match)
            return;

        const screenName = root.normalizeConnectorName(match[1]);
        if (screenName.length > 0)
            root.focusedScreenName = screenName;
    }

    function clampBrightness(value, allowZero) {
        const numericValue = Number(value);
        const safeValue = isNaN(numericValue) ? root.fallbackBrightnessValue : numericValue;
        return Math.max(allowZero ? 0.0 : 0.01, Math.min(1.0, safeValue));
    }

    function normalizeConnectorName(name) {
        const raw = String(name || "").trim();
        if (raw.length === 0)
            return "";
        return raw.replace(/^card[0-9]+-/, "");
    }

    function getMonitorForScreen(screen) {
        if (!screen)
            return root.activeMonitor;
        return root.getMonitorByName(screen.name);
    }

    function getScreenByName(name) {
        const normalizedName = root.normalizeConnectorName(name);
        if (normalizedName.length === 0)
            return null;
        return Quickshell.screens.find(screen => root.normalizeConnectorName(screen.name) === normalizedName) || null;
    }

    function getMonitorByName(name) {
        const normalizedName = root.normalizeConnectorName(name);
        if (normalizedName.length === 0)
            return null;
        return root.monitors.find(m => root.normalizeConnectorName(m.screenName) === normalizedName) || null;
    }

    function setBrightness(val, allowZero) {
        // 手动调节亮度时，关闭自动亮度（不触发 refresh，避免覆盖用户设置）
        if (root.autoBrightness) {
            root.autoBrightness = false;
            wlumaControlProc.exec(["systemctl", "--user", "stop", "wluma.service"]);
        }
        root.setBrightnessForScreen(null, val, allowZero);
    }

    function setBrightnessForScreen(screen, val, allowZero) {
        if (root.autoBrightness) {
            root.autoBrightness = false;
            wlumaControlProc.exec(["systemctl", "--user", "stop", "wluma.service"]);
        }
        const monitor = root.getMonitorForScreen(screen);
        if (monitor) {
            monitor.setBrightness(val, allowZero);
            return;
        }

        if (!root.hasBrightnessctl)
            return;

        const safeVal = root.clampBrightness(val, allowZero);
        const pct = Math.round(safeVal * 100);
        fallbackBrightnessValue = safeVal;
        fallbackSetProc.exec(["brightnessctl", "--class", "backlight", "s", pct + "%", "--quiet"]);
        root.brightnessChanged();
    }

    // 对比度 & RGB 增益 — 直接委托给活动显示器
    function setContrast(val) { if (root.activeMonitor) root.activeMonitor.setContrast(val); }
    function setRedGain(val)  { if (root.activeMonitor) root.activeMonitor.setRedGain(val); }
    function setGreenGain(val) { if (root.activeMonitor) root.activeMonitor.setGreenGain(val); }
    function setBlueGain(val)  { if (root.activeMonitor) root.activeMonitor.setBlueGain(val); }

    function rescanDdcMonitors() {
        if (ddcDetectProcess.running)
            ddcDetectProcess.running = false;
        pendingDdcMonitors = [];
        if (!hasDdcutil)
            return;
        ddcDetectProcess.running = true;
    }

    function parseDdcBlock(data) {
        const block = String(data || "").trim();
        if (!block.startsWith("Display "))
            return;

        const lines = block.split("\n").map(line => line.trim());
        const busLine = lines.find(line => line.startsWith("I2C bus:"));
        const connectorLine = lines.find(line => line.startsWith("DRM connector:"));
        if (!busLine || !connectorLine)
            return;

        const busMatch = busLine.match(/\/dev\/i2c-([0-9]+)/);
        const connector = root.normalizeConnectorName(connectorLine.split(":").slice(1).join(":"));
        if (!busMatch || connector.length === 0)
            return;

        const next = pendingDdcMonitors.slice();
        next.push({
            name: connector,
            busNum: busMatch[1]
        });
        pendingDdcMonitors = next;
    }

    function initializeMonitor(index) {
        if (index >= root.monitors.length)
            return;
        root.monitors[index].initialize();
    }

    Process {
        id: ddcDetectProcess

        command: ["ddcutil", "detect", "--brief"]

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text || "";
                // 单显示器或末尾没空行时分隔符
                const blocks = text.split("\n\n").filter(b => b.trim().length > 0);
                for (let i = 0; i < blocks.length; i += 1)
                    root.parseDdcBlock(blocks[i]);

                root.ddcMonitors = root.pendingDdcMonitors;
                root.pendingDdcMonitors = [];
                root.initializeMonitor(0);
            }
        }
    }

    Process {
        id: fallbackSetProc
    }

    Process {
        id: focusedOutputProcess

        command: ["niri", "msg", "focused-output"]

        stdout: StdioCollector {
            onStreamFinished: root.parseFocusedOutput(this.text)
        }
    }

    // 自动亮度管理 — 启动时检查 wluma 状态，之后每 5 秒轮询
    Timer {
        id: wlumaStatusTimer

        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wlumaStatusProc.running = true
    }

    Process {
        id: wlumaStatusProc

        command: ["systemctl", "--user", "is-active", "wluma.service"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const status = (this.text || "").trim();
                const isActive = (status === "active");
                if (root.autoBrightness !== isActive) {
                    root.autoBrightness = isActive;
                }
            }
        }
    }

    Process {
        id: wlumaControlProc
    }

    function setAutoBrightness(enabled) {
        if (enabled === root.autoBrightness)
            return;

        root.autoBrightness = enabled;
        const svc = "wluma.service";
        if (enabled) {
            wlumaControlProc.exec(["systemctl", "--user", "start", svc]);
        } else {
            wlumaControlProc.exec(["systemctl", "--user", "stop", svc]);
            // 停止 wluma 后，立即读取当前亮度值作为手动值起点
            if (root.activeMonitor)
                root.activeMonitor.refresh();
        }
    }

    Timer {
        id: pollTimer

        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            // 自动模式下也更频繁地轮询 DDC 亮度（wluma 在后台改值）
            if (root.activeMonitor && (root.autoBrightness || !root.activeMonitor.isDdc))
                root.activeMonitor.refresh();
        }
    }

    Timer {
        // 从 1s 降至 5s：focused-output 只在焦点屏幕变化时才需要更新，
        // 原 1s 轮询每秒派生一次 `niri msg` 子进程，属于资源浪费
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refreshFocusedOutput()
    }

    Component {
        id: monitorComponent

        QtObject {
            id: monitor

            required property var screen
            readonly property string screenName: screen ? screen.name : ""
            property bool isDdc: false
            property string busNum: ""
            property int rawMaxBrightness: 100
            property real brightness: root.fallbackBrightnessValue
            property real contrast: 0.5
            property real redGain: 0.49
            property real greenGain: 0.44
            property real blueGain: 0.44
            property bool ready: false
            property bool pendingSync: false
            property bool reading: false

            onBrightnessChanged: {
                if (reading)
                    return;

                root.fallbackBrightnessValue = brightness;
                root.brightnessChanged();

                if (!ready) {
                    pendingSync = true;
                    return;
                }

                scheduleSync();
            }

            function initialize() {
                ready = false;
                pendingSync = false;

                const connectorName = root.normalizeConnectorName(screenName);
                const match = root.ddcMonitors.find(m => root.normalizeConnectorName(m.name) === connectorName);
                isDdc = !!match;
                busNum = match ? match.busNum : "";
                refresh();
            }

            function refresh() {
                reading = true;
                if (isDdc) {
                    if (!root.hasDdcutil) {
                        reading = false;
                        ready = true;
                        return;
                    }
                    readProcess.command = ["ddcutil", "-b", busNum, "getvcp", "10", "12", "16", "18", "1A", "--brief"];
                } else {
                    if (!root.hasBrightnessctl) {
                        reading = false;
                        ready = true;
                        return;
                    }
                    readProcess.command = ["brightnessctl", "--class", "backlight", "-m"];
                }
                readProcess.running = true;
            }

            function parseReadOutput(text) {
                const data = String(text || "").trim();
                if (data.length === 0)
                    return;

                if (isDdc) {
                    const lines = data.split("\n");
                    for (let i = 0; i < lines.length; i += 1) {
                        const parts = lines[i].trim().split(/\s+/);
                        if (parts.length < 5)
                            continue;
                        const vcpCode = parseInt(parts[1], 16);
                        const current = parseInt(parts[3]);
                        const max = parseInt(parts[4]);
                        if (isNaN(current) || isNaN(max) || max <= 0)
                            continue;
                        const val = Math.max(0, Math.min(1, current / max));
                        switch (vcpCode) {
                        case 0x10: rawMaxBrightness = max; brightness = val; break;
                        case 0x12: contrast = val; break;
                        case 0x16: redGain = val; break;
                        case 0x18: greenGain = val; break;
                        case 0x1A: blueGain = val; break;
                        }
                    }
                    return;
                }

                const parts = data.split(",");
                if (parts.length < 5)
                    return;

                const percent = parseInt(parts[3].replace("%", ""));
                const max = parseInt(parts[4]);
                if (!isNaN(max) && max > 0)
                    rawMaxBrightness = max;
                if (!isNaN(percent))
                    brightness = Math.max(0, Math.min(1, percent / 100.0));
            }

            function setBrightness(value, allowZero) {
                brightness = root.clampBrightness(value, allowZero);
            }

            function setContrast(value) {
                contrast = root.clampBrightness(value, false);
                if (!isDdc || !ready) return;
                syncVcp("12", contrast);
            }

            function setRedGain(value) {
                redGain = root.clampBrightness(value, false);
                if (!isDdc || !ready) return;
                syncVcp("16", redGain);
            }

            function setGreenGain(value) {
                greenGain = root.clampBrightness(value, false);
                if (!isDdc || !ready) return;
                syncVcp("18", greenGain);
            }

            function setBlueGain(value) {
                blueGain = root.clampBrightness(value, false);
                if (!isDdc || !ready) return;
                syncVcp("1A", blueGain);
            }

            function syncVcp(code, val) {
                if (!root.hasDdcutil) return;
                const raw = Math.max(1, Math.floor(val * 100));
                vcpSetProcess.exec(["ddcutil", "-b", busNum, "setvcp", code, String(raw)]);
            }

            function scheduleSync() {
                if (isDdc)
                    ddcSetTimer.restart();
                else
                    syncBrightness();
            }

            function syncBrightness() {
                const safeBrightness = Math.max(0, Math.min(1, brightness));
                if (isDdc) {
                    if (!root.hasDdcutil)
                        return;
                    const rawValue = Math.max(1, Math.floor(safeBrightness * rawMaxBrightness));
                    setProcess.exec(["ddcutil", "-b", busNum, "setvcp", "10", String(rawValue)]);
                    return;
                }

                if (!root.hasBrightnessctl)
                    return;

                const percent = Math.round(safeBrightness * 100);
                setProcess.exec(["brightnessctl", "--class", "backlight", "s", percent + "%", "--quiet"]);
            }

            readonly property Process readProcess: Process {
                stdout: StdioCollector {
                    onStreamFinished: monitor.parseReadOutput(this.text)
                }

                onExited: {
                    monitor.reading = false;
                    monitor.ready = true;

                    if (monitor.pendingSync) {
                        monitor.pendingSync = false;
                        monitor.scheduleSync();
                    }

                    root.initializeMonitor(root.monitors.indexOf(monitor) + 1);
                }
            }

            readonly property Process setProcess: Process {}

            readonly property Process vcpSetProcess: Process {}

            readonly property Timer ddcSetTimer: Timer {
                id: ddcSetTimer

                interval: 300
                running: false
                repeat: false
                onTriggered: monitor.syncBrightness()
            }
        }
    }
}
