import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Common

Item {
    id: root

    // ============================================================
    // 信号
    // ============================================================
    signal requestPickImage()

    // ============================================================
    // 公开属性：图片 & 一言
    // ============================================================
    property string currentImagePath: ""
    property var allImages: []
    property string hitokotoText: ""
    property string hitokotoFrom: ""
    property bool hitokotoLoading: false

    // ============================================================
    // 一言每日缓存
    // ============================================================
    property string cachedDate: ""
    property string cachedHitokoto: ""
    property string cachedFrom: ""

    readonly property int charsPerColumn: 12
    readonly property int maxColumns: 12
    readonly property string hitokotoApiUrl: "https://v1.hitokoto.cn/?c=a&c=b&c=d&c=k"

    ListModel { id: columnModel }
    ListModel { id: imageModel }

    // ============================================================
    // FloatingHoleCard — 从 OverviewContent 移入
    // ============================================================
    component FloatingHoleCard : Item {
        id: cardRoot
        default property alias content: innerContainer.data
        property real floatMargin: 10
        property real contentMargin: 14

        Rectangle {
            id: cardBackground
            anchors.fill: parent
            anchors.margins: cardRoot.floatMargin
            radius: 20
            color: Appearance.colors.colLayer0
            border.width: 0
            border.color: "transparent"
        }

        Item {
            id: innerContainer
            anchors.fill: cardBackground
            anchors.margins: cardRoot.contentMargin
        }
    }

    // ============================================================
    // 图片扫描
    // ============================================================
    property string illustDir: "/home/eunoia/Pictures/Illustraions"

    Process {
        id: scanProcess
        command: ["bash", "-c",
            "if [ -d '" + root.illustDir + "' ]; then find '" + root.illustDir +
            "' -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort; fi"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (file) => {
                var f = file.trim()
                if (f !== "") {
                    root.allImages.push(f)
                    imageModel.append({ path: f })
                }
            }
        }
        onExited: {
            if (imageModel.count > 0 && root.currentImagePath === "")
                root.currentImagePath = imageModel.get(0).path
        }
    }

    function scanImages() {
        root.allImages = []
        imageModel.clear()
        scanProcess.running = false
        scanProcess.running = true
    }

    // ============================================================
    // 选中图片（由外部 overlay 回调设置）
    // ============================================================
    function setImagePath(path) {
        root.currentImagePath = path
    }

    // ============================================================
    // 一言获取
    // ============================================================
    // 过滤英文语句 (>70% ASCII 则重新获取)
    function isMostlyAscii(text) {
        if (!text) return false
        var ascii = 0
        for (var i = 0; i < text.length; i++) {
            if (text.charCodeAt(i) < 128) ascii++
        }
        return (ascii / text.length) > 0.7
    }

    function applyHitokoto(data) {
        var text = data.hitokoto || ""
        if (root.isMostlyAscii(text)) {
            root.hitokotoLoading = false
            fetchHitokoto(true)
            return
        }
        var today = new Date().toISOString().slice(0, 10)
        root.cachedDate = today
        root.cachedHitokoto = text
        root.cachedFrom = data.from || ""
        root.hitokotoText = root.cachedHitokoto
        root.hitokotoFrom = root.cachedFrom
        buildColumns()
    }

    function fetchHitokoto(forceRefresh) {
        var today = new Date().toISOString().slice(0, 10)
        if (!forceRefresh && root.cachedDate === today && root.cachedHitokoto !== "") {
            root.hitokotoText = root.cachedHitokoto
            root.hitokotoFrom = root.cachedFrom
            buildColumns()
            return
        }

        if (root.hitokotoLoading) return
        root.hitokotoLoading = true

        var xhr = new XMLHttpRequest()
        xhr.open("GET", root.hitokotoApiUrl)
        xhr.timeout = 5000

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.hitokotoLoading = false
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        root.applyHitokoto(data)
                    } catch (e) {
                        setFallbackHitokoto()
                    }
                } else {
                    setFallbackHitokoto()
                }
            }
        }

        xhr.ontimeout = function() {
            root.hitokotoLoading = false
            setFallbackHitokoto()
        }

        xhr.onerror = function() {
            root.hitokotoLoading = false
            // XMLHttpRequest 失败时降级到 curl
            fallbackCurl()
        }

        xhr.send()
    }

    function fallbackCurl() {
        curlProc.running = false
        curlProc.running = true
    }

    function setFallbackHitokoto() {
        if (root.cachedHitokoto !== "") {
            root.hitokotoText = root.cachedHitokoto
            root.hitokotoFrom = root.cachedFrom
        } else {
            root.hitokotoText = "岁月失语，惟石能言。"
            root.hitokotoFrom = "佚名"
        }
        buildColumns()
    }

    Process {
        id: curlProc
        command: ["bash", "-c",
            "curl -s --max-time 5 '" + root.hitokotoApiUrl + "' 2>/dev/null || echo ''"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                var text = data.trim()
                if (text === "") { setFallbackHitokoto(); return }
                try {
                    var parsed = JSON.parse(text)
                    root.applyHitokoto(parsed)
                } catch (e) {
                    setFallbackHitokoto()
                }
            }
        }
        onExited: {
            if (root.hitokotoText === "") setFallbackHitokoto()
        }
    }

    // ============================================================
    // 竖排文字构建
    // ============================================================
    function buildColumns() {
        columnModel.clear()
        if (!root.hitokotoText) return

        var text = root.hitokotoText
        // 标点避头: 若列首字符是标点，从前列移一字
        function shouldPullPrev(chunk, prevChunk) {
            if (!chunk || chunk.length === 0 || !prevChunk) return false
            var first = chunk.charAt(0)
            var punct = "，。！？；：、》）」』】〕"
            return punct.indexOf(first) >= 0 && prevChunk.length > 1
        }

        var chunks = []
        var maxChars = root.maxColumns * root.charsPerColumn
        if (text.length > maxChars) text = text.slice(0, maxChars) + "…"

        for (var i = 0; i < text.length; i += root.charsPerColumn) {
            chunks.push(text.slice(i, i + root.charsPerColumn))
        }

        // 从后往前处理标点避头
        for (var j = chunks.length - 1; j > 0; j--) {
            if (shouldPullPrev(chunks[j], chunks[j - 1])) {
                var lastChar = chunks[j - 1].charAt(chunks[j - 1].length - 1)
                chunks[j - 1] = chunks[j - 1].slice(0, -1)
                chunks[j] = lastChar + chunks[j]
            }
        }

        // 按从左到右排列列 (用户要求: 从左到右)
        for (var k = 0; k < chunks.length; k++) {
            columnModel.append({ colText: chunks[k].split("").join("\n") })
        }
    }

    // ============================================================
    // 初始化
    // ============================================================
    Component.onCompleted: {
        scanImages()
        // 先显示默认句子，再异步获取一言
        root.hitokotoText = "岁月失语，惟石能言。"
        root.hitokotoFrom = "佚名"
        buildColumns()
        fetchHitokoto(false)
    }

    // ============================================================
    // 布局
    // ============================================================
    FloatingHoleCard {
        anchors.fill: parent

        // ── 内容区 ──
        Row {
            anchors.fill: parent
            spacing: 8

            // ── 左侧：插图 ──
            Item {
                width: 270
                height: parent.height

                Item {
                    id: imageFrame
                    anchors.centerIn: parent
                    width: parent.width - 10
                    height: parent.height - 24

                    Rectangle {
                        id: imageBg
                        anchors.fill: parent
                        radius: 10
                        color: Appearance.colors.colLayer2
                        visible: !illustImage.visible
                    }

                    Image {
                        id: illustImage
                        anchors.fill: parent
                        source: root.currentImagePath ? "file://" + root.currentImagePath : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 400
                        asynchronous: true
                        cache: false
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: illustImage.status === Image.Ready ? illustImage : imageBg
                        maskSource: Rectangle {
                            width: imageFrame.width
                            height: imageFrame.height
                            radius: 10
                            visible: false
                        }
                    }
                }

                MouseArea {
                    anchors.fill: imageFrame
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestPickImage()
                }
            }

            // ── 右侧：竖排文字 ──
            Item {
                width: parent.width - 270 - 8
                height: parent.height
                clip: true

                Row {
                    id: verticalTextRow
                    anchors.centerIn: parent
                    layoutDirection: Qt.LeftToRight
                    spacing: 2

                    Repeater {
                        model: columnModel

                        Text {
                            text: model.colText
                            font.family: Sizes.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Appearance.colors.colOnSurface
                            horizontalAlignment: Text.AlignHCenter
                            lineHeight: 1.1
                        }
                    }
                }

                // 出处标注
                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    text: root.hitokotoFrom ? "—— 《" + root.hitokotoFrom + "》" : ""
                    font.family: Sizes.fontFamily
                    font.pixelSize: 11
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // ── 刷新按钮 ──
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            width: 30
            height: 30
            radius: 15
            color: refreshMouse.containsMouse ? Appearance.colors.colLayer2Hover : "transparent"

            Text {
                id: refreshIcon
                anchors.centerIn: parent
                text: "refresh"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                color: refreshMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant

                RotationAnimation {
                    id: spinAnim
                    target: refreshIcon
                    property: "rotation"
                    from: 0; to: 360
                    duration: 800
                    loops: Animation.Infinite
                    running: root.hitokotoLoading
                }

                RotationAnimation {
                    id: resetAnim
                    target: refreshIcon
                    property: "rotation"
                    to: 0
                    duration: 300
                    direction: RotationAnimation.Shortest
                }
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                property int lastClickTime: 0

                onClicked: {
                    var now = Date.now()
                    if (now - lastClickTime < 2000) return  // 2 秒冷却
                    lastClickTime = now
                    if (!root.hitokotoLoading) {
                        resetAnim.stop()
                        refreshIcon.rotation = 0
                        spinAnim.start()
                        root.fetchHitokoto(true)
                    }
                }
            }
        }
    }
}
