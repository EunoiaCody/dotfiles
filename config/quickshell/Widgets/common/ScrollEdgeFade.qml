import QtQuick

// Fade effect on the edges of a Flickable when content is scrollable.
Rectangle {
    id: root
    required property var target  // The Flickable to observe
    property bool vertical: true
    property bool horizontal: false

    anchors.fill: target
    color: "transparent"

    gradient: Gradient {
        // Top fade
        GradientStop {
            position: 0.0
            color: vertical && target && target.contentY > 0
                ? Qt.rgba(0, 0, 0, 0.15) : "transparent"
        }
        GradientStop {
            position: vertical ? 0.05 : 0.0
            color: "transparent"
        }
        // Bottom fade
        GradientStop {
            position: vertical ? 0.95 : 1.0
            color: "transparent"
        }
        GradientStop {
            position: 1.0
            color: vertical && target
                && target.contentY + target.height < target.contentHeight - 1
                ? Qt.rgba(0, 0, 0, 0.15) : "transparent"
        }
    }
}
