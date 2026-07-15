pragma Singleton

import QtQuick

// ============================================================
// LyricsSyncEngine — 统一的歌词同步引擎
// ============================================================
// 职责: 二分查找 + 字级进度计算 + 自适应 Timer
// 供给方: LyricsContent.qml / Media.qml 各自将标准化后的
//         playbackSeconds 写入本 Singleton 的 playbackSeconds，
//         并绑定 activeLineIndex / activeWordIndex 等输出。
// ============================================================

QtObject {
    id: root

    // ---- 输入 (由消费者写入) ----
    // 歌词数据：来自 Python fetcher 输出的 lines 数组
    // 结构: [{time, text, words: [{word, startTime, endTime}]}]
    property var lyricsData: []
    // 标准化为秒的当前播放位置 (基于 T0 验证结果)
    property double playbackSeconds: 0
    // 播放状态: true = 正在播放
    property bool isPlaying: false
    // 歌曲标识 (trackTitle)，用于检测歌曲切换
    property string trackId: ""

    // ---- 输出 (由消费者绑定) ----
    readonly property int activeLineIndex: _activeLineIndex
    readonly property int activeWordIndex: _activeWordIndex
    readonly property double activeWordProgress: _activeWordProgress
    readonly property bool hasWordLevelData: _hasWordLevelData

    // ---- 内部状态 ----
    property int _activeLineIndex: -1
    property int _activeWordIndex: -1
    property double _activeWordProgress: 0.0
    property bool _hasWordLevelData: false
    property double _lastPlaybackSeconds: -1
    property string _lastTrackId: ""

    // ---- 常量 ----
    readonly property double seekJumpThreshold: 2.0   // 跳变阈值(秒)
    readonly property double lookAheadTime: 0.3       // 提前量(秒)
    readonly property int wordLevelInterval: 50        // 逐字模式 Timer 间隔(ms)
    readonly property int lineLevelInterval: 100       // 行级模式 Timer 间隔(ms)

    // ---- 内部 Timer ----
    property int _timerInterval: lineLevelInterval

    Timer {
        id: syncTimer
        interval: root._timerInterval
        running: root.isPlaying && root.lyricsData && root.lyricsData.length > 0
        repeat: true
        onTriggered: root._syncTick()
    }

    // ---- 当数据或播放状态变化时重置 ----
    onLyricsDataChanged: {
        root._detectDatasetChange();
    }

    onTrackIdChanged: {
        if (root.trackId !== root._lastTrackId) {
            root._lastTrackId = root.trackId;
            root._reset();
        }
    }

    onIsPlayingChanged: {
        if (!root.isPlaying) {
            // 暂停时：停止 Timer，保留当前状态
            syncTimer.running = false;
        } else {
            // 恢复播放：启动 Timer，立即执行一次 sync
            root._lastPlaybackSeconds = -1;
            syncTimer.interval = root._timerInterval;
            syncTimer.running = root.lyricsData && root.lyricsData.length > 0;
            if (syncTimer.running) {
                root._syncTick();
            }
        }
    }

    // ---- 内部方法 ----

    // 歌词数据变化时检测是否有逐字数据
    function _detectDatasetChange() {
        let hasWord = false;
        if (root.lyricsData && root.lyricsData.length > 0) {
            for (let i = 0; i < Math.min(root.lyricsData.length, 5); i++) {
                let line = root.lyricsData[i];
                if (line && line.words && line.words.length > 1) {
                    hasWord = true;
                    break;
                }
            }
        }
        root._hasWordLevelData = hasWord;
        root._timerInterval = hasWord ? root.wordLevelInterval : root.lineLevelInterval;
        syncTimer.interval = root._timerInterval;
        root._lastPlaybackSeconds = -1;
        root._syncTick();
    }

    // 完全重置（歌曲切换）
    function _reset() {
        root._activeLineIndex = -1;
        root._activeWordIndex = -1;
        root._activeWordProgress = 0.0;
        root._lastPlaybackSeconds = -1;
    }

    // 核心同步 tick：由 Timer 触发
    function _syncTick() {
        if (!root.lyricsData || root.lyricsData.length === 0) {
            return;
        }

        let currentSec = root.playbackSeconds;

        // 快进/快退检测
        let jumped = false;
        if (root._lastPlaybackSeconds >= 0) {
            let delta = Math.abs(currentSec - root._lastPlaybackSeconds);
            if (delta > root.seekJumpThreshold) {
                jumped = true;
            }
        }
        root._lastPlaybackSeconds = currentSec;

        // 二分查找当前行索引
        let lineIdx = root._findLineIndex(currentSec + root.lookAheadTime);

        // 如果行索引改变或跳变，更新
        if (lineIdx !== root._activeLineIndex || jumped) {
            root._activeLineIndex = lineIdx;
        }

        // 字级进度计算
        if (root._hasWordLevelData && root._activeLineIndex >= 0) {
            let wordResult = root._findWordProgress(root._activeLineIndex, currentSec);
            root._activeWordIndex = wordResult.index;
            root._activeWordProgress = wordResult.progress;
        } else {
            root._activeWordIndex = -1;
            root._activeWordProgress = 0.0;
        }
    }

    // 二分查找：找到 time <= target 的最大行索引
    function _findLineIndex(targetSec) {
        let lines = root.lyricsData;
        let len = lines.length;
        if (len === 0) return 0;

        let lo = 0;
        let hi = len - 1;

        while (lo <= hi) {
            let mid = Math.floor((lo + hi) / 2);
            let midTime = _safeTime(lines[mid]);

            if (midTime <= targetSec) {
                lo = mid + 1;
            } else {
                hi = mid - 1;
            }
        }

        // hi 指向最后一个 time <= targetSec 的行
        return Math.max(0, Math.min(len - 1, hi));
    }

    // 在指定行内查找当前字索引和进度
    function _findWordProgress(lineIndex, currentSec) {
        let line = root.lyricsData[lineIndex];
        if (!line || !line.words || line.words.length === 0) {
            return { index: -1, progress: 0.0 };
        }

        let words = line.words;
        let len = words.length;

        // 二分查找当前时间对应的字
        let lo = 0;
        let hi = len - 1;
        let wordIdx = 1;  // 默认

        while (lo <= hi) {
            let mid = Math.floor((lo + hi) / 2);
            let w = words[mid];
            let wStart = _safeWordTime(w, "startTime");

            if (wStart <= currentSec) {
                wordIdx = mid;
                lo = mid + 1;
            } else {
                hi = mid - 1;
            }
        }

        // 计算字内进度 (0.0 - 1.0)
        let currentWord = words[wordIdx];
        let wStart = _safeWordTime(currentWord, "startTime");
        let wEnd = _safeWordTime(currentWord, "endTime");
        let duration = wEnd - wStart;
        let progress = 0.0;

        if (duration > 0) {
            progress = (currentSec - wStart) / duration;
            progress = Math.max(0.0, Math.min(1.0, progress));
        }

        return { index: wordIdx, progress: progress };
    }

    // ---- 安全访问辅助 ----

    function _safeTime(line) {
        if (!line || line.time === undefined || line.time === null) return 0;
        let v = Number(line.time);
        return isNaN(v) ? 0 : v;
    }

    function _safeWordTime(word, key) {
        if (!word || word[key] === undefined || word[key] === null) return 0;
        let v = Number(word[key]);
        return isNaN(v) ? 0 : v;
    }
}
