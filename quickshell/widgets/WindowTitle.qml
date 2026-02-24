// ============================================================
// 活动窗口标题组件
// 从 SketchyBar front_app.lua 迁移
// 通过 niri msg 获取当前聚焦窗口信息
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    implicitWidth: titleText.implicitWidth + Theme.widgetPadding * 2
    implicitHeight: Theme.barHeight

    // 当前窗口标题
    property string windowTitle: "桌面"
    // 当前应用 ID
    property string appId: ""

    // -------------------- 定时轮询 --------------------
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: windowProcess.running = true
    }

    Component.onCompleted: windowProcess.running = true

    // -------------------- 获取窗口数据 --------------------
    property string windowBuffer: ""

    Process {
        id: windowProcess
        command: ["niri", "msg", "--json", "focused-window"]
        stdout: SplitParser {
            onRead: data => {
                root.windowBuffer += data
            }
        }
        onExited: (exitCode) => {
            if (exitCode === 0 && root.windowBuffer.length > 0) {
                try {
                    const parsed = JSON.parse(root.windowBuffer)
                    if (parsed && parsed.app_id) {
                        root.appId = parsed.app_id
                        root.windowTitle = parsed.title || parsed.app_id
                    } else {
                        root.appId = ""
                        root.windowTitle = "桌面"
                    }
                } catch (e) {
                    root.appId = ""
                    root.windowTitle = "桌面"
                }
            } else {
                root.appId = ""
                root.windowTitle = "桌面"
            }
            root.windowBuffer = ""
        }
    }

    // -------------------- 显示 --------------------
    Text {
        id: titleText
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.widgetPadding

        // 显示应用名称（截断过长标题）
        text: root.windowTitle
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true

        // 最大宽度限制
        elide: Text.ElideRight
        maximumLineCount: 1
        width: Math.min(implicitWidth, 300)
    }
}
