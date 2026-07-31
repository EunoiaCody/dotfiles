import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs.Common

// Material ripple button — base for notification actions, group expand, etc.
Button {
    id: root
    property bool toggled: false
    property string buttonText: ""
    property bool pointingHandCursor: true
    property real buttonRadius: Appearance.rounding?.small ?? 4
    property real buttonRadiusPressed: buttonRadius
    property real buttonEffectiveRadius: root.down ? root.buttonRadiusPressed : root.buttonRadius
    property int rippleDuration: 1200
    property bool rippleEnabled: true
    property var downAction      // Called on left press
    property var releaseAction   // Called on left release
    property var altAction       // Called on right click
    property var middleClickAction

    // Default layer colors — override per instance
    property color colBackground: Appearance.colors.colLayer1Hover ?? "transparent"
    property color colBackgroundHover: Appearance.colors.colLayer1Hover ?? "#E5DFED"
    property color colBackgroundToggled: Appearance.colors.colPrimary ?? "#65558F"
    property color colBackgroundToggledHover: Appearance.colors.colPrimaryHover ?? "#77699C"
    property color colRipple: Appearance.colors.colLayer1Active ?? "#D6CEE2"
    property color colRippleToggled: Appearance.colors.colPrimaryActive ?? "#D6CEE2"

    opacity: root.enabled ? 1 : 0.4

    readonly property color buttonColor: root.toggled
        ? (root.hovered ? colBackgroundToggledHover : colBackgroundToggled)
        : (root.hovered ? colBackgroundHover : colBackground)
    readonly property color rippleColor: root.toggled ? colRippleToggled : colRipple

    function startRipple(x, y) {
        const stateY = buttonBackground.y;
        rippleAnim.x = x;
        rippleAnim.y = y - stateY;

        const dist = (ox, oy) => ox * ox + oy * oy;
        const stateEnd = stateY + buttonBackground.height;
        rippleAnim.radius = Math.sqrt(Math.max(
            dist(0, stateY), dist(0, stateEnd),
            dist(width, stateY), dist(width, stateEnd)
        ));

        rippleFadeAnim.complete();
        rippleAnim.restart();
    }

    component RippleAnim: NumberAnimation {
        duration: rippleDuration
        easing.type: Appearance.animation.elementMoveEnter?.type ?? Easing.BezierSpline
        easing.bezierCurve: Appearance.curves?.standardDecel ?? [0, 0, 0, 1, 1, 1]
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.pointingHandCursor ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onPressed: (event) => {
            if (event.button === Qt.RightButton) {
                if (root.altAction) root.altAction(event);
                return;
            }
            if (event.button === Qt.MiddleButton) {
                if (root.middleClickAction) root.middleClickAction();
                return;
            }
            root.down = true;
            if (root.downAction) root.downAction();
            if (!root.rippleEnabled) return;
            const pos = event;
            startRipple(pos.x, pos.y);
        }
        onReleased: (event) => {
            root.down = false;
            if (event.button !== Qt.LeftButton) return;
            if (root.releaseAction) root.releaseAction();
            root.click();
            if (!root.rippleEnabled) return;
            rippleFadeAnim.restart();
        }
        onCanceled: () => {
            root.down = false;
            if (!root.rippleEnabled) return;
            rippleFadeAnim.restart();
        }
    }

    RippleAnim {
        id: rippleFadeAnim
        duration: rippleDuration * 2
        target: ripple
        property: "opacity"
        to: 0
    }

    SequentialAnimation {
        id: rippleAnim
        property real x: 0
        property real y: 0
        property real radius: 0

        PropertyAction { target: ripple; property: "x"; value: rippleAnim.x }
        PropertyAction { target: ripple; property: "y"; value: rippleAnim.y }
        PropertyAction { target: ripple; property: "opacity"; value: 1 }

        ParallelAnimation {
            RippleAnim {
                target: ripple
                properties: "implicitWidth,implicitHeight"
                from: 0
                to: rippleAnim.radius * 2
            }
        }
    }

    background: Rectangle {
        id: buttonBackground
        radius: root.buttonEffectiveRadius
        implicitHeight: 30
        color: root.buttonColor

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: buttonBackground.width
                height: buttonBackground.height
                radius: root.buttonEffectiveRadius
            }
        }

        Item {
            id: ripple
            width: ripple.implicitWidth
            height: ripple.implicitHeight
            opacity: 0
            visible: width > 0 && height > 0

            property real implicitWidth: 0
            property real implicitHeight: 0

            Behavior on opacity {
                ColorAnimation { duration: 200 }
            }

            RadialGradient {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.rippleColor }
                    GradientStop { position: 0.3; color: root.rippleColor }
                    GradientStop { position: 0.5; color: Qt.rgba(
                        root.rippleColor.r, root.rippleColor.g, root.rippleColor.b, 0) }
                }
            }

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }

    contentItem: Text {
        text: root.buttonText
        font.family: Sizes.fontFamily
        font.pixelSize: 14
        color: Appearance.m3colors.m3onBackground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
