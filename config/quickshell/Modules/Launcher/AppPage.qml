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
    ListModel { id: filteredAppsModel }

    RofiStyle {
        id: rofiStyle
    }

    function decrementCurrentIndex() { setCurrentIndex(appsList.currentIndex - 1) }
    function incrementCurrentIndex() { setCurrentIndex(appsList.currentIndex + 1) }

    function setCurrentIndex(index, skipScroll) {
        if (filteredAppsModel.count === 0) {
            appsList.currentIndex = -1
            appsList.contentY = 0
            return
        }

        appsList.currentIndex = Math.max(0, Math.min(index, filteredAppsModel.count - 1))
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

        const maxFirstIndex = Math.max(0, filteredAppsModel.count - rofiStyle.listRows)
        firstVisibleIndex = Math.max(0, Math.min(firstVisibleIndex, maxFirstIndex))
        appsList.contentY = firstVisibleIndex * rofiStyle.listStep
    }

    // ── 增量搜索（避免 modelReset，让 ListView 的 add/remove/move 过渡生效）──
    function search(text) {
        let raw = AppManager.updateFilter(text, DesktopEntries)
        // 无搜索词时按频率排序，搜索时保持字母序
        if (text.trim() === "") {
            raw = LaunchTracker.sortByFrequency(raw)
        }

        // 构建目标列表
        let target = raw.map(a => ({
            name: a.name,
            icon: a.icon || "",
            appObj: a.appObj,
            appId: a.appObj ? a.appObj.id : (a.name || "")
        }))

        // ── 增量 diff：移除 → 插入 → 移动 ──
        let targetIds = new Set(target.map(t => t.appId))

        // 1) 移除不在目标中的 item（倒序）
        for (let i = filteredAppsModel.count - 1; i >= 0; i--) {
            if (!targetIds.has(filteredAppsModel.get(i).appId)) {
                filteredAppsModel.remove(i)
            }
        }

        // 2) 当前位置快照
        let curPos = {}
        for (let i = 0; i < filteredAppsModel.count; i++) {
            curPos[filteredAppsModel.get(i).appId] = i
        }

        // 3) 插入新 item（按目标顺序）
        for (let ti = 0; ti < target.length; ti++) {
            let tid = target[ti].appId
            if (curPos[tid] === undefined) {
                filteredAppsModel.insert(ti, target[ti])
                for (let id in curPos) {
                    if (curPos[id] >= ti) curPos[id]++
                }
                curPos[tid] = ti
            }
        }

        // 4) 移动已存在的 item 到正确位置（从上到下，逐个归位）
        for (let ti = 0; ti < Math.min(target.length, filteredAppsModel.count); ti++) {
            let expectedId = target[ti].appId
            let ci = -1
            for (let j = ti; j < filteredAppsModel.count; j++) {
                if (filteredAppsModel.get(j).appId === expectedId) {
                    ci = j
                    break
                }
            }
            if (ci >= 0 && ci !== ti) {
                filteredAppsModel.move(ci, ti, 1)
                for (let id in curPos) {
                    if (curPos[id] >= ti && curPos[id] < ci) curPos[id]++
                }
                curPos[expectedId] = ti
            }
        }

        appsList.contentY = 0
        setCurrentIndex(0)
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
                        readonly property string requestedSource: root.iconSource(model.icon)
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
                    text: root.highlightText(model.name, root.query)
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
        showVerticalScrollBar: false

        model: filteredAppsModel
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
        if (filteredAppsModel.count > 0 && appsList.currentIndex >= 0) {
            let appData = filteredAppsModel.get(appsList.currentIndex)
            if (appData && appData.appObj) {
                // Record launch for frequency tracking
                LaunchTracker.recordLaunch(appData.appObj.id)
                appData.appObj.execute()
            }
            root.requestCloseLauncher()
        }
    }
}
