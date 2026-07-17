import QtQuick
import QtQuick.Layouts
import QtQuick.Effects 
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Common 
import qs.Services 
import qs.Widgets.common

Item {
    id: root
    
    required property var player
    property bool active: false
    property bool showCover: true
    property alias lyricsContextWindow: lyricContainer.contextWindow
    property bool showSpectrum: true
    property var lyricsArray: []
    property int currentLineIndex: -1
    property bool hasWordData: false
    property int activeWordIdx: -1
    property real activeWordProg: 0.0
    
    readonly property string trackTitle: player ? player.trackTitle : ""
    readonly property string trackArtist: player ? player.trackArtist : ""
    readonly property string playerName: player ? (player.identity || player.busName || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""
    
    property string currentLoadedTitle: ""
    readonly property string spectrumToken: "dynamic-island-lyrics"

    // 非音乐内容检测: 标题不含音乐信号词时 emit, 通知 DynamicIsland 退回时钟模式
    signal notMusicDetected()
    property bool isNotMusic: false

    Component.onCompleted: {
        if (root.active)
            AudioSpectrum.acquire(root.spectrumToken);
    }
    Component.onDestruction: AudioSpectrum.release(root.spectrumToken)

    // ============================================================
    // 【动态自适应宽度引擎】
    // ============================================================
    property int defaultTextWidth: 350 
    property int currentTextWidth: defaultTextWidth 
    
    // 基础左右留白 (showCover/showSpectrum 为 false 时各 10px)
    implicitWidth: 10 + currentTextWidth + (showCover ? 38 : 0) + (showSpectrum ? 34 : 0) 

    Connections {
        target: root
        function onActiveChanged() {
            if (root.active)
                AudioSpectrum.acquire(root.spectrumToken);
            else
                AudioSpectrum.release(root.spectrumToken);
        }
    }

    // ================= 1. 歌词获取 (LyricsDaemon 长驻进程) =================
    Connections {
        target: LyricsDaemon
        function onLyricsReady(title, data) {
            if (title !== root.trackTitle) return;
            try {
                var obj = data;
                // 非音乐内容: 通知 DynamicIsland 退回时钟模式
                if (obj.source === "not-music") {
                    root.isNotMusic = true;
                    root.lyricsArray = [];
                    LyricsSyncEngine.lyricsData = [];
                    root.notMusicDetected();
                    return;
                }
                root.isNotMusic = false;
                var legacyArr = obj._legacy || obj;
                var linesArr = obj.lines || [];
                if (Array.isArray(legacyArr) && legacyArr.length > 0) {
                    root.lyricsArray = linesArr.length > 0 ? linesArr : legacyArr;
                    LyricsSyncEngine.lyricsData = linesArr.length > 0 ? linesArr : legacyArr;
                    LyricsSyncEngine.trackId = root.trackTitle;
                    root.currentLineIndex = 0;
                    root.currentLoadedTitle = root.trackTitle;
                } else {
                    root.lyricsArray = [{time: 0, text: "暂无歌词"}];
                    LyricsSyncEngine.lyricsData = [{time: 0, text: "暂无歌词"}];
                }
            } catch (e) {
                root.lyricsArray = [{time: 0, text: "歌词错误"}];
                LyricsSyncEngine.lyricsData = [];
            }
        }
        // 渐进式升级: 更高优先级源返回后替换歌词，不重置状态
        function onLyricsUpgrade(title, data) {
            if (title !== root.trackTitle) return;
            try {
                var obj = data;
                if (obj.source === "not-music") return;
                var linesArr = obj.lines || [];
                if (linesArr.length > 0) {
                    root.lyricsArray = linesArr;
                    LyricsSyncEngine.lyricsData = linesArr;
                }
            } catch (e) {}
        }
    }

    onTrackTitleChanged: triggerReload()
    onActiveChanged: { if (active && root.trackTitle !== root.currentLoadedTitle) triggerReload() }

    function triggerReload() {
        if (!root.active) return
        debounceTimer.restart()
    }

    Timer { 
        id: debounceTimer; interval: 300; repeat: false; 
        onTriggered: {
            if (root.trackTitle !== "") { 
                root.lyricsArray = []; root.currentLineIndex = 0; 
                LyricsDaemon.request(root.trackTitle, root.trackArtist)
            }
        }
    }

    // ================= 2. 同步逻辑 (通过 LyricsSyncEngine) =================
    Timer {
        interval: 100
        running: root.active && root.lyricsArray.length > 1 && root.player
        repeat: true
        onTriggered: {
            if (!root.player) return
            var rawPos = root.player.position
            var posSec = (rawPos > 100000) ? (rawPos / 1000000) : rawPos
            
            LyricsSyncEngine.playbackSeconds = posSec;
            LyricsSyncEngine.isPlaying = root.player ? root.player.isPlaying : false;
            
            // 读取 SyncEngine 输出
            var lineIdx = LyricsSyncEngine.activeLineIndex;
            if (lineIdx >= 0 && lineIdx < root.lyricsArray.length) {
                root.currentLineIndex = lineIdx;
            }
            root.hasWordData = LyricsSyncEngine.hasWordLevelData;
            root.activeWordIdx = LyricsSyncEngine.activeWordIndex;
            root.activeWordProg = LyricsSyncEngine.activeWordProgress;
        }
    }

    // ================= 3. 界面层 =================
    Item {
        anchors.fill: parent
        clip: true 

        // --- 专辑封面 ---
        Item {
            id: albumCoverContainer
            visible: root.showCover
            anchors.left: parent.left; anchors.leftMargin: 15; anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26
            
            Image {
                id: coverImg; anchors.fill: parent
                source: root.artUrl; visible: root.artUrl !== ""; fillMode: Image.PreserveAspectCrop
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource { sourceItem: Rectangle { width: coverImg.width; height: coverImg.height; radius: 5; color: "black" } }
                }
            }
            Text {
                visible: root.artUrl === ""; anchors.centerIn: parent
                text: "\uf001"; font.family: "Symbols Nerd Font Mono"; font.pixelSize: 14; color: "#80ffffff"
            }
        }

        // --- 歌词显示 (单行, 逐字高亮 或 整行回退) ---
        Item {
            id: lyricContainer
            anchors.left: root.showCover ? albumCoverContainer.right : parent.left
            anchors.leftMargin: root.showCover ? 12 : 0
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.currentTextWidth
            clip: true

            // 当前行数据
            property var currentLine: {
                var idx = root.currentLineIndex;
                if (idx < 0 || idx >= root.lyricsArray.length) return null;
                return root.lyricsArray[idx];
            }
            property string currentText: currentLine ? (currentLine.text || "") : ""
            property var currentWords: root.hasWordData && currentLine && currentLine.words ? currentLine.words : []
            property bool showWords: currentWords.length > 1

            // 上下文窗口配置
            property int contextWindow: 8  // 活跃字前后各显示 N 字

            // 计算上下文窗口内的 words
            property var visibleWords: {
                if (!lyricContainer.showWords) return [];
                var words = lyricContainer.currentWords;
                var activeIdx = root.activeWordIdx;
                if (activeIdx < 0 || activeIdx >= words.length) activeIdx = 0;
                var start = Math.max(0, activeIdx - lyricContainer.contextWindow);
                var end = Math.min(words.length, activeIdx + lyricContainer.contextWindow + 1);
                var result = [];
                if (start > 0) {
                    result.push({word: "…", isEllipsis: true, idx: -1});
                }
                for (var i = start; i < end; i++) {
                    result.push({
                        word: words[i].word,
                        isEllipsis: false,
                        idx: i
                    });
                }
                if (end < words.length) {
                    result.push({word: "…", isEllipsis: true, idx: -1});
                }
                return result;
            }

            // 逐字渲染 (word-level)
            Row {
                id: wordRow
                anchors.centerIn: parent
                visible: lyricContainer.showWords
                spacing: 0
                Repeater {
                    model: lyricContainer.visibleWords
                    Text {
                        text: modelData.word || ""
                        font.family: Sizes.fontFamilyLyric
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: {
                            if (modelData.isEllipsis) return "#99ffffff";
                            var currentLine = root.lyricsArray[root.currentLineIndex];
                            if (!currentLine || !currentLine.words) return "white";
                            // 活跃字以内 = 已唱, 之后 = 未唱
                            return (modelData.idx <= root.activeWordIdx) ? "#b4befe" : "white";
                        }
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }
            }

            // 整行渲染 (line-level fallback)
            Text {
                id: lyricText
                anchors.centerIn: parent
                visible: !lyricContainer.showWords
                text: lyricContainer.currentText
                color: "#b4befe"
                font.family: Sizes.fontFamilyLyric
                font.pixelSize: 18
                font.weight: Font.Bold
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                // 宽度自适应
                onImplicitWidthChanged: {
                    if (lyricContainer.showWords) return;
                    root.currentTextWidth = Math.max(root.defaultTextWidth, Math.min(implicitWidth + 20, 800));
                }
            }

            // 词行宽度自适应
            onShowWordsChanged: {
                if (lyricContainer.showWords && wordRow.implicitWidth > 0) {
                    root.currentTextWidth = Math.max(root.defaultTextWidth, Math.min(wordRow.implicitWidth + 20, 800));
                }
            }
            onVisibleWordsChanged: {
                if (lyricContainer.showWords) {
                    Qt.callLater(function() {
                        if (wordRow.implicitWidth > 0) {
                            root.currentTextWidth = Math.max(root.defaultTextWidth, Math.min(wordRow.implicitWidth + 20, 800));
                        }
                    });
                }
            }
        }

        // ============================================================
        // 【全新】：高动态对称聚合频谱条
        // ============================================================
        Item {
            id: spectrumContainer
            visible: root.showSpectrum
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            width: 21  
            height: 16 

            property var smoothValues: [0, 0, 0, 0, 0, 0]

            Timer {
                interval: 16 
                running: root.active && root.showSpectrum && AudioSpectrum.available
                repeat: true
                onTriggered: {
                    let s = spectrumContainer.smoothValues;
                    let r = AudioSpectrum.values;
                    if (!r || r.length < 6) return;
                    
                    let getRegionMax = (startRatio, endRatio) => {
                        let start = Math.max(0, Math.min(r.length - 1, Math.floor(r.length * startRatio)));
                        let end = Math.max(start, Math.min(r.length - 1, Math.floor(r.length * endRatio)));
                        let maxV = 0;
                        for (let i = start; i <= end; i++) {
                            if (r[i] > maxV) maxV = r[i];
                        }
                        return maxV * 100;
                    };

                    let targets = [0, 0, 0, 0, 0, 0];
                    
                    targets[0] = getRegionMax(0.55, 0.78) * 1.5;
                    targets[5] = getRegionMax(0.78, 0.98) * 1.5;
                    
                    targets[1] = getRegionMax(0.18, 0.33) * 1.2;
                    targets[4] = getRegionMax(0.33, 0.55) * 1.2;
                    
                    targets[2] = getRegionMax(0.00, 0.08);
                    targets[3] = getRegionMax(0.08, 0.18);

                    let globalBeat = Math.max(targets[2], targets[3]);

                    for (let i = 0; i < 6; i++) {
                        let finalTarget = Math.min(100, targets[i] * 0.8 + globalBeat * 0.2);
                        
                        let diff = finalTarget - s[i];
                        
                        if (diff > 0) s[i] += 0.85 * diff;
                        else s[i] += 0.08 * diff;
                    }
                    
                    spectrumContainer.smoothValues = s;
                    spectrumCanvas.requestPaint();
                }
            }

            Canvas {
                id: spectrumCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    let s = parent.smoothValues;
                    
                    ctx.beginPath();
                    ctx.lineCap = "round"; 
                    ctx.lineWidth = 2.5;   
                    ctx.strokeStyle = "#b4befe"; 

                    for(let i = 0; i < 6; i++) {
                        let val = Math.min(1.0, s[i] / 100.0);
                        let h = Math.max(3, val * height);
                        
                        let x = 1.25 + i * 3.7; 
                        
                        ctx.moveTo(x, height / 2 - h / 2);
                        ctx.lineTo(x, height / 2 + h / 2);
                    }
                    ctx.stroke();
                }
            }
        }
    }
}
