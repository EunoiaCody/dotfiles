#!/bin/bash
# Wrapper for quickshell: sets env vars for Clavis C++ plugins
# Required because the C++ plugin RPATH points to build directory, not install dir

export QML2_IMPORT_PATH="/home/eunoia/.local/share/qt6/qml:${QML2_IMPORT_PATH:+${QML2_IMPORT_PATH}}"

CLAVIS_DIR="/home/eunoia/.local/share/qt6/qml/Clavis"
# Add all Clavis plugin directories to LD_LIBRARY_PATH for runtime linking
LD_LIBRARY_PATH="${CLAVIS_DIR}/Niri:${CLAVIS_DIR}/Sysmon:${CLAVIS_DIR}/Weather:${CLAVIS_DIR}/Media:${CLAVIS_DIR}/Keyboard:${CLAVIS_DIR}:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH

exec quickshell "$@"
