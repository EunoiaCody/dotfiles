pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================
// ClipboardService — 剪贴板历史服务 (cliphist + wl-clipboard)
// ============================================================
// 通过 cliphist list 获取剪贴板历史条目列表。
// 使用 wl-copy 将选中条目写回剪贴板。
// 面板打开时自动轮询刷新（1.5s 间隔）。
// ============================================================

QtObject {
    id: root

    // --- 条目数据 ---
    // 格式: [{id: 0, preview: "第一行预览文本..."}, ...]
    property var entries: []
    property int entryCount: 0
    property bool loading: false
    property string lastError: ""

    // --- 面板激活状态（由 ClipboardContent 控制） ---
    property bool panelActive: false

    onPanelActiveChanged: {
        if (panelActive) {
            root.refresh()
            pollTimer.running = true
        } else {
            pollTimer.running = false
        }
    }

    // --- 轮询定时器 ---
    property Timer pollTimer: Timer {
        interval: 1500
        repeat: true
        running: false
        onTriggered: root.refresh()
    }

    // --- 临时缓冲（onRead 逐行累积） ---
    property var _pendingEntries: []

    // --- 完成去抖定时器 ---
    property Timer _debounceTimer: Timer {
        interval: 80
        repeat: false
        onTriggered: {
            root.entries = root._pendingEntries
            root.entryCount = root.entries.length
            root.loading = false
        }
    }

    // ============================================================
    // 列出剪贴板历史 (cliphist list)
    // ============================================================
    property Process listProc: Process {
        id: listProc
        command: ["cliphist", "list"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(raw) {
                var line = raw.trim()
                if (!line) return

                // cliphist list 输出格式: "id\tpreview"
                var tabIdx = line.indexOf("\t")
                if (tabIdx < 0) return

                var id = parseInt(line.substring(0, tabIdx))
                var preview = line.substring(tabIdx + 1)
                if (isNaN(id)) return

                // 截断预览文本到 120 字符
                if (preview.length > 120)
                    preview = preview.substring(0, 120) + "…"

                root._pendingEntries.push({id: id, preview: preview})
            }
        }

        onExited: {
            // 进程退出后，等待短暂去抖再提交
            root._debounceTimer.restart()
        }
    }

    function refresh() {
        if (listProc.running) return
        root._pendingEntries = []
        root.loading = true
        root.lastError = ""
        listProc.running = true
    }

    // ============================================================
    // 复制条目到剪贴板 (cliphist decode <id> | wl-copy)
    // ============================================================
    property Process copyProc: Process {
        id: copyProc
        command: []

        onExited: {
            if (exitCode === 0) {
                root._copySuccess = true
            } else {
                root.lastError = "复制失败 (exit code: " + exitCode + ")"
            }
        }
    }

    property bool _copySuccess: false
    property int _copyTargetId: -1

    // 将指定 ID 的剪贴板条目解码并写入 Wayland 剪贴板
    function copyToClipboard(id) {
        root._copySuccess = false
        root._copyTargetId = id
        // 使用 shell 管道: cliphist decode <id> | wl-copy
        copyProc.command = ["bash", "-c", "cliphist decode " + id + " | wl-copy"]
        copyProc.running = true
    }

    // ============================================================
    // 解码条目内容（异步回调模式）
    // ============================================================
    property var _decodeCallback: null
    property string _decodedContent: ""

    property Process decodeProc: Process {
        id: decodeProc
        command: []

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(raw) {
                if (root._decodedContent.length > 0)
                    root._decodedContent += "\n"
                root._decodedContent += raw
            }
        }

        onExited: {
            if (root._decodeCallback) {
                var cb = root._decodeCallback
                root._decodeCallback = null
                cb(root._decodedContent)
            }
        }
    }

    function decode(id, callback) {
        root._decodedContent = ""
        root._decodeCallback = callback
        decodeProc.command = ["cliphist", "decode", String(id)]
        decodeProc.running = true
    }

    // ============================================================
    // 删除条目
    // ============================================================

    // 按 ID 删除单条：解码获取完整内容 → 用完整内容精准匹配删除
    function deleteItem(id) {
        root.decode(id, function(content) {
            if (!content) return
            // 使用完整解码内容作为查询键（比仅首行更精准）
            var query = content.trim().substring(0, 500)
            if (!query) return
            deleteProc.command = ["cliphist", "delete-query", query]
            deleteProc.running = true
        })
    }

    property Process deleteProc: Process {
        id: deleteProc
        command: []

        onExited: {
            // 删除完成后立即刷新列表
            root.refresh()
        }
    }

    // ============================================================
    // 清空全部历史
    // ============================================================
    property Process wipeProc: Process {
        id: wipeProc
        command: ["cliphist", "wipe"]

        onExited: {
            root.entries = []
            root.entryCount = 0
        }
    }

    function wipe() {
        wipeProc.running = true
    }

    // ============================================================
    // 获取剪贴板数据库路径（辅助）
    // ============================================================
    readonly property string dataDir: {
        var home = Quickshell.env("HOME") || "/home/eunoia"
        var xdgData = Quickshell.env("XDG_DATA_HOME") || (home + "/.local/share")
        return xdgData + "/cliphist"
    }

    readonly property string dbPath: dataDir + "/db"
}
