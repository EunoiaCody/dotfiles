import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

// Full wallpaper background with 7 GLSL shader transition effects.
// Transitions: fade, wipe, disc, stripes, iris bloom, pixelate, portal.
// Renders on the Background layer of each screen so other panels can sit on top.

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: wallpaperWindow

        required property var modelData

        screen: modelData
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "clavis-wallpaper"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        mask: Region {
            item: Item {}
        }

        Item {
            id: root

            anchors.fill: parent

            property int serviceRevision: WallpaperService.revision
            property int settingsRevision: WallpaperService.settingsRevision
            readonly property string targetSource: serviceRevision >= 0 ? WallpaperService.wallpaperForScreen(modelData.name) : ""
            readonly property int targetFillMode: settingsRevision >= 0 ? WallpaperService.qtFillMode(WallpaperService.fillModeForScreen(modelData.name)) : Image.PreserveAspectCrop
            readonly property real shaderFillMode: settingsRevision >= 0 ? WallpaperService.shaderFillMode(WallpaperService.fillModeForScreen(modelData.name)) : 2
            readonly property string targetTransitionType: settingsRevision >= 0 ? PersonalizationConfig.wallpaperTransitionType : "fade"
            readonly property var targetIncludedTransitions: settingsRevision >= 0 ? PersonalizationConfig.includedTransitions : []
            readonly property int targetTransitionDurationMs: settingsRevision >= 0 ? PersonalizationConfig.transitionDurationMs : 1000
            readonly property string targetTransitionEasingMode: settingsRevision >= 0 ? PersonalizationConfig.transitionEasingMode : "customBezier"
            readonly property var targetTransitionBezierCurve: settingsRevision >= 0 ? PersonalizationConfig.transitionBezierCurve : [0.43, 1.19, 1.0, 0.4, 1.0, 1.0]
            readonly property int textureWidth: Math.min(Math.max(1, Math.round(modelData.width)), 8192)
            readonly property int textureHeight: Math.min(Math.max(1, Math.round(modelData.height)), 8192)

            property string currentSource: ""
            property string nextSource: ""
            property string activeTransition: "none"
            property real transitionProgress: 0
            property bool effectActive: false
            property bool useNextForEffect: false
            property string pendingSource: ""
            property vector4d fillColor: Qt.vector4d(0, 0, 0, 1)
            property real edgeSmoothness: 0.1
            property real wipeDirection: 0
            property real discCenterX: 0.5
            property real discCenterY: 0.5
            property real stripesCount: 16
            property real stripesAngle: 0
            property int activeTransitionDurationMs: 1000
            property int activeTransitionEasingType: Easing.BezierSpline
            property var activeTransitionBezierCurve: [0.43, 1.19, 1.0, 0.4, 1.0, 1.0]

            function imageUrl(path) {
                return path && path !== "" ? Paths.fileUrl(path) : "";
            }

            function isColorSource(path) {
                return /^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$/.test(String(path || ""));
            }

            function chooseTransition() {
                let transition = root.targetTransitionType;
                if (transition !== "random")
                    return transition;

                const included = root.targetIncludedTransitions;
                if (!included || included.length === 0)
                    return "fade";
                return included[Math.floor(Math.random() * included.length)];
            }

            function easingType(mode) {
                switch (mode) {
                case "linear":
                    return Easing.Linear;
                case "quad":
                    return Easing.InOutQuad;
                case "cubic":
                    return Easing.InOutCubic;
                case "quart":
                    return Easing.InOutQuart;
                case "quint":
                    return Easing.InOutQuint;
                case "sine":
                    return Easing.InOutSine;
                case "expo":
                    return Easing.InOutExpo;
                case "circ":
                    return Easing.InOutCirc;
                case "customBezier":
                default:
                    return Easing.BezierSpline;
                }
            }

            function setImmediate(path) {
                transitionAnimation.stop();
                root.currentSource = path || "";
                root.nextSource = "";
                root.pendingSource = "";
                root.activeTransition = "none";
                root.transitionProgress = 0;
                root.effectActive = false;
                root.useNextForEffect = false;
            }

            function prepareTransition(type) {
                switch (type) {
                case "wipe":
                    root.wipeDirection = Math.random() * 4;
                    break;
                case "disc":
                case "pixelate":
                case "portal":
                    root.discCenterX = Math.random();
                    root.discCenterY = Math.random();
                    break;
                case "stripes":
                    root.stripesCount = Math.round(Math.random() * 20 + 4);
                    root.stripesAngle = Math.random() * 360;
                    break;
                }
            }

            function startTransition() {
                root.activeTransitionDurationMs = root.targetTransitionDurationMs;
                root.activeTransitionEasingType = root.easingType(root.targetTransitionEasingMode);
                root.activeTransitionBezierCurve = root.targetTransitionEasingMode === "customBezier"
                    ? root.targetTransitionBezierCurve
                    : [0, 0, 1, 1, 1, 1];
                root.effectActive = true;
                root.useNextForEffect = true;
                transitionDelayTimer.restart();
            }

            function requestWallpaper(path, immediate) {
                if (!path || path === "") {
                    setImmediate("");
                    return;
                }

                if (path === root.currentSource && !root.nextSource)
                    return;

                if (root.isColorSource(path) || root.isColorSource(root.currentSource) || root.currentSource === "" || immediate || root.targetTransitionType === "none" || root.targetTransitionDurationMs <= 0) {
                    setImmediate(path);
                    return;
                }

                if (transitionAnimation.running || root.effectActive) {
                    root.pendingSource = path;
                    return;
                }

                root.activeTransition = chooseTransition();
                if (root.activeTransition === "none") {
                    setImmediate(path);
                    return;
                }

                prepareTransition(root.activeTransition);
                root.transitionProgress = 0;
                root.nextSource = path;
                if (nextImage.status === Image.Ready)
                    startTransition();
            }

            onTargetSourceChanged: requestWallpaper(targetSource, false)

            Component.onCompleted: requestWallpaper(targetSource, true)

            Rectangle {
                anchors.fill: parent
                color: root.currentSource
                visible: root.isColorSource(root.currentSource)
            }

            Image {
                id: currentImage

                anchors.fill: parent
                source: !root.isColorSource(root.currentSource) ? root.imageUrl(root.currentSource) : ""
                fillMode: root.targetFillMode
                asynchronous: true
                cache: true
                retainWhileLoading: true
                smooth: true
                visible: source !== "" && !root.isColorSource(root.currentSource)
                sourceSize: Qt.size(root.textureWidth, root.textureHeight)
            }

            Image {
                id: nextImage

                anchors.fill: parent
                source: !root.isColorSource(root.nextSource) ? root.imageUrl(root.nextSource) : ""
                fillMode: root.targetFillMode
                asynchronous: true
                cache: true
                retainWhileLoading: true
                smooth: true
                visible: source !== "" && !root.isColorSource(root.nextSource)
                sourceSize: Qt.size(root.textureWidth, root.textureHeight)

                onStatusChanged: {
                    if (status === Image.Ready && root.nextSource !== "" && !transitionAnimation.running && root.effectActive === false)
                        root.startTransition();
                }
            }

            ShaderEffectSource {
                id: srcCurrent

                sourceItem: root.effectActive ? currentImage : null
                hideSource: root.effectActive
                live: root.effectActive
                mipmap: false
                recursive: false
                textureSize: Qt.size(root.textureWidth, root.textureHeight)
            }

            ShaderEffectSource {
                id: srcNext

                sourceItem: root.effectActive ? nextImage : null
                hideSource: root.effectActive
                live: root.effectActive
                mipmap: false
                recursive: false
                textureSize: Qt.size(root.textureWidth, root.textureHeight)
            }

            Loader {
                id: effectLoader

                anchors.fill: parent
                active: root.effectActive

                function transitionComponent(type) {
                    switch (type) {
                    case "wipe":
                        return wipeComp;
                    case "disc":
                        return discComp;
                    case "stripes":
                        return stripesComp;
                    case "iris bloom":
                        return irisComp;
                    case "pixelate":
                        return pixelateComp;
                    case "portal":
                        return portalComp;
                    case "fade":
                    default:
                        return fadeComp;
                    }
                }

                sourceComponent: transitionComponent(root.activeTransition)
            }

            Component {
                id: fadeComp

                ShaderEffect {
                    anchors.fill: parent
                    property variant source1: srcCurrent
                    property variant source2: srcNext
                    property real progress: root.transitionProgress
                    property real fillMode: root.shaderFillMode
                    property vector4d fillColor: root.fillColor
                    property real imageWidth1: root.width
                    property real imageHeight1: root.height
                    property real imageWidth2: root.width
                    property real imageHeight2: root.height
                    property real screenWidth: root.width
                    property real screenHeight: root.height
                    fragmentShader: Qt.resolvedUrl("../../assets/shaders/wallpaper/qsb/wp_fade.frag.qsb")
                }
            }

            Component {
                id: wipeComp

                ShaderEffect {
                    anchors.fill: parent
                    property variant source1: srcCurrent
                    property variant source2: srcNext
                    property real progress: root.transitionProgress
                    property real smoothness: root.edgeSmoothness
                    property real direction: root.wipeDirection
                    property real fillMode: root.shaderFillMode
                    property vector4d fillColor: root.fillColor
                    property real imageWidth1: root.width
                    property real imageHeight1: root.height
                    property real imageWidth2: root.width
                    property real imageHeight2: root.height
                    property real screenWidth: root.width
                    property real screenHeight: root.height
                    fragmentShader: Qt.resolvedUrl("../../assets/shaders/wallpaper/qsb/wp_wipe.frag.qsb")
                }
            }

            Component {
                id: discComp

                ShaderEffect {
                    anchors.fill: parent
                    property variant source1: srcCurrent
                    property variant source2: srcNext
                    property real progress: root.transitionProgress
                    property real smoothness: root.edgeSmoothness
                    property real aspectRatio: root.width / Math.max(1, root.height)
                    property real centerX: root.discCenterX
                    property real centerY: root.discCenterY
                    property real fillMode: root.shaderFillMode
                    property vector4d fillColor: root.fillColor
                    property real imageWidth1: root.width
                    property real imageHeight1: root.height
                    property real imageWidth2: root.width
                    property real imageHeight2: root.height
                    property real screenWidth: root.width
                    property real screenHeight: root.height
                    fragmentShader: Qt.resolvedUrl("../../assets/shaders/wallpaper/qsb/wp_disc.frag.qsb")
                }
            }

            Component {
                id: stripesComp

                ShaderEffect {
                    anchors.fill: parent
                    property variant source1: srcCurrent
                    property variant source2: srcNext
                    property real progress: root.transitionProgress
                    property real smoothness: root.edgeSmoothness
                    property real aspectRatio: root.width / Math.max(1, root.height)
                    property real stripeCount: root.stripesCount
                    property real angle: root.stripesAngle
                    property real fillMode: root.shaderFillMode
                    property vector4d fillColor: root.fillColor
                    property real imageWidth1: root.width
                    property real imageHeight1: root.height
                    property real imageWidth2: root.width
                    property real imageHeight2: root.height
                    property real screenWidth: root.width
                    property real screenHeight: root.height
                    fragmentShader: Qt.resolvedUrl("../../assets/shaders/wallpaper/qsb/wp_stripes.frag.qsb")
                }
            }

            Component {
                id: irisComp

                ShaderEffect {
                    anchors.fill: parent
                    property variant source1: srcCurrent
                    property variant source2: srcNext
                    property real progress: root.transitionProgress
                    property real smoothness: root.edgeSmoothness
                    property real centerX: 0.5
                    property real centerY: 0.5
                    property real aspectRatio: root.width / Math.max(1, root.height)
                    property real fillMode: root.shaderFillMode
                    property vector4d fillColor: root.fillColor
                    property real imageWidth1: root.width
                    property real imageHeight1: root.height
                    property real imageWidth2: root.width
                    property real imageHeight2: root.height
                    property real screenWidth: root.width
                    property real screenHeight: root.height
                    fragmentShader: Qt.resolvedUrl("../../assets/shaders/wallpaper/qsb/wp_iris_bloom.frag.qsb")
                }
            }

            Component {
                id: pixelateComp

                ShaderEffect {
                    anchors.fill: parent
                    property variant source1: srcCurrent
                    property variant source2: srcNext
                    property real progress: root.transitionProgress
                    property real smoothness: root.edgeSmoothness
                    property real fillMode: root.shaderFillMode
                    property vector4d fillColor: root.fillColor
                    property real imageWidth1: root.width
                    property real imageHeight1: root.height
                    property real imageWidth2: root.width
                    property real imageHeight2: root.height
                    property real screenWidth: root.width
                    property real screenHeight: root.height
                    property real centerX: root.discCenterX
                    property real centerY: root.discCenterY
                    property real aspectRatio: root.width / Math.max(1, root.height)
                    fragmentShader: Qt.resolvedUrl("../../assets/shaders/wallpaper/qsb/wp_pixelate.frag.qsb")
                }
            }

            Component {
                id: portalComp

                ShaderEffect {
                    anchors.fill: parent
                    property variant source1: srcCurrent
                    property variant source2: srcNext
                    property real progress: root.transitionProgress
                    property real smoothness: root.edgeSmoothness
                    property real aspectRatio: root.width / Math.max(1, root.height)
                    property real centerX: root.discCenterX
                    property real centerY: root.discCenterY
                    property real fillMode: root.shaderFillMode
                    property vector4d fillColor: root.fillColor
                    property real imageWidth1: root.width
                    property real imageHeight1: root.height
                    property real imageWidth2: root.width
                    property real imageHeight2: root.height
                    property real screenWidth: root.width
                    property real screenHeight: root.height
                    fragmentShader: Qt.resolvedUrl("../../assets/shaders/wallpaper/qsb/wp_portal.frag.qsb")
                }
            }

            Timer {
                id: transitionDelayTimer

                interval: 16
                repeat: false
                onTriggered: transitionAnimation.restart()
            }

            NumberAnimation {
                id: transitionAnimation

                target: root
                property: "transitionProgress"
                from: 0
                to: 1
                duration: root.activeTransitionDurationMs
                easing.type: root.activeTransitionEasingType
                easing.bezierCurve: root.activeTransitionBezierCurve
                onFinished: {
                    root.currentSource = root.nextSource;
                    root.nextSource = "";
                    root.transitionProgress = 0;
                    root.effectActive = false;
                    root.useNextForEffect = false;

                    if (root.pendingSource !== "") {
                        const pending = root.pendingSource;
                        root.pendingSource = "";
                        Qt.callLater(() => root.requestWallpaper(pending, false));
                    }
                }
            }
        }
    }
}
