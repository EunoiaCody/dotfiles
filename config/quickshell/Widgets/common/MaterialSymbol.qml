import QtQuick

// Material Design icon glyph via Material Symbols font.
// Usage: MaterialSymbol { text: "notifications"; iconSize: 20; color: "white" }
Text {
    id: root
    property real iconSize: 18

    font.family: "Material Symbols Outlined"
    font.pixelSize: root.iconSize
    text: ""
    color: "white"
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
