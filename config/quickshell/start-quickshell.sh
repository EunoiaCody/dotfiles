#!/bin/bash
# Wrapper for quickshell: sets env vars for Clavis C++ plugins + M3Shapes
# 采用 StatIndet HEAD 为底座：新版 Clavis 插件（qml-next）优先。

# 新版 Clavis 插件优先，其次旧版，最后 M3Shapes
export QML2_IMPORT_PATH="/home/eunoia/.local/share/qt6/qml-next:/home/eunoia/.local/share/qt6/qml:/home/eunoia/.local/lib/qt6/qml:${QML2_IMPORT_PATH:+${QML2_IMPORT_PATH}}"

# 使用 gtk3 平台主题（图标主题解析），允许用户覆盖
export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-gtk3}"

# 静音 Qt 向 xdg-desktop-portal 注册的冗余警告
export QT_LOGGING_RULES="${QT_LOGGING_RULES:+${QT_LOGGING_RULES};}qt.qpa.services.warning=false"

CLAVIS_NEXT_DIR="/home/eunoia/.local/share/qt6/qml-next/Clavis"
CLAVIS_DIR="/home/eunoia/.local/share/qt6/qml/Clavis"
LD_LIBRARY_PATH="${HOME}/.local/lib:${CLAVIS_NEXT_DIR}/Cava:${CLAVIS_NEXT_DIR}/WeatherMap:${CLAVIS_NEXT_DIR}/Runtime:${CLAVIS_NEXT_DIR}/Files:${CLAVIS_NEXT_DIR}/Gamma:${CLAVIS_NEXT_DIR}/I18n:${CLAVIS_NEXT_DIR}/Lyrics:${CLAVIS_NEXT_DIR}/WindowPreview:${CLAVIS_NEXT_DIR}/DesktopCards:${CLAVIS_NEXT_DIR}/Niri:${CLAVIS_NEXT_DIR}/Media:${CLAVIS_NEXT_DIR}/Weather:${CLAVIS_NEXT_DIR}/Keyboard:${CLAVIS_DIR}/Niri:${CLAVIS_DIR}/Sysmon:${CLAVIS_DIR}/Weather:${CLAVIS_DIR}/Media:${CLAVIS_DIR}/Keyboard:${CLAVIS_DIR}:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH

exec quickshell "$@"
