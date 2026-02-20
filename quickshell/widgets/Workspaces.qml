// ============================================================
// 工作区切换器组件
// 从 SketchyBar spaces.lua 迁移，增强了平滑切换动画
// 通过 niri msg 获取工作区状态
// ============================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    // 当前屏幕（用于过滤工作区）
    property var screen: null

    implicitWidth: workspacesRow.implicitWidth
    implicitHeight: Theme.barHeight

    // 工作区数据列表
    property var workspacesList: []
    // 当前活动工作区 ID
    property int activeWorkspaceId: 1

    // -------------------- 定时轮询 --------------------
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: workspacesProcess.running = true
    }

    Component.onCompleted: workspacesProcess.running = true

    // -------------------- 获取工作区数据 --------------------
    property string wsBuffer: ""

    Process {
        id: workspacesProcess
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: SplitParser {
            onRead: data => {
                root.wsBuffer += data
            }
        }
        onExited: (exitCode) => {
            if (exitCode === 0 && root.wsBuffer.length > 0) {
                try {
                    const parsed = JSON.parse(root.wsBuffer)
                    // 按 idx 排序
                    parsed.sort((a, b) => a.idx - b.idx)

                    // 过滤当前显示器的工作区
                    let filtered = parsed
                    if (root.screen && root.screen.name) {
                        filtered = parsed.filter(ws => ws.output === root.screen.name)
                        if (filtered.length === 0) filtered = parsed
                    }

                    root.workspacesList = filtered
                    // 找到活动工作区
                    for (let i = 0; i < filtered.length; i++) {
                        if (filtered[i].is_focused) {
                            root.activeWorkspaceId = filtered[i].idx
                            break
                        }
                    }
                } catch (e) {
                    // JSON 解析失败，忽略
                }
            }
            root.wsBuffer = ""
        }
    }

    // -------------------- 切换工作区命令 --------------------
    Process {
        id: switchProcess
        command: []
    }

    function switchWorkspace(idx) {
        switchProcess.command = ["niri", "msg", "action", "focus-workspace", String(idx)]
        switchProcess.running = true
    }

    // -------------------- 工作区按钮行 --------------------
    Row {
        id: workspacesRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: root.workspacesList

            // 单个工作区按钮
            Rectangle {
                id: wsButton

                required property var modelData
                required property int index

                width: 28
                height: 28
                radius: Theme.radius

                // 活动工作区使用 Lavender 高亮（与 SketchyBar 一致）
                color: modelData.is_focused ? Theme.lavender : Theme.surface0

                // 平滑颜色过渡动画
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationDuration
                    }
                }

                // 缩放动画
                scale: modelData.is_focused ? 1.0 : 0.9
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animationDuration
                        easing.type: Easing.OutQuad
                    }
                }

                // 工作区编号
                Text {
                    anchors.centerIn: parent
                    text: String(modelData.idx)
                    color: modelData.is_focused ? Theme.base : Theme.overlay1
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: modelData.is_focused

                    // 文字颜色过渡动画
                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animationDuration
                        }
                    }
                }

                // 点击切换工作区
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.switchWorkspace(modelData.idx)
                }
            }
        }
    }
}
