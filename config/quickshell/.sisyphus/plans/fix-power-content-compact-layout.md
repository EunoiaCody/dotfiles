# Plan: Fix PowerContent to anchor items at the top of the panel

## TL;DR

> **Quick Summary**: The 4 power menu items (锁定/注销/重启/关机) currently appear in the lower-middle of the right sidebar panel instead of right below the title. The fix: replace the `ColumnLayout` wrapper (which uses `Layout.alignment: Qt.AlignTop` — doesn't work because the parent `contentLayout` in WidgetPanel has `Layout.fillHeight: true`) with an `Item` wrapper that uses explicit `anchors.top` positioning.
>
> **Deliverable**: Items appear tightly packed at the top of the panel, right below the "电源" title, with empty transparent space below them.

---

## Problem Analysis

### Current state
- `Modules/Sidebars/Right/PowerContent.qml` wraps the `Repeater` in a `ColumnLayout` with `Layout.alignment: Qt.AlignTop`
- The WidgetPanel's `contentLayout` (in `Widgets/common/WidgetPanel.qml`) has `Layout.fillHeight: true`
- When a child ColumnLayout has `Layout.alignment: Qt.AlignTop` but no `Layout.fillHeight` or `Layout.preferredHeight`, the alignment is unreliable in this scenario — items end up in the lower-middle of the available space instead of pinned to the top

### Visual symptom
- Title "电源" appears at top (y~90)
- Huge empty space from y~110 to y~380
- 4 items (锁定/注销/重启/关机) appear clustered in lower middle (y~380-510)
- Empty space from y~510 to bottom (y~620)

### Root cause
The parent `contentLayout` in WidgetPanel.qml forces `Layout.fillHeight: true`, which interferes with `Layout.alignment: Qt.AlignTop` on a child ColumnLayout that has its own implicit content height. The layout engine treats the child as having extra available space and centers it instead of pinning to the top.

---

## Fix

### File to modify
- `Modules/Sidebars/Right/PowerContent.qml` — replace the `ColumnLayout` wrapper (lines 27-93) with an `Item` wrapper that uses explicit `anchors.top` positioning.

### Why this works
- The `Item` wrapper has `Layout.fillWidth: true; Layout.fillHeight: true` so it takes the full content area
- The `ColumnLayout` inside is anchored to `parent.top` explicitly — no reliance on layout alignment flags
- The `clip: true` on the Item prevents the items from visually overflowing if they ever get larger
- This is a proven pattern in QML when parent layouts have conflicting fillHeight behavior

### Code change

Replace the existing `ColumnLayout { ... }` block (lines 27-93) with:

```qml
Item {
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    ColumnLayout {
        id: itemsColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 4
        }
        spacing: 4

        Repeater {
            model: root.actions

            Rectangle {
                id: menuItem
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 40
                radius: 10
                color: itemMouse.containsMouse
                    ? (modelData.isRed ? Appearance.colors.colError : Appearance.colors.colLayer1)
                    : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Appearance.animation.expressiveEffects.duration; easing.type: Appearance.animation.expressiveEffects.type; easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 14

                    Text {
                        text: menuItem.modelData.icon
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: itemMouse.containsMouse && menuItem.modelData.isRed
                            ? Appearance.colors.colOnError
                            : Appearance.colors.colOnLayer0
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: menuItem.modelData.label
                        font.pixelSize: 14
                        font.family: Sizes.fontFamily
                        color: itemMouse.containsMouse && menuItem.modelData.isRed
                            ? Appearance.colors.colOnError
                            : Appearance.colors.colOnLayer0
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        WidgetState.qsOpen = false;
                        Quickshell.execDetached(menuItem.modelData.cmd[0], menuItem.modelData.cmd.slice(1));
                    }
                }
            }
        }
    }
}
```

### Constraints
- Do NOT change the 4 items, commands, icons, colors, or hover behavior
- Do NOT modify WidgetPanel.qml
- Do NOT modify QuickSettings.qml
- Only the layout wrapper changes — from `ColumnLayout { Layout.alignment: Qt.AlignTop }` to `Item { anchors.top: parent.top }`

---

## Verification

After applying the change:

```bash
# Confirm the file uses Item wrapper
grep -A 2 "Layout.fillWidth: true" /home/eunoia/.config/quickshell/Modules/Sidebars/Right/PowerContent.qml | head -5
# Expected: Item { Layout.fillWidth: true; Layout.fillHeight: true

# Confirm anchors.top is set
grep -n "anchors" /home/eunoia/.config/quickshell/Modules/Sidebars/Right/PowerContent.qml
# Expected: anchors.top: parent.top
```

Then restart quickshell (`/home/eunoia/.config/quickshell/start-quickshell.sh`) and visually verify the 4 items appear right below the "电源" title with no large empty gap.

---

## Success Criteria
- [ ] `PowerContent.qml` uses `Item { Layout.fillWidth: true; Layout.fillHeight: true }` wrapper
- [ ] Inner `ColumnLayout` has `anchors.top: parent.top`
- [ ] Quickshell reloads without errors
- [ ] Visually: 4 items appear at the top of the panel, right below the "电源" title, occupying ~172px of vertical space
- [ ] No large empty gap between title and items
