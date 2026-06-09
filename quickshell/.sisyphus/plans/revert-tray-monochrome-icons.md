# Plan: Revert System Tray Icons to Original Colors

## TL;DR

> **Quick Summary**: Disable the `monochromeIcons` setting in the tray config so the system tray icons display in their original colors instead of a single highlight color.
>
> **Deliverable**: Tray icons rendered with their native app colors
>
> **Estimated Effort**: Quick (single config change)
>
> **Critical Path**: Edit `tray.json` → restart quickshell

---

## Context

### Original Request
The user reports that all system tray icons (e.g., the bar at the top of the screen) are now rendered in a single "highlight" color (colOnSurface), and wants them reverted to their original multi-color appearance.

### Investigation Findings

1. **Render path** (`/home/eunoia/.config/quickshell/Modules/Bar/Tray/TrayItem.qml`):
   - When `TrayService.monochromeIcons` is `false`, the native `IconImage` from the system tray is displayed directly (line 86-96)
   - When `monochromeIcons` is `true`, a `Loader` activates that renders the icon through a `Desaturate` + `ColorOverlay` chain, tinting everything with `Appearance.colors.colOnSurface` (line 98-136)

2. **Config state** (`/home/eunoia/.cache/quickshell/tray.json`):
   ```json
   {
     "monochromeIcons": true,   ← root cause
     ...
   }
   ```
   The property is persisted in this file and defaults to `false` in the code.

3. **Loader mechanism** (`/home/eunoia/.config/quickshell/Services/TrayService.qml`):
   - The `FileView` for `tray.json` does NOT have `watchChanges: true` — external edits are not hot-reloaded.
   - A quickshell restart is required after the config change for the new value to take effect.

---

## Work Objectives

### Core Objective
Set `monochromeIcons: false` so the Loader is deactivated and the native system tray icons are rendered.

### Definition of Done
- [ ] `~/.cache/quickshell/tray.json` contains `"monochromeIcons": false`
- [ ] After quickshell restart, tray icons display in their original (non-monochrome) colors
- [ ] Visual verification: icons in the Bar's tray area match the colors of their source apps (e.g., the Telegram icon shows its native blue, etc.)

### Must NOT Have
- No other fields in `tray.json` should be modified
- No QML source files should be edited (the rendering logic is correct, only the config value is wrong)

---

## TODOs

- [ ] 1. Flip `monochromeIcons` to `false` and restart quickshell

  **What to do**:
  - Edit `/home/eunoia/.cache/quickshell/tray.json`: change `"monochromeIcons": true` to `"monochromeIcons": false`
  - Restart quickshell (e.g., `killall qs; /home/eunoia/.config/quickshell/start-quickshell.sh &` or however the user normally restarts it)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none
  - **Reason**: Single-line config edit, no domain expertise needed

  **References**:
  - `/home/eunoia/.cache/quickshell/tray.json` (lines 2) — the only field to change
  - `/home/eunoia/.config/quickshell/Services/TrayService.qml` (line 16) — confirms default is `false`
  - `/home/eunoia/.config/quickshell/Modules/Bar/Tray/TrayItem.qml` (lines 86-136) — confirms render path is toggled by this single property

  **Acceptance Criteria**:
  - [ ] `grep '"monochromeIcons"' ~/.cache/quickshell/tray.json` → outputs `"monochromeIcons": false,`
  - [ ] After restart, visible screenshot/visual check of the Bar's tray region shows icons in their original multi-color appearance (not all colOnSurface)

  **QA Scenarios**:

  ```
  Scenario: Config value is now false
    Tool: Bash (grep)
    Steps:
      1. grep '"monochromeIcons"' /home/eunoia/.cache/quickshell/tray.json
    Expected Result: A line containing "monochromeIcons": false
    Failure Indicators: Output still shows "monochromeIcons": true
    Evidence: inline command output
  ```

  **Commit**: NO
  - This is a user runtime config (in `~/.cache/`), not a tracked file. No commit needed.

---

## Final Verification Wave

Single-task change — user can visually confirm by looking at the Bar's tray area after restart. No formal F1-F4 review wave needed for a 1-line config flip.

---

## Success Criteria

### Verification Commands
```bash
grep '"monochromeIcons"' /home/eunoia/.cache/quickshell/tray.json  # Expected: "monochromeIcons": false,
```

### Final Checklist
- [ ] `tray.json` shows `monochromeIcons: false`
- [ ] Quickshell restarted
- [ ] Tray icons display in original colors
