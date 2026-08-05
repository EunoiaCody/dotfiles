#!/bin/bash
# Wrapper for quickshell: sets env vars for Clavis C++ plugins
# Required because the C++ plugin RPATH points to build directory, not install dir

export QML2_IMPORT_PATH="/home/eunoia/.local/share/qt6/qml:${QML2_IMPORT_PATH:+${QML2_IMPORT_PATH}}"

# 使用 gtk3 平台主题：让 Qt 通过 gsettings 解析图标主题（Tela-dracula-dark 等），
# 否则 QIcon::fromTheme 全部失败，托盘图标/通知图标会报
# "Could not load icon ... from request" 并显示缺失占位图
# （允许用户已设置的值覆盖）
export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-gtk3}"

# 静音 Qt 向 xdg-desktop-portal 注册 app ID 的冗余警告：
# "Failed to register with host portal ... Connection already associated with an application ID"
# 每次启动必现但无功能影响；本配置不使用 QDesktopServices，该分类无其他有用警告
# （若日后需要 openUrl 失败信息可移除）
export QT_LOGGING_RULES="${QT_LOGGING_RULES:+${QT_LOGGING_RULES};}qt.qpa.services.warning=false"

CLAVIS_DIR="/home/eunoia/.local/share/qt6/qml/Clavis"
# Add all Clavis plugin directories to LD_LIBRARY_PATH for runtime linking
LD_LIBRARY_PATH="${CLAVIS_DIR}/Niri:${CLAVIS_DIR}/Sysmon:${CLAVIS_DIR}/Weather:${CLAVIS_DIR}/Media:${CLAVIS_DIR}/Keyboard:${CLAVIS_DIR}:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH

exec quickshell "$@"
