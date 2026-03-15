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
        right: Root.BarLayout.rightMarginFor("systemmonitor")
    }

    implicitWidth: monitorPill.width + 4
    implicitHeight: monitorPill.height + 12
    color: "transparent"

    onImplicitWidthChanged: Root.BarLayout.updateWidth("systemmonitor", implicitWidth)
    Component.onCompleted: Root.BarLayout.updateWidth("systemmonitor", implicitWidth)

    WlrLayershell.layer: WlrLayer.Top

    property bool panelOpen: false
    property bool _panelClosing: false

    // Metrics state
    property real cpuUsage: 0
    property real cpuTemp: -1
    property real gpuUsage: -1
    property real gpuTemp: -1
    property real memPercent: 0
    property real swapPercent: 0
    property real netDownKBps: 0
    property real netUpKBps: 0

    // Internal counters
    property real _prevRx: 0
    property real _prevTx: 0
    property bool _netPrimed: false

    // Config
    property string netInterface: "wlan0"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpuStatProc.running = true;
            memInfoProc.running = true;
            netStatProc.running = true;
            gpuStatProc.running = true;
            cpuTempProc.running = true;
        }
    }

    // CPU usage from /proc/stat via two-sample delta (no JS state)
    Process {
        id: cpuStatProc
        command: ["bash", "-lc", "LC_ALL=C read _ u n s i io irq sirq st rest < /proc/stat; sleep 0.25; LC_ALL=C read _ u2 n2 s2 i2 io2 irq2 sirq2 st2 rest2 < /proc/stat; total=$((u2+n2+s2+i2+io2+irq2+sirq2+st2 - (u+n+s+i+io+irq+sirq+st))); idle=$((i2+io2 - (i+io))); if [ $total -gt 0 ]; then python - <<'PY'\ntot=$total\nidle=$idle\nused=tot-idle\nif tot > 0:\n    pct = max(0.0, min(100.0, (used / tot) * 100.0))\n    print(f\"{pct:.2f}\")\nelse:\n    print(\"0\")\nPY\nelse echo 0; fi\n"]
        property string buf: ""

        stdout: SplitParser {
            onRead: data => cpuStatProc.buf += data
        }

        onExited: {
            const val = cpuStatProc.buf.trim();
            cpuStatProc.buf = "";
            const pct = parseFloat(val);
            if (!isNaN(pct)) root.cpuUsage = Math.max(0, Math.min(100, pct));
        }
    }

    // Memory + swap usage computed in-shell (handles MemAvailable fallback)
    Process {
        id: memInfoProc
        command: ["bash", "-c", "LC_ALL=C awk 'BEGIN{mt=ma=mf=buf=cach=sr=sh=st=sf=0} /MemTotal:/ {mt=$2} /MemAvailable:/ {ma=$2} /MemFree:/ {mf=$2} /Buffers:/ {buf=$2} /Cached:/ {cach=$2} /SReclaimable:/ {sr=$2} /Shmem:/ {sh=$2} /SwapTotal:/ {st=$2} /SwapFree:/ {sf=$2} END {if(mt>0){if(ma==0) ma=mf+buf+cach+sr-sh; if(ma<0) ma=0; used=mt-ma; mpct=used*100/mt;} else mpct=0; if(st>0){su=st-sf; spct=su*100/st;} else spct=0; printf \"%.2f %.2f\\n\", mpct, spct}' /proc/meminfo"]
        property string buf: ""

        stdout: SplitParser {
            onRead: data => memInfoProc.buf += data
        }

        onExited: {
            const parts = memInfoProc.buf.trim().split(/\s+/);
            memInfoProc.buf = "";
            if (parts.length >= 2) {
                const mp = parseFloat(parts[0]);
                const sp = parseFloat(parts[1]);
                if (!isNaN(mp)) root.memPercent = Math.max(0, Math.min(100, mp));
                if (!isNaN(sp)) root.swapPercent = Math.max(0, Math.min(100, sp));
            }
        }
    }

    // Network throughput (KB/s) for given interface
    Process {
        id: netStatProc
        property string buf: ""
        command: ["bash", "-c", "rx=$(cat /sys/class/net/" + root.netInterface + "/statistics/rx_bytes 2>/dev/null); tx=$(cat /sys/class/net/" + root.netInterface + "/statistics/tx_bytes 2>/dev/null); echo \"$rx $tx\""]

        stdout: SplitParser {
            onRead: data => netStatProc.buf += data
        }

        onExited: {
            const parts = netStatProc.buf.trim().split(/\s+/);
            netStatProc.buf = "";
            if (parts.length < 2) return;
            const rx = parseInt(parts[0]) || 0;
            const tx = parseInt(parts[1]) || 0;
            if (root._netPrimed) {
                const drx = rx - root._prevRx;
                const dtx = tx - root._prevTx;
                root.netDownKBps = Math.max(0, drx / 1024);
                root.netUpKBps = Math.max(0, dtx / 1024);
            }
            root._prevRx = rx;
            root._prevTx = tx;
            root._netPrimed = true;
        }
    }

    // AMD GPU usage + temp
    Process {
        id: gpuStatProc
        property string buf: ""
        command: ["bash", "-c", "busyfile=; for f in /sys/class/drm/card*/device/gpu_busy_percent; do [ -r \"$f\" ] && { busyfile=$f; break; }; done; tempFile=; for f in /sys/class/drm/card*/device/hwmon/*/temp1_input; do [ -r \"$f\" ] && { tempFile=$f; break; }; done; busy=; temp=; [ -n \"$busyfile\" ] && busy=$(cat \"$busyfile\" 2>/dev/null); [ -n \"$tempFile\" ] && temp=$(cat \"$tempFile\" 2>/dev/null); echo \"$busy $temp\"" ]

        stdout: SplitParser {
            onRead: data => gpuStatProc.buf += data
        }

        onExited: {
            const parts = gpuStatProc.buf.trim().split(/\s+/);
            gpuStatProc.buf = "";
            if (parts[0]) {
                const g = parseInt(parts[0]);
                if (!isNaN(g)) root.gpuUsage = Math.max(0, Math.min(100, g));
            }
            if (parts.length > 1 && parts[1]) {
                const t = parseInt(parts[1]);
                if (!isNaN(t)) root.gpuTemp = t / 1000.0;
            }
        }
    }

    // CPU temperature via sensors
    Process {
        id: cpuTempProc
        property string buf: ""
        command: ["bash", "-c", "sensors 2>/dev/null | awk '/Package id 0:|Tctl:|Tdie:|CPU:/ {if(match($0, /([0-9]+\\.?[0-9]*)°C/, a)) {print a[1]; exit}} /temp1:/ {if(match($0, /([0-9]+\\.?[0-9]*)°C/, a)) {print a[1]; exit}}'"]

        stdout: SplitParser {
            onRead: data => cpuTempProc.buf += data
        }

        onExited: {
            const val = cpuTempProc.buf.trim();
            cpuTempProc.buf = "";
            const t = parseFloat(val);
            if (!isNaN(t)) root.cpuTemp = t;
        }
    }

    Timer {
        id: closeDelayTimer
        interval: 380
        onTriggered: {
            Root.PanelStack.panelClosed("systemmonitor");
            root._panelClosing = false;
        }
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            Root.PanelStack.panelOpened("systemmonitor", 0);
        } else {
            root._panelClosing = true;
            closeDelayTimer.start();
        }
    }

    // Pill button
    Rectangle {
        id: monitorPill
        anchors.centerIn: parent
        width: pillRow.width + 20
        height: 42
        radius: height / 2
        color: pillMouse.containsMouse ? Root.Color.lavender : Root.Color.base

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "📊"
                font.pointSize: 15
                color: pillMouse.containsMouse ? Root.Color.base : Root.Color.lavender

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Text {
                text: "仪表盘"
                font.pointSize: 11
                font.bold: true
                color: pillMouse.containsMouse ? Root.Color.base : Root.Color.lavender
                elide: Text.ElideRight

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }

        MouseArea {
            id: pillMouse
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

            property real panelTop: Root.PanelStack.topFor("systemmonitor")
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
            implicitHeight: contentCol.implicitHeight + 32
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "system-monitor"

            onImplicitHeightChanged: Root.PanelStack.updateHeight("systemmonitor", implicitHeight)
            Component.onCompleted: Root.PanelStack.updateHeight("systemmonitor", implicitHeight)

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
                        id: contentCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 16
                        }
                        spacing: 14

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "系统状态"
                                font.pointSize: 14
                                font.bold: true
                                color: Root.Color.lavender
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                radius: width / 2
                                color: closeArea.containsMouse ? Root.Color.red : Root.Color.surface0

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.panelOpen ? "×" : ""
                                    font.pointSize: 12
                                    color: closeArea.containsMouse ? Root.Color.base : Root.Color.subtext1

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }
                                }

                                MouseArea {
                                    id: closeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.panelOpen = false
                                }
                            }
                        }

                        // Gauges
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Loader {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                sourceComponent: gaugeCardComponent
                                onLoaded: {
                                    if (item) {
                                        item.title = "CPU";
                                        item.value = root.cpuUsage;
                                        item.temperature = root.cpuTemp;
                                        item.accent = Root.Color.lavender;
                                    }
                                }
                            }

                            Loader {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                sourceComponent: gaugeCardComponent
                                onLoaded: {
                                    if (item) {
                                        item.title = "GPU";
                                        item.value = root.gpuUsage >= 0 ? root.gpuUsage : -1;
                                        item.temperature = root.gpuTemp;
                                        item.accent = Root.Color.red;
                                    }
                                }
                            }
                        }

                        // Memory
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "内存"
                                font.pointSize: 12
                                font.bold: true
                                color: Root.Color.text
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 18
                                radius: height / 2
                                color: Root.Color.surface0

                                Rectangle {
                                    width: parent.width * (Math.max(0, Math.min(100, root.memPercent)) / 100)
                                    height: parent.height
                                    radius: height / 2
                                    color: Root.Color.lavender

                                    Behavior on width {
                                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(root.memPercent) + "%"
                                    font.pointSize: 10
                                    font.bold: true
                                    color: Root.Color.base
                                }
                            }

                            Text {
                                text: "交换"
                                font.pointSize: 12
                                font.bold: true
                                color: Root.Color.text
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 18
                                radius: height / 2
                                color: Root.Color.surface0

                                Rectangle {
                                    width: parent.width * (Math.max(0, Math.min(100, root.swapPercent)) / 100)
                                    height: parent.height
                                    radius: height / 2
                                    color: Root.Color.red

                                    Behavior on width {
                                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(root.swapPercent) + "%"
                                    font.pointSize: 10
                                    font.bold: true
                                    color: Root.Color.base
                                }
                            }
                        }

                        // Network
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: netRow.height + 14
                            radius: 12
                            color: Root.Color.mantle

                            RowLayout {
                                id: netRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 12
                                    rightMargin: 12
                                }
                                spacing: 10

                                Text {
                                    text: "⇣"
                                    font.pointSize: 14
                                    color: Root.Color.lavender
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: "下载"
                                        font.pointSize: 10
                                        color: Root.Color.subtext0
                                    }

                                    Text {
                                        text: formatSpeed(root.netDownKBps)
                                        font.pointSize: 12
                                        font.bold: true
                                        color: Root.Color.text
                                    }
                                }

                                Text {
                                    text: "⇡"
                                    font.pointSize: 14
                                    color: Root.Color.red
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: "上传"
                                        font.pointSize: 10
                                        color: Root.Color.subtext0
                                    }

                                    Text {
                                        text: formatSpeed(root.netUpKBps)
                                        font.pointSize: 12
                                        font.bold: true
                                        color: Root.Color.text
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function formatTemp(t) {
        if (t === undefined || t === null || isNaN(t) || t < 0) return "N/A";
        return Math.round(t) + "°C";
    }

    function formatSpeed(kib) {
        if (kib < 0.1) return "0 KiB/s";
        if (kib >= 1024) return (kib / 1024).toFixed(1) + " MiB/s";
        return Math.round(kib) + " KiB/s";
    }

    // Gauge card component
    Component {
        id: gaugeCardComponent
        Item {
            id: gaugeItem
            property string title: ""
            property real value: -1
            property real temperature: -1
            property color accent: Root.Color.lavender
            property real thickness: 12

            implicitHeight: 160

            ColumnLayout {
                anchors.fill: parent
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120

                    Canvas {
                        id: gaugeCanvas
                        anchors.fill: parent

                        Connections {
                            target: gaugeItem
                            function onValueChanged() { gaugeCanvas.requestPaint(); }
                            function onAccentChanged() { gaugeCanvas.requestPaint(); }
                        }

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const w = width;
                            const h = height;
                            const cx = w / 2;
                            const cy = h / 2;
                            const r = Math.min(w, h) / 2 - gaugeItem.thickness;
                            const start = -210 * Math.PI / 180;
                            const sweep = 240 * Math.PI / 180;
                            ctx.lineWidth = gaugeItem.thickness;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = Root.Color.surface0;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, start, start + sweep, false);
                            ctx.stroke();
                            const pct = gaugeItem.value < 0 ? 0 : Math.max(0, Math.min(100, gaugeItem.value));
                            ctx.strokeStyle = gaugeItem.accent;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, start, start + sweep * (pct / 100), false);
                            ctx.stroke();
                        }

                        onWidthChanged: requestPaint();
                        onHeightChanged: requestPaint();
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: (gaugeItem.value >= 0 ? Math.round(gaugeItem.value) + "%" : "N/A")
                            font.pointSize: 18
                            font.bold: true
                            color: Root.Color.text
                        }

                        Text {
                            text: gaugeItem.title
                            font.pointSize: 10
                            color: Root.Color.subtext0
                        }
                    }
                }

                Text {
                    text: formatTemp(gaugeItem.temperature)
                    font.pointSize: 10
                    color: Root.Color.subtext0
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
