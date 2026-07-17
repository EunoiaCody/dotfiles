pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================
// LyricsDaemon — 歌词获取进程管理器
// ============================================================
// 使用 CLI 模式 (args) 而非 stdin daemon 模式,
// 因为 Quickshell 的 Process 对 stdin write 支持有限。
// 每次切歌时重启进程。
//
// 进程在并发获取所有源后，可能输出 1-2 条 JSON 行:
//   第 1 行: _update: false (最快返回的源)
//   第 2 行: _update: true (更高优先级源的结果，升级)
// QML 端通过 _update 字段区分初始结果和升级结果。
// ============================================================

QtObject {
    id: root

    signal lyricsReady(string title, var data)
    signal lyricsUpgrade(string title, var data)

    property string _pendingTitle: ""
    property string _currentTitle: ""
    property int _lineCount: 0

    property Process proc: Process {
        id: lyricsProc
        command: ["python3", Paths.scriptPath("media", "lyrics_fetcher.py"), "", ""]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(raw) {
                var line = raw.trim();
                if (!line) return;
                try {
                    var result = JSON.parse(line);
                    var title = root._pendingTitle || root._currentTitle;
                    if (!title || !result) return;
                    
                    if (result._update === true) {
                        // 渐进式升级: 用更好源的歌词替换当前歌词
                        root.lyricsUpgrade(title, result);
                    } else {
                        // 首次结果: 新歌曲歌词
                        root._currentTitle = title;
                        root._pendingTitle = "";
                        root._lineCount = 0;
                        root.lyricsReady(title, result);
                    }
                    root._lineCount++;
                } catch (e) {}
            }
        }
    }

    function request(title, artist) {
        root._pendingTitle = title;
        root._lineCount = 0;
        // 重启进程
        root.proc.running = false;
        root.proc.command = ["python3", Paths.scriptPath("media", "lyrics_fetcher.py"), title, artist || ""];
        root.proc.running = true;
    }
}
