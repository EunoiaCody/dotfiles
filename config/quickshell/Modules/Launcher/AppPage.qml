import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets.common
import qs.Services
import "../../Common/functions/AppManager.js" as AppManager

Item {
    id: root

    signal requestCloseLauncher()

    property string query: ""
    ListModel { id: appModel }

    RofiStyle {
        id: rofiStyle
    }

    function decrementCurrentIndex() { setCurrentIndex(appsList.currentIndex - 1) }
    function incrementCurrentIndex() { setCurrentIndex(appsList.currentIndex + 1) }

    function setCurrentIndex(index, skipScroll) {
        if (appModel.count === 0) {
            appsList.currentIndex = -1
            appsList.contentY = 0
            return
        }

        appsList.currentIndex = Math.max(0, Math.min(index, appModel.count - 1))
        if (!skipScroll) ensureCurrentVisible()
    }

    function ensureCurrentVisible() {
        if (appsList.currentIndex < 0)
            return

        let firstVisibleIndex = Math.round(appsList.contentY / rofiStyle.listStep)
        if (appsList.currentIndex < firstVisibleIndex)
            firstVisibleIndex = appsList.currentIndex
        else if (appsList.currentIndex >= firstVisibleIndex + rofiStyle.listRows)
            firstVisibleIndex = appsList.currentIndex - rofiStyle.listRows + 1

        const maxFirstIndex = Math.max(0, appModel.count - rofiStyle.listRows)
        firstVisibleIndex = Math.max(0, Math.min(firstVisibleIndex, maxFirstIndex))
        appsList.contentY = firstVisibleIndex * rofiStyle.listStep
    }

    // ── 搜索：直接存 DesktopEntry 原生对象 → Qt 按引用 diff → 匹配 item 保留 + 平滑移动 ──
    function search(text) {
        var wrapped = AppManager.updateFilter(text, DesktopEntries)
        var target = []
        for (var i = 0; i < wrapped.length; i++) {
            var entry = wrapped[i].appObj
            if (entry && entry.id) {
                target.push(entry)
            }
        }

        // 始终按使用频率排序
        target = LaunchTracker.sortByFrequencyRaw(target)

        // ── 安全增量 diff（有空值防护）──
        // 若模型中有失效条目，先整体重建
        var needsRebuild = false
        for (var ci = 0; ci < appModel.count; ci++) {
            var item = appModel.get(ci)
            if (!item || !item.app || !item.app.id) {
                needsRebuild = true
                break
            }
        }

        if (needsRebuild) {
            appModel.clear()
            for (var j = 0; j < target.length; j++) {
                appModel.append({ app: target[j] })
            }
        } else {
            // 1) 建立目标 ID 集合
            var targetIds = {}
            for (var ti = 0; ti < target.length; ti++) {
                targetIds[target[ti].id] = true
            }

            // 2) 移除不在目标中的 item（倒序）→ remove 过渡
            for (var ri = appModel.count - 1; ri >= 0; ri--) {
                if (!targetIds[appModel.get(ri).app.id]) {
                    appModel.remove(ri)
                }
            }

            // 3) 建立当前 ID→位置 映射
            var curPos = {}
            for (var ci2 = 0; ci2 < appModel.count; ci2++) {
                curPos[appModel.get(ci2).app.id] = ci2
            }

            // 4) 插入新 item → add 过渡
            for (var ii = 0; ii < target.length; ii++) {
                var tid = target[ii].id
                if (curPos[tid] === undefined) {
                    appModel.insert(ii, { app: target[ii] })
                    for (var id in curPos) {
                        if (curPos[id] >= ii) curPos[id]++
                    }
                    curPos[tid] = ii
                }
            }

            // 5) 移动已存在 item 到正确位置 → displaced 过渡
            for (var mi = 0; mi < target.length && mi < appModel.count; mi++) {
                var expectedId = target[mi].id
                var curIdx = -1
                for (var sj = mi; sj < appModel.count; sj++) {
                    if (appModel.get(sj).app.id === expectedId) {
                        curIdx = sj
                        break
                    }
                }
                if (curIdx >= 0 && curIdx !== mi) {
                    appModel.move(curIdx, mi, 1)
                    for (var id2 in curPos) {
                        if (curPos[id2] >= mi && curPos[id2] < curIdx) curPos[id2]++
                    }
                    curPos[expectedId] = mi
                }
            }
        }

        appsList.contentY = 0
        setCurrentIndex(0)
    }

    // 应用安装/卸载 → 自动重新搜索（无需轮询）
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.search(root.query)
        }
    }

    // 轮询等待 DesktopEntries 和 LaunchTracker 都就绪后再初始化搜索
    // 否则首次打开时频率数据未加载，排序退化为纯字母序
    property int _pollRetries: 0
    readonly property int _pollMaxRetries: 80  // 80 × 50ms = 4 秒超时

    Timer {
        id: startupPollTimer
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            let entriesReady = DesktopEntries.applications.values.length > 0
            let trackerReady = LaunchTracker.ready

            if (entriesReady && trackerReady) {
                root.search(root.query)
                running = false
            } else if (root._pollRetries >= root._pollMaxRetries) {
                // 超时：用现有数据（可能频率为空），避免无限等待
                root.search(root.query)
                running = false
            }
            root._pollRetries++
        }
    }

    // ── 搜索更新：增量 diff 触发 StyledListView 的 add/remove/move 过渡 ──
    // 匹配的 item 会被保留并平滑移动，不再全部销毁重建
    onQueryChanged: search(query)

    onVisibleChanged: {
        if (visible)
            search(query)
    }

    function highlightText(fullText, query) {
        let safeText = fullText.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        if (!query || query.trim() === "") return safeText
        let escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        let regex = new RegExp("(" + escapedQuery + ")", "gi")
        return safeText.replace(regex, "<u><b>$1</b></u>")
    }

    function fallbackIconSource() {
        const fallback = Quickshell.iconPath("application-x-executable", "");
        return fallback && fallback !== "" ? fallback : "image://icon/application-x-executable";
    }

    function iconSource(icon) {
        if (!icon || icon === "")
            return fallbackIconSource();
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.startsWith("file://") || icon.startsWith("image://"))
            return icon;

        const resolved = Quickshell.iconPath(icon, "application-x-executable");
        return resolved && resolved !== "" ? resolved : fallbackIconSource();
    }

    // 提取 delegate 为命名 Component，供 transitions 的 PropertyAction(delegate: null) 使用
    Component {
        id: appDelegate

        Item {
            id: delegateItem
            width: ListView.view.width
            height: rofiStyle.rowHeight

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.setCurrentIndex(index)
                    runSelectedApp()
                }
                onEntered: root.setCurrentIndex(index, true)
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: rofiStyle.itemPadding
                spacing: rofiStyle.itemSpacing

                Item {
                    Layout.preferredWidth: rofiStyle.iconSize
                    Layout.preferredHeight: rofiStyle.iconSize
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.fill: parent
                        sourceSize.width: rofiStyle.iconSize * 2
                        sourceSize.height: rofiStyle.iconSize * 2
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true

                        property bool fallbackApplied: false
                        readonly property string requestedSource: root.iconSource((model.app && model.app.icon) ? model.app.icon : "")
                        readonly property string fallbackSource: root.fallbackIconSource()

                        source: fallbackApplied ? fallbackSource : requestedSource

                        onRequestedSourceChanged: fallbackApplied = false

                        onStatusChanged: {
                            if (status === Image.Error && !fallbackApplied && source !== fallbackSource)
                                fallbackApplied = true
                        }
                    }
                }

                Text {
                    text: root.highlightText((model.app && model.app.name) ? model.app.name : "", root.query)
                    textFormat: Text.StyledText
                    color: delegateItem.ListView.isCurrentItem ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: rofiStyle.fontPixelSize
                    font.bold: false
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    StyledListView {
        id: appsList
        width: parent.width
        height: rofiStyle.listHeight
        anchors.top: parent.top
        clip: true
        spacing: rofiStyle.listSpacing
        animateAppearance: true
        animateMovement: true
        smoothWheelEnabled: false
        showVerticalScrollBar: false

        model: appModel
        delegate: appDelegate

        boundsBehavior: Flickable.StopAtBounds
        maximumFlickVelocity: 3000
        highlightFollowsCurrentItem: false
        highlightRangeMode: ListView.NoHighlightRange

        highlight: Rectangle {
            width: appsList.width
            height: rofiStyle.rowHeight
            color: Appearance.colors.colPrimary
            radius: rofiStyle.controlRadius
            y: appsList.currentItem ? appsList.currentItem.y : 0

            Behavior on y {
                NumberAnimation {
                    duration: Appearance.animation.expressiveDefaultSpatial.duration
                    easing.type: Appearance.animation.expressiveDefaultSpatial.type
                    easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                }
            }
        }

        // ── 搜索过渡：新增从右侧滑入 + 淡入；移除向右滑出 + 淡出 ──
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; from: appsList.width * 0.3; to: 0; duration: 250; easing.type: Easing.OutCubic }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; to: appsList.width * 0.3; duration: 200; easing.type: Easing.InCubic }
                NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
            }
        }

        displaced: Transition {
            NumberAnimation { property: "y"; duration: 250; easing.type: Easing.OutCubic }
        }
    }

    function runSelectedApp() {
        if (appModel.count > 0 && appsList.currentIndex >= 0) {
            var appData = appModel.get(appsList.currentIndex).app
            if (appData) {
                LaunchTracker.recordLaunch(appData.id)
                appData.execute()
            }
            root.requestCloseLauncher()
        }
    }
}
