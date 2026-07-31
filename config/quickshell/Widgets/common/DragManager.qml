import QtQuick

// Drag gesture handler for notification swipe-to-dismiss.
// Emits dragDiffX/dragDiffY changes and dragReleased signal.
MouseArea {
    id: root
    property bool interactive: true
    property bool automaticallyReset: true
    property real dragDiffX: 0
    property real dragDiffY: 0

    signal dragReleased(real diffX, real diffY)
    signal draggingChanged()

    enabled: interactive
    drag.target: interactive ? dragProxy : null
    drag.axis: Drag.XAxis

    onPressed: {
        if (!interactive) return;
        dragProxy.x = 0;
        dragDiffX = 0;
        dragDiffY = 0;
        draggingChanged();
    }

    onPositionChanged: {
        if (!interactive || !drag.active) return;
        dragDiffX = dragProxy.x;
        dragDiffY = dragProxy.y;
        draggingChanged();
    }

    onReleased: {
        if (!interactive || !drag.active) return;
        const dx = dragProxy.x;
        const dy = dragProxy.y;
        if (automaticallyReset) {
            dragProxy.x = 0;
            dragDiffX = 0;
            dragDiffY = 0;
        }
        dragReleased(dx, dy);
        draggingChanged();
    }

    Item {
        id: dragProxy
        width: 0; height: 0; visible: false
    }
}
