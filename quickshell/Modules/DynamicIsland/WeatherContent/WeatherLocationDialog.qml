import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import qs.Common
import qs.Widgets.common

Item {
    id: root

    // 填充 WeatherContent 区域，z-index 确保在最上层
    anchors.fill: parent
    z: 100

    // 外部属性
    property bool shouldBeVisible: false
    property string initialCity: ""
    property real initialLat: 0
    property real initialLon: 0
    property bool hasManualLocation: false

    // 信号
    signal saved(string name, real lat, real lon)
    signal cleared()
    signal cancelled()

    // 内部状态
    property bool _cityError: false
    property bool _latError: false
    property bool _lonError: false
    property bool _geocoding: false

    // 正向地理编码：城市名 → 经纬度（Open-Meteo 免费 API）
    function geocodeCity(name) {
        if (!name || _geocoding) return
        _geocoding = true
        const url = "https://geocoding-api.open-meteo.com/v1/search?name="
                  + encodeURIComponent(name) + "&count=1&language=zh&format=json"
        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.timeout = 5000
        xhr.setRequestHeader("User-Agent", "Quickshell-WeatherLocationDialog/1.0")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                _geocoding = false
                if (xhr.status === 200) {
                    try {
                        const data = JSON.parse(xhr.responseText)
                        if (data.results && data.results.length > 0) {
                            const r = data.results[0]
                            latField.text = r.latitude.toFixed(3)
                            lonField.text = r.longitude.toFixed(3)
                            _latError = false
                            _lonError = false
                            geocodeStatus.text = "✓ 已匹配: " + (r.admin1 || r.country || "")
                        } else {
                            geocodeStatus.text = "✗ 未找到该城市"
                        }
                    } catch(e) {
                        geocodeStatus.text = "✗ 解析失败"
                    }
                } else {
                    geocodeStatus.text = "✗ 查询超时"
                }
            }
        }
        geocodeStatus.text = "🔍 查询中…"
        xhr.send()
    }

    // 反向地理编码：经纬度 → 城市名（Nominatim 免费 API）
    function reverseGeocode(lat, lon) {
        if (_geocoding) return
        _geocoding = true
        const url = "https://nominatim.openstreetmap.org/reverse?lat="
                  + lat + "&lon=" + lon + "&format=json&accept-language=zh"
        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.timeout = 5000
        xhr.setRequestHeader("User-Agent", "Quickshell-WeatherLocationDialog/1.0")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                _geocoding = false
                if (xhr.status === 200) {
                    try {
                        const data = JSON.parse(xhr.responseText)
                        if (data.address) {
                            const a = data.address
                            const name = a.city || a.town || a.county || a.state || a.country || ""
                            if (name) {
                                cityField.text = name
                                _cityError = false
                                geocodeStatus.text = "✓ 已匹配: " + name
                            }
                        } else {
                            geocodeStatus.text = "✗ 无法解析位置"
                        }
                    } catch(e) {
                        geocodeStatus.text = "✗ 解析失败"
                    }
                } else {
                    geocodeStatus.text = "✗ 查询超时"
                }
            }
        }
        geocodeStatus.text = "🔍 查询中…"
        xhr.send()
    }

    function open() {
        shouldBeVisible = true;
        Qt.callLater(() => modalContent.forceActiveFocus());
    }

    function close() {
        shouldBeVisible = false;
        _cityError = false;
        _latError = false;
        _lonError = false;
    }

    // 弹窗显示时同步初始值到输入框
    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            cityField.text = root.initialCity;
            latField.text = root.initialLat !== 0 ? String(root.initialLat) : "";
            lonField.text = root.initialLon !== 0 ? String(root.initialLon) : "";
            _cityError = false;
            _latError = false;
            _lonError = false;
        }
    }

    function validateAndSave() {
        _cityError = false;
        _latError = false;
        _lonError = false;

        const name = cityField.text.trim();
        if (name === "") {
            _cityError = true;
            return;
        }

        const lat = parseFloat(latField.text);
        if (isNaN(lat) || lat < -90 || lat > 90) {
            _latError = true;
            return;
        }

        const lon = parseFloat(lonField.text);
        if (isNaN(lon) || lon < -180 || lon > 180) {
            _lonError = true;
            return;
        }

        root.saved(name, lat, lon);
        root.close();
    }

    // 纯 QML 覆盖层，通过 scale/opacity 动画实现弹窗过渡
    Item {
        anchors.fill: parent

        // 半透明背景遮罩 — fade 动画
        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: root.shouldBeVisible ? 1 : 0
            visible: opacity > 0.005

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }

        // 外部点击关闭 — 仅在弹窗可见时生效
        MouseArea {
            anchors.fill: parent
            enabled: root.shouldBeVisible
            onClicked: {
                root.cancelled();
                root.close();
            }
        }

        // 弹窗主体 — scale + fade 组合动画
        FocusScope {
            id: modalContent

            anchors.centerIn: parent
            width: 420
            height: 380
            focus: root.shouldBeVisible

            // 进入：scale 0.92→1 (OutBack 弹性)，opacity 0→1
            // 退出：scale 1→0.95 (OutCubic 回缩)，opacity 1→0
            scale: root.shouldBeVisible ? 1 : 0.92
            opacity: root.shouldBeVisible ? 1 : 0
            visible: opacity > 0.005

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: root.shouldBeVisible ? Easing.OutBack : Easing.OutCubic
                    easing.overshoot: root.shouldBeVisible ? 0.35 : 0
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: root.shouldBeVisible ? 220 : 180
                    easing.type: Easing.OutCubic
                }
            }

            // 阻止点击穿透到遮罩层
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                z: -1
                onPressed: mouse => mouse.accepted = true
                onClicked: mouse => mouse.accepted = true
            }

            Keys.onEscapePressed: event => {
                root.cancelled();
                root.close();
                event.accepted = true;
            }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainerLow
                border.width: 1
                border.color: Appearance.m3colors.m3outlineVariant
            }

            Item {
                anchors.fill: parent
                anchors.margins: 24

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 标题栏
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "设置位置"
                            font.pixelSize: 18
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnSurface
                            font.family: Sizes.fontFamily
                        }

                        Item { Layout.fillWidth: true }

                        // 关闭按钮
                        Item {
                            implicitWidth: 32
                            implicitHeight: 32

                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.full
                                color: closeMouse.containsMouse ? Appearance.colors.colLayer4 : "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 16
                                color: Appearance.colors.colOnSurface
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.cancelled();
                                    root.close();
                                }
                            }
                        }
                    }

                    // 输入区域
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        spacing: 12

                        MaterialTextField {
                            id: cityField
                            Layout.fillWidth: true
                            placeholderText: "城市名称（如：上海）"
                            Material.accent: root._cityError ? Appearance.m3colors.m3error : Appearance.m3colors.m3primary
                            onEditingFinished: {
                                const name = text.trim()
                                if (name !== "" && !root._geocoding)
                                    root.geocodeCity(name)
                            }
                        }

                        MaterialTextField {
                            id: latField
                            Layout.fillWidth: true
                            placeholderText: "纬度（-90 ~ 90）"
                            Material.accent: root._latError ? Appearance.m3colors.m3error : Appearance.m3colors.m3primary
                            onEditingFinished: {
                                const lat = parseFloat(text)
                                const lon = parseFloat(lonField.text)
                                if (!isNaN(lat) && !isNaN(lon) && !root._geocoding
                                    && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180)
                                    root.reverseGeocode(lat, lon)
                            }
                        }

                        MaterialTextField {
                            id: lonField
                            Layout.fillWidth: true
                            placeholderText: "经度（-180 ~ 180）"
                            Material.accent: root._lonError ? Appearance.m3colors.m3error : Appearance.m3colors.m3primary
                            onEditingFinished: {
                                const lat = parseFloat(latField.text)
                                const lon = parseFloat(text)
                                if (!isNaN(lat) && !isNaN(lon) && !root._geocoding
                                    && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180)
                                    root.reverseGeocode(lat, lon)
                            }
                        }
                    }

                    // 地理编码状态提示
                    Text {
                        id: geocodeStatus
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        text: ""
                        font.pixelSize: 11
                        color: root._geocoding ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                        font.family: Sizes.fontFamily
                        visible: text !== ""
                    }

                    Item { Layout.fillHeight: true }

                    // 恢复自动定位
                    DialogActionButton {
                        Layout.alignment: Qt.AlignLeft
                        visible: root.hasManualLocation
                        text: "恢复自动定位"
                        onClicked: {
                            root.cleared();
                            root.close();
                        }
                    }

                    // 底部按钮
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        spacing: 12

                        DialogActionButton {
                            text: "取消"
                            onClicked: {
                                root.cancelled();
                                root.close();
                            }
                        }

                        DialogActionButton {
                            text: "保存"
                            filled: true
                            onClicked: root.validateAndSave()
                        }
                    }
                }
            }
        }
    }
}
