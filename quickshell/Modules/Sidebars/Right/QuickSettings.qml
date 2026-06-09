import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets.common

Item {
    id: root

    property var screen: null

    // Reports the content height of whichever view is currently active.
    // RightSidebar uses this to size the panel (compact for power, full
    // height for the others). Each child Content sets its own
    // contentImplicitHeight; the inactive ones don't matter.
    readonly property real contentImplicitHeight: {
        switch (WidgetState.qsView) {
        case "network":       return networkContent.contentImplicitHeight;
        case "audio":         return audioContent.contentImplicitHeight;
        case "settings":      return settingsContent.contentImplicitHeight;
        case "notifications": return notificationsContent.contentImplicitHeight;
        case "power":         return powerContent.contentImplicitHeight;
        default:              return 640;
        }
    }

    Item {
        anchors.fill: parent
        
        NetworkContent {
            id: networkContent
            anchors.fill: parent
            
            // ============================================================
            // 【核心修复】：将动画控制权收回到 QuickSettings 层
            // ============================================================
            opacity: WidgetState.qsView === "network" ? 1.0 : 0.0
            scale: WidgetState.qsView === "network" ? 1.0 : 0.95
            visible: opacity > 0
            
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
        }

        AudioContent {
            id: audioContent
            anchors.fill: parent
            
            // ============================================================
            // 【核心修复】：在这里独立控制混音器面板的显隐动画
            // ============================================================
            opacity: WidgetState.qsView === "audio" ? 1.0 : 0.0
            scale: WidgetState.qsView === "audio" ? 1.0 : 0.95
            visible: opacity > 0
            
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
        }

        SettingsContent {
            id: settingsContent
            anchors.fill: parent
            screen: root.screen

            opacity: WidgetState.qsView === "settings" ? 1.0 : 0.0
            scale: WidgetState.qsView === "settings" ? 1.0 : 0.95
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
        }

        NotificationsContent {
            id: notificationsContent
            anchors.fill: parent

            opacity: WidgetState.qsView === "notifications" ? 1.0 : 0.0
            scale: WidgetState.qsView === "notifications" ? 1.0 : 0.95
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
        }

        PowerContent {
            id: powerContent
            anchors.fill: parent

            opacity: WidgetState.qsView === "power" ? 1.0 : 0.0
            scale: WidgetState.qsView === "power" ? 1.0 : 0.95
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
        }
    }
}
