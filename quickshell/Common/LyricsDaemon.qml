pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================
// LyricsDaemon — 歌词获取进程管理器
// ============================================================
// 使用 CLI 模式 (args) 而非 stdin daemon 模式,
// 因为 Quickshell 的 Process 对 stdin write 支持有限。
// 每次切歌时重启进程(冷启动开销 ~50ms)，远快于旧版 spawn。
// ============================================================

QtObject {
    id: root

    signal lyricsReady(string title, var data)

    property string _pendingTitle: ""

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
                    var title = root._pendingTitle;
                    if (title && result) {
                        root.lyricsReady(title, result);
                        root._pendingTitle = "";
                    }
                } catch (e) {}
            }
        }
    }

    function request(title, artist) {
        root._pendingTitle = title;
        // 重启进程: 改为 running=false 后更新 command 再启动
        root.proc.running = false;
        root.proc.command = ["python3", Paths.scriptPath("media", "lyrics_fetcher.py"), title, artist || ""];
        root.proc.running = true;
    }
}
