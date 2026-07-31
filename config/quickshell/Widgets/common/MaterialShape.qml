import QtQuick

// Shaped container used for notification app icons.
// Supports Circle, VerySunny, SoftBurst, Ghostish shapes.
Rectangle {
    id: root

    enum Shape {
        Circle,
        VerySunny,
        SoftBurst,
        Ghostish
    }

    property int shape: MaterialShape.Shape.Circle
    property real implicitSize: 38

    implicitWidth: implicitSize
    implicitHeight: implicitSize
    radius: {
        switch (shape) {
            case MaterialShape.Shape.Circle: return implicitSize / 2;
            case MaterialShape.Shape.VerySunny: return implicitSize * 0.25;
            case MaterialShape.Shape.SoftBurst: return implicitSize * 0.35;
            case MaterialShape.Shape.Ghostish: return implicitSize * 0.15;
            default: return implicitSize / 2;
        }
    }
    color: "transparent"
    clip: true
}
