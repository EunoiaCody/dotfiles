pragma Singleton

import QtQuick

QtObject {
    id: root

    property bool qsOpen: false
    property string qsView: "network"
    property string qsScreenName: ""

    // Anchor position for the QuickSettingsPanel popup
    // Set by each button before toggling qsOpen
    property real qsAnchorGlobalX: 0
    property real qsAnchorGlobalY: 0
    property real qsAnchorWidth: 0
    property real qsAnchorHeight: 0

    property bool leftSidebarOpen: false
    property string leftSidebarView: "info"

    onQsOpenChanged: {
        if (!qsOpen)
            qsScreenName = "";
    }

    function closeAllPopups() {
        qsOpen = false;
        leftSidebarOpen = false;
    }
}
