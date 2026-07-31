pragma Singleton

import QtQuick
import Quickshell

// Animations.qml — M3 motion tokens (easing curves + duration constants).
// Note: QML Singleton requires inline property values, not 'curves: QtObject {...}' bindings.

Singleton {
    id: root

    readonly property QtObject curves: QtObject {
        readonly property var emphasized: [0.05, 0, 0.1333, 0.06, 0.1667, 0.4, 0.2083, 0.82, 0.25, 1, 1, 1]
        readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property var standard: [0.2, 0, 0, 1, 1, 1]
        readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property var standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
        readonly property var expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
        readonly property var expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        readonly property var expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
        readonly property var expressiveEffects: expressiveDefaultEffects
        readonly property int expressiveFastSpatialDuration: 350
        readonly property int expressiveDefaultSpatialDuration: 500
        readonly property int expressiveEffectsDuration: 200
        readonly property int emphasizedAccelDuration: 200
        readonly property int standardDecelDuration: 200
    }

    readonly property QtObject durations: QtObject {
        readonly property int small: 200
        readonly property int normal: 400
        readonly property int large: 600
        readonly property int extraLarge: 1000
        readonly property int expressiveFastSpatial: 350
        readonly property int expressiveDefaultSpatial: 500
        readonly property int expressiveSlowSpatial: 650
        readonly property int expressiveFastEffects: 150
        readonly property int expressiveDefaultEffects: 200
        readonly property int expressiveSlowEffects: 300
        readonly property int expressiveEffects: 200
        readonly property int emphasizedAccel: 200
        readonly property int standardDecel: 200
    }

    readonly property QtObject animation: QtObject {
        readonly property QtObject standardSmall: QtObject {
            readonly property int duration: 200
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.standard
        }
        readonly property QtObject standard: QtObject {
            readonly property int duration: 400
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.standard
        }
        readonly property QtObject standardLarge: QtObject {
            readonly property int duration: 600
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.standard
        }
        readonly property QtObject standardExtraLarge: QtObject {
            readonly property int duration: 1000
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.standard
        }
        readonly property QtObject standardAccel: QtObject {
            readonly property int duration: 400
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.standardAccel
        }
        readonly property QtObject standardDecel: QtObject {
            readonly property int duration: 200
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.standardDecel
        }
        readonly property QtObject emphasizedAccel: QtObject {
            readonly property int duration: 200
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.emphasizedAccel
        }
        readonly property QtObject expressiveFastSpatial: QtObject {
            readonly property int duration: 350
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveFastSpatial
        }
        readonly property QtObject expressiveDefaultSpatial: QtObject {
            readonly property int duration: 500
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveDefaultSpatial
        }
        readonly property QtObject expressiveSlowSpatial: QtObject {
            readonly property int duration: 650
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveSlowSpatial
        }
        readonly property QtObject expressiveFastEffects: QtObject {
            readonly property int duration: 150
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveFastEffects
        }
        readonly property QtObject expressiveDefaultEffects: QtObject {
            readonly property int duration: 200
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveDefaultEffects
        }
        readonly property QtObject expressiveSlowEffects: QtObject {
            readonly property int duration: 300
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveSlowEffects
        }
        readonly property QtObject expressiveEffects: QtObject {
            readonly property int duration: 200
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveDefaultEffects
        }
        readonly property QtObject elementMoveFast: QtObject {
            readonly property int duration: 350
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveFastSpatial
        }
        readonly property QtObject elementMove: QtObject {
            readonly property int duration: 500
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveDefaultSpatial
        }
        readonly property QtObject elementResize: QtObject {
            readonly property int duration: 300
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.emphasized
        }
        readonly property QtObject scroll: QtObject {
            readonly property int duration: 200
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.standardDecel
        }
        readonly property QtObject clickBounce: QtObject {
            readonly property int duration: 400
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveDefaultSpatial
        }
    }
}
