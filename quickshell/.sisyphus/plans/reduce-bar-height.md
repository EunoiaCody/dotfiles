# Plan: Reduce Bar Section implicitHeight (Smaller Pills)

## TL;DR

> **Quick Summary**: Reduce the `implicitHeight` of the three bar section components (Workspaces, Tray, SysMonitor) from 36 → 32, making the bar pills smaller and more compact.
>
> **Deliverable**: Smaller bar pill heights, more compact bar appearance
>
> **Estimated Effort**: Quick (3-line change)
>
> **Critical Path**: Edit 3 QML files → restart quickshell

---

## Context

### Original Request
The bar takes up too much vertical space, and there is some empty whitespace. The user prefers reducing the `implicitHeight` of the bottom-anchored section items rather than changing the global `barHeight` constant (which would also affect the right sidebar's `panelTopMargin` and the launcher's `verticalCenterOffset`).

### Investigation Findings

The three components that define the visible bar pill height all set `implicitHeight: 36`:

1. **`/home/eunoia/.config/quickshell/Modules/Bar/Workspaces/Workspaces.qml:15`**
   ```qml
   implicitHeight: 36
   ```

2. **`/home/eunoia/.config/quickshell/Modules/Bar/Tray/Tray.qml:29`**
   ```qml
   implicitHeight: 36
   ```

3. **`/home/eunoia/.config/quickshell/Modules/Bar/SysMonitor/SysMonitor.qml:16`**
   ```qml
   implicitHeight: 36
   ```

These components are anchored with `anchors.bottom: parent.bottom` inside the `barContent` (44px tall) in `Bar.qml`, so they sit at the bottom of the bar with 8px of empty space above.

### Why Not Just Reduce `barHeight`?
- `Sizes.barHeight` is also consumed by:
  - `Modules/Sidebars/Right/RightSidebar.qml:17` (`panelTopMargin: Sizes.barHeight`)
  - `Modules/Launcher/LauncherWindow.qml:163` (`anchors.verticalCenterOffset: Sizes.barHeight / 2`)
- Changing `barHeight` is a "global" change that affects the sidebar/launcher positioning math.
- Reducing just the section `implicitHeight` keeps the bar's panel height unchanged but makes the visible pills smaller, giving a more compact look without touching the layout math.

---

## Work Objectives

### Core Objective
Reduce the visible pill height of the three bar sections from 36 → 32, making the bar more compact.

### Definition of Done
- [ ] All three components have `implicitHeight: 32`
- [ ] After quickshell restart, bar pills are visibly shorter (4px less)
- [ ] Content within each pill (workspace dots, tray icons, sysmon text) remains readable and well-proportioned
- [ ] The bar's overall panel height (44px) is unchanged, but the empty top space is larger — this is the expected trade-off for not touching `Sizes.barHeight`

### Must NOT Have
- `Sizes.barHeight` must NOT be changed (would affect sidebar/launcher positioning)
- `Bar.qml` layout structure must NOT be changed
- Other properties in the three component files must NOT be changed (only the `implicitHeight` line)

---

## TODOs

- [ ] 1. Reduce `implicitHeight` from 36 → 32 in Workspaces.qml, Tray.qml, SysMonitor.qml

  **What to do**:
  - Edit `/home/eunoia/.config/quickshell/Modules/Bar/Workspaces/Workspaces.qml:15`: change `implicitHeight: 36` to `implicitHeight: 32`
  - Edit `/home/eunoia/.config/quickshell/Modules/Bar/Tray/Tray.qml:29`: change `implicitHeight: 36` to `implicitHeight: 32`
  - Edit `/home/eunoia/.config/quickshell/Modules/Bar/SysMonitor/SysMonitor.qml:16`: change `implicitHeight: 36` to `implicitHeight: 32`
  - Restart quickshell

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none
  - **Reason**: 3-line change, all in the same module, trivial

  **References**:
  - `/home/eunoia/.config/quickshell/Modules/Bar/Workspaces/Workspaces.qml:15`
  - `/home/eunoia/.config/quickshell/Modules/Bar/Tray/Tray.qml:29`
  - `/home/eunoia/.config/quickshell/Modules/Bar/SysMonitor/SysMonitor.qml:16`
  - `/home/eunoia/.config/quickshell/Modules/Bar/Bar.qml:46-75` — confirms RowLayout uses `implicitHeight` for sizing

  **Acceptance Criteria**:
  - [ ] `grep -n "implicitHeight: 32" /home/eunoia/.config/quickshell/Modules/Bar/{Workspaces,Tray,SysMonitor}/*/Workspaces.qml /home/eunoia/.config/quickshell/Modules/Bar/Tray/Tray.qml /home/eunoia/.config/quickshell/Modules/Bar/SysMonitor/SysMonitor.qml` returns 3 matching lines
  - [ ] After restart, the bar pills are visibly shorter (4px less per pill)
  - [ ] No content within the pills is clipped

  **QA Scenarios**:

  ```
  Scenario: All three implicitHeight values changed to 32
    Tool: Bash (grep)
    Steps:
      1. grep -n "implicitHeight: 32" /home/eunoia/.config/quickshell/Modules/Bar/Workspaces/Workspaces.qml /home/eunoia/.config/quickshell/Modules/Bar/Tray/Tray.qml /home/eunoia/.config/quickshell/Modules/Bar/SysMonitor/SysMonitor.qml
    Expected Result: 3 lines, one per file
    Failure Indicators: 0 lines (none changed) or fewer than 3 (some missed)
    Evidence: inline command output
  ```

  ```
  Scenario: Bar pills are shorter after restart
    Tool: visual inspection
    Preconditions: quickshell restarted
    Steps:
      1. Look at the top bar of the screen
    Expected Result: The three pill sections (workspaces, tray/sysmon, quicksettings) appear shorter
    Failure Indicators: Pills are still the same height as before, or content is clipped
  ```

  **Commit**: NO
  - Personal config tweak.

---

## Final Verification Wave

Three-line change in 3 sibling files. User can visually confirm. No formal F1-F4 review needed.

---

## Success Criteria

### Verification Commands
```bash
grep -n "implicitHeight: 32" /home/eunoia/.config/quickshell/Modules/Bar/Workspaces/Workspaces.qml /home/eunoia/.config/quickshell/Modules/Bar/Tray/Tray.qml /home/eunoia/.config/quickshell/Modules/Bar/SysMonitor/SysMonitor.qml
# Expected: 3 lines, each showing implicitHeight: 32
```

### Final Checklist
- [ ] All three `implicitHeight` values changed to 32
- [ ] Quickshell restarted
- [ ] Pills visibly shorter
- [ ] No content clipped

---

## Alternative Values

If 32 looks too cramped or too loose:
- `implicitHeight: 30` (more aggressive, very compact)
- `implicitHeight: 34` (gentler reduction)

User can tweak in 2px increments.
