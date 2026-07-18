pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

// Tracks application launch frequency for most-frequently-used sorting
// Persists to ~/.cache/quickshell/app-launch-freq.json

Singleton {
    id: root

    property var frequencies: ({})
    readonly property string configDir: Paths.homeDir + "/.cache/quickshell"
    readonly property string filePath: configDir + "/app-launch-freq.json"
    property bool storeReady: false
    property bool ready: false

    property bool _dirty: false
    property var _saveTimer: Timer {
        interval: 2000
        repeat: false
        onTriggered: root._doSave()
    }

    // Record a launch for the given desktop entry id
    function recordLaunch(appId) {
        if (!appId || appId === "") return

        let current = frequencies[appId] || 0
        frequencies[appId] = current + 1
        _dirty = true
        _saveTimer.restart()
    }

    // Get launch count for an app (default 0)
    function getFrequency(appId) {
        return frequencies[appId] || 0
    }

    // Sort apps array by frequency descending, then alphabetically as tiebreaker
    function sortByFrequency(apps) {
        if (!apps || apps.length === 0) return apps || []

        let sorted = apps.slice()
        sorted.sort((a, b) => {
            let freqA = root.getFrequency(a.appObj ? a.appObj.id : "")
            let freqB = root.getFrequency(b.appObj ? b.appObj.id : "")
            if (freqA !== freqB) return freqB - freqA
            let nameA = (a.name || "").toLowerCase()
            let nameB = (b.name || "").toLowerCase()
            if (nameA < nameB) return -1
            if (nameA > nameB) return 1
            return 0
        })
        return sorted
    }

    // Internal: write frequencies to disk
    function _doSave() {
        if (!_dirty || !storeReady) return
        _dirty = false
        freqFile.setText(JSON.stringify(frequencies, null, 2))
    }

    // 在单例创建时立即初始化（不延迟到首次访问）
    Component.onCompleted: {
        ensureDir.running = true
    }

    // 确保缓存目录存在
    Process {
        id: ensureDir
        command: ["mkdir", "-p", root.configDir]
        onExited: {
            root.storeReady = true
            freqFile.reload()
        }
    }

    // File-based persistence (read/write JSON)
    FileView {
        id: freqFile
        path: root.filePath

        onLoaded: {
            try {
                var parsed = JSON.parse(freqFile.text().trim() || "{}")
                if (typeof parsed === "object" && parsed !== null) {
                    root.frequencies = parsed
                }
            } catch (error) {
                root.frequencies = {}
                root._dirty = true
                root._doSave()
            }
            root.ready = true
        }

        onLoadFailed: {
            root.frequencies = {}
            root.ready = true
        }
    }
}
