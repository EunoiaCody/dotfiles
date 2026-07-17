# Plan: Migrate PowerButton to RightSidebar Pattern

## TL;DR

> **Quick Summary**: Move the power menu from a standalone `PowerMenu.qml` popup (launched by `PowerButton`) into the unified `RightSidebar` system, matching the pattern already used by Network, Audio, Settings, and Notifications. Create a new `PowerContent.qml` view and switch `PowerButton` to set `WidgetState.qsView = "power"`.
>
> **Deliverable**: Clicking the power button opens the power menu inside the RightSidebar (consistent with network/notifications), removing the duplicate floating popup.
>
> **Estimated Effort**: Quick (4 files touched, 1 new file)
>
> **Critical Path**: Create PowerContent → register in QuickSettings → rewire PowerButton → delete old PowerMenu → restart

---

## Context

### Original Request
之前网络和通知的展开窗口改好了 (network/notification expanded windows were migrated to RightSidebar), 但是忘记还有电源的窗口没有改 (but the power window was missed), 现在也请你参考远程仓库修改 (now also migrate it referencing the remote repo).

### Current State

| File | Role | Pattern |
|------|------|---------|
| `Bar/QuickSettings/Network.qml` | Button | Sets `WidgetState.qsView = "network"` |
| `Bar/QuickSettings/NotificationButton.qml` | Button | Sets `WidgetState.qsView = "notifications"` |
| `Bar/QuickSettings/PowerButton.qml` | Button | Opens standalone `PowerMenu.qml` popup |
| `Bar/QuickSettings/PowerMenu.qml` | Popup | Full-screen `PanelWindow` with menu items |
| `Sidebars/Right/NetworkContent.qml` | Sidebar view | Renders when `qsView === "network"` |
| `Sidebars/Right/NotificationsContent.qml` | Sidebar view | Renders when `qsView === "notifications"` |
| `Sidebars/Right/SettingsContent.qml` | Sidebar view | Renders when `qsView === "settings"` |
| `Sidebars/Right/AudioContent.qml` | Sidebar view | Renders when `qsView === "audio"` |
| `Sidebars/Right/QuickSettings.qml` | Container | Holds all 4 views, animates opacity/scale |

`PowerButton` is the **only** QuickSettings button that still uses the legacy floating-popup pattern. The other three migrated to the RightSidebar cleanly.

### Reference: Remote Repo
- `/tmp/opencode/remote-quickshell/Modules/Bar/QuickSettings/PowerButton.qml` uses `wlogout` directly (no custom popup)
- `/tmp/opencode/remote-quickshell/Modules/Sidebars/Right/SettingsContent.qml:214-221` has a "会话" (session) `QuickToggleButton` that calls `wlogout` — this is the remote's approach

The local user has a custom `PowerMenu.qml` with 4 items (锁定/注销/重启/关机) that they want preserved. The migration goal is to keep those 4 items but show them in the RightSidebar instead of a separate floating popup.

---

## Work Objectives

### Core Objective
Make the power button open its menu inside the RightSidebar, matching the pattern of network/notification. Keep the existing 4 items (lock/logout/reboot/shutdown) but display them in a new `PowerContent.qml` view.

### Definition of Done
- [ ] New file `Modules/Sidebars/Right/PowerContent.qml` created with 4 menu items: 锁定 / 注销 / 重启 / 关机
- [ ] `Modules/Sidebars/Right/QuickSettings.qml` includes `PowerContent` with the same opacity/scale animation as other views
- [ ] `Modules/Bar/QuickSettings/PowerButton.qml` sets `WidgetState.qsView = "power"` + `WidgetState.qsOpen = true` instead of opening the standalone popup
- [ ] `Modules/Bar/QuickSettings/PowerMenu.qml` deleted (no longer used)
- [ ] Clicking the power button opens the RightSidebar showing the power menu
- [ ] Clicking a power action (lock/logout/reboot/shutdown) executes the corresponding `systemctl`/`loginctl`/`niri msg` command
- [ ] All existing functionality preserved (no commands broken)

### Must NOT Have
- `Sizes.barHeight` and other unrelated properties unchanged
- `Bar.qml`, `RightSidebar.qml`, `WidgetState.qml` unchanged
- No new dependencies introduced
- Power actions must NOT block the UI (they were synchronous in the popup; in the sidebar they should also be fire-and-forget)

---

## TODOs

- [ ] 1. Create `Modules/Sidebars/Right/PowerContent.qml`

  **What to do**:
  - Create new file `Modules/Sidebars/Right/PowerContent.qml`
  - Use `WidgetPanel` as the root (like `NotificationsContent.qml` and `NetworkContent.qml`)
  - Set `title: "电源"`, `icon: "power_settings_new"`, `closeAction: () => WidgetState.qsOpen = false`
  - Add 4 `MaterialRippleButton` items in the content layout:
    - 锁定 → `["loginctl", "lock-session"]`
    - 注销 → `["niri", "msg", "action", "quit"]`
    - 重启 → `["systemctl", "reboot"]`
    - 关机 → `["systemctl", "poweroff"]`
  - The shutdown item should be styled with the `colError` color (matches the old PowerMenu's `isRed: true` pattern)
  - Use the same per-item pattern from the old `PowerMenu.qml:168-232` (Repeater with model array, Rectangle with hover state, MouseArea → `Quickshell.execDetached`)
  - Imports: `QtQuick`, `QtQuick.Layouts`, `Quickshell`, `qs.Common`, `qs.Widgets.common`

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
  - **Skills**: none
  - **Reason**: Simple QML with 4 menu items; structure is well-defined by existing templates

  **References**:
  - `/home/eunoia/.config/quickshell/Widgets/common/WidgetPanel.qml` — base panel component
  - `/home/eunoia/.config/quickshell/Modules/Sidebars/Right/NotificationsContent.qml` — closest template (WidgetPanel + content + closeAction)
  - `/home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/PowerMenu.qml:168-232` — original Repeater model with 4 items to preserve
  - `/home/eunoia/.config/quickshell/Modules/Sidebars/Right/SettingsContent.qml:496-501` — example of `Quickshell.execDetached` usage in a sidebar view
  - `/home/eunoia/.config/quickshell/Common/Appearance.qml` — `colError`, `colOnError`, `colOnLayer0`, `colLayer1` etc.

  **Acceptance Criteria**:
  - [ ] File exists at `Modules/Sidebars/Right/PowerContent.qml`
  - [ ] Root element is `WidgetPanel` (not a bare `Item` or `PanelWindow`)
  - [ ] 4 menu items render: 锁定, 注销, 重启, 关机
  - [ ] Each item executes the correct command on click
  - [ ] 关机 item uses `colError` color (red), others use default `colOnLayer0`/`colLayer1`
  - [ ] No imports of removed files (no `PowerMenu.qml`, no `QuickSettingsPanel.qml`)

  **QA Scenarios**:

  ```
  Scenario: PowerContent file exists
    Tool: Bash (ls)
    Steps:
      1. ls -la /home/eunoia/.config/quickshell/Modules/Sidebars/Right/PowerContent.qml
    Expected Result: File present, non-zero size
    Failure Indicators: File not found
    Evidence: inline command output
  ```

  ```
  Scenario: All 4 menu actions are wired
    Tool: Bash (grep)
    Steps:
      1. grep -E "lock-session|niri.*quit|systemctl.*reboot|systemctl.*poweroff" /home/eunoia/.config/quickshell/Modules/Sidebars/Right/PowerContent.qml
    Expected Result: 4 lines, one per command
    Failure Indicators: Fewer than 4 (some action missing)
    Evidence: inline command output
  ```

  **Commit**: YES
  - Message: `feat(sidebar): add PowerContent view for the unified RightSidebar`
  - Files: `Modules/Sidebars/Right/PowerContent.qml`

- [ ] 2. Register `PowerContent` in `Modules/Sidebars/Right/QuickSettings.qml`

  **What to do**:
  - Open `/home/eunoia/.config/quickshell/Modules/Sidebars/Right/QuickSettings.qml`
  - Add `PowerContent` as a child Item, with `anchors.fill: parent` and the same opacity/scale animation pattern as the other views:
    ```qml
    PowerContent {
        anchors.fill: parent

        opacity: WidgetState.qsView === "power" ? 1.0 : 0.0
        scale: WidgetState.qsView === "power" ? 1.0 : 0.95
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
    }
    ```
  - Add `import qs.Modules.Sidebars.Right` if not already present (it isn't, since the existing views are in the same directory and don't need explicit import)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none
  - **Reason**: 8-line addition to an existing file, pure QML

  **References**:
  - `/home/eunoia/.config/quickshell/Modules/Sidebars/Right/QuickSettings.qml:14-63` — exact pattern to mirror
  - `/home/eunoia/.config/quickshell/Modules/Sidebars/Right/NotificationsContent.qml` — proves same-directory views work without import

  **Acceptance Criteria**:
  - [ ] `PowerContent` block exists in `QuickSettings.qml` after the `NotificationsContent` block
  - [ ] It uses `WidgetState.qsView === "power"` for its opacity/scale gating
  - [ ] Animation `Behavior on opacity` and `Behavior on scale` match the other views
  - [ ] The `visible` property is bound to `opacity > 0` (so hidden views don't intercept clicks)

  **QA Scenarios**:

  ```
  Scenario: PowerContent registered in QuickSettings.qml
    Tool: Bash (grep)
    Steps:
      1. grep -n "PowerContent\|qsView === \"power\"" /home/eunoia/.config/quickshell/Modules/Sidebars/Right/QuickSettings.qml
    Expected Result: At least 2 lines (PowerContent block + qsView check)
    Failure Indicators: 0 lines
    Evidence: inline command output
  ```

  **Commit**: YES (groups with Task 1)
  - Message: `feat(sidebar): add PowerContent view for the unified RightSidebar`
  - Files: `Modules/Sidebars/Right/QuickSettings.qml`

- [ ] 3. Rewire `PowerButton.qml` to use `WidgetState`

  **What to do**:
  - Open `/home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/PowerButton.qml`
  - In the `onClicked` handler of the MouseArea, replace:
    ```qml
    onClicked: {
        powerMenu.anchorItem = root;
        powerMenu.screen = root.screen;
        powerMenu.open();
    }
    ```
    With the same pattern as `Network.qml:36-50` and `NotificationButton.qml:34-49`:
    ```qml
    onClicked: {
        const gpos = root.mapToGlobal(0, 0);
        WidgetState.qsAnchorGlobalX = gpos.x;
        WidgetState.qsAnchorGlobalY = gpos.y;
        WidgetState.qsAnchorWidth = root.width;
        WidgetState.qsAnchorHeight = root.height;
        if (root.screen && root.screen.name)
            WidgetState.qsScreenName = root.screen.name;
        if (WidgetState.qsOpen && WidgetState.qsView === "power") {
            WidgetState.qsOpen = false;
        } else {
            WidgetState.qsView = "power";
            WidgetState.qsOpen = true;
        }
    }
    ```
  - Remove the `PowerMenu { id: powerMenu; screen: root.screen }` block at the bottom (no longer needed)
  - Remove the `qs.Services` import if it was only for PowerMenu (check imports first)
  - Update `PopupToolTip` to match the new style: `extraVisibleCondition: mouseArea.containsMouse`, `text: "电源"`
  - Add a `readonly property bool active` similar to `SettingsButton.qml:12` to indicate the active state (optional, for visual feedback)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none
  - **Reason**: Single-file rewire following an established pattern

  **References**:
  - `/home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/Network.qml:36-50` — exact pattern to copy
  - `/home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/NotificationButton.qml:34-49` — secondary reference
  - `/home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/SettingsButton.qml:12,46-53` — pattern for active state + WidgetState toggle

  **Acceptance Criteria**:
  - [ ] `onClicked` sets `WidgetState.qsView = "power"` (not "network" or other)
  - [ ] `WidgetState.qsAnchorGlobalX/Y/Width/Height` are set from the button's global position
  - [ ] The standalone `PowerMenu { id: powerMenu }` block is removed
  - [ ] `Quickshell.execDetached` calls in PowerButton are removed (those belong in PowerContent now)
  - [ ] Imports match what the file actually uses

  **QA Scenarios**:

  ```
  Scenario: PowerButton uses WidgetState
    Tool: Bash (grep)
    Steps:
      1. grep -n "qsView.*power\|qsOpen\|qsAnchor" /home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/PowerButton.qml
    Expected Result: Lines with WidgetState settings (qsView = "power", qsOpen = true)
    Failure Indicators: Lines with "powerMenu.open()" (old pattern still present)
    Evidence: inline command output
  ```

  ```
  Scenario: Old PowerMenu instantiation removed
    Tool: Bash (grep)
    Steps:
      1. grep -n "PowerMenu" /home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/PowerButton.qml
    Expected Result: 0 lines (no PowerMenu reference)
    Failure Indicators: Any line containing "PowerMenu"
    Evidence: inline command output
  ```

  **Commit**: YES
  - Message: `refactor(powerbutton): use WidgetState instead of standalone PowerMenu popup`
  - Files: `Modules/Bar/QuickSettings/PowerButton.qml`

- [ ] 4. Delete obsolete `PowerMenu.qml`

  **What to do**:
  - `rm /home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/PowerMenu.qml`
  - Verify no other file imports or references it: `grep -rn "PowerMenu" /home/eunoia/.config/quickshell --include="*.qml"`
  - Expected: no matches (the old popup is fully replaced)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none
  - **Reason**: Single file deletion + verification

  **References**:
  - `/home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/PowerMenu.qml` — file to delete (242 lines)

  **Acceptance Criteria**:
  - [ ] `PowerMenu.qml` no longer exists
  - [ ] No `.qml` file references "PowerMenu" by name

  **QA Scenarios**:

  ```
  Scenario: PowerMenu.qml deleted
    Tool: Bash (ls)
    Steps:
      1. ls /home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/PowerMenu.qml 2>&1
    Expected Result: "No such file or directory" error
    Failure Indicators: File still present
    Evidence: inline command output
  ```

  ```
  Scenario: No remaining PowerMenu references
    Tool: Bash (grep)
    Steps:
      1. grep -rn "PowerMenu" /home/eunoia/.config/quickshell --include="*.qml"
    Expected Result: 0 lines
    Failure Indicators: Any matches (file still referenced somewhere)
    Evidence: inline command output
  ```

  **Commit**: YES
  - Message: `chore(cleanup): remove obsolete standalone PowerMenu.qml popup`
  - Files: `Modules/Bar/QuickSettings/PowerMenu.qml` (deleted)

---

## Final Verification Wave

After all 4 tasks complete:

- [ ] F1. **Plan Compliance Audit** — `oracle`
  - Verify all 4 deliverables exist: PowerContent.qml created, QuickSettings.qml updated, PowerButton.qml rewired, PowerMenu.qml deleted
  - Verify WidgetState integration is correct (qsView = "power", qsOpen toggles correctly)
  - Verify 4 power commands are preserved in PowerContent (lock/logout/reboot/shutdown)

- [ ] F2. **Code Quality Review** — `unspecified-high`
  - QML syntax check (ast_grep / pattern match for valid QML)
  - Verify no dangling imports
  - Verify PowerButton.qml no longer imports `PowerMenu` or `Process`
  - Verify PowerContent.qml has all 4 action items

- [ ] F3. **Real Manual QA** — `unspecified-high`
  - Start quickshell, click power button → confirm RightSidebar opens showing 电源 view with 4 items
  - Verify hover/click feedback on each item
  - Verify clicking an item triggers the correct action (lock-screen for safety, don't actually reboot)

- [ ] F4. **Scope Fidelity Check** — `deep`
  - Compare each task's "What to do" with actual diff
  - Verify no unrelated files changed
  - Verify "Must NOT Have" constraints respected (no `Sizes.barHeight` change, no `Bar.qml` change, etc.)

---

## Commit Strategy

| Task | Message | Files |
|------|---------|-------|
| 1, 2 | `feat(sidebar): add PowerContent view for the unified RightSidebar` | `Modules/Sidebars/Right/PowerContent.qml` (new), `Modules/Sidebars/Right/QuickSettings.qml` |
| 3   | `refactor(powerbutton): use WidgetState instead of standalone PowerMenu popup` | `Modules/Bar/QuickSettings/PowerButton.qml` |
| 4   | `chore(cleanup): remove obsolete standalone PowerMenu.qml popup` | `Modules/Bar/QuickSettings/PowerMenu.qml` (deleted) |

---

## Success Criteria

### Verification Commands
```bash
# New view exists
ls /home/eunoia/.config/quickshell/Modules/Sidebars/Right/PowerContent.qml

# Registered in QuickSettings
grep "PowerContent" /home/eunoia/.config/quickshell/Modules/Sidebars/Right/QuickSettings.qml

# PowerButton uses WidgetState
grep "qsView = \"power\"" /home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/PowerButton.qml

# Old popup gone
ls /home/eunoia/.config/quickshell/Modules/Bar/QuickSettings/PowerMenu.qml 2>&1  # Should fail

# No stale references
grep -rn "PowerMenu" /home/eunoia/.config/quickshell --include="*.qml"  # Should be empty

# 4 power actions preserved
grep -E "lock-session|niri.*quit|systemctl.*reboot|systemctl.*poweroff" /home/eunoia/.config/quickshell/Modules/Sidebars/Right/PowerContent.qml
# Expected: 4 lines
```

### Final Checklist
- [ ] `PowerContent.qml` created with 4 items
- [ ] `QuickSettings.qml` registers the new view with animation
- [ ] `PowerButton.qml` uses `WidgetState.qsView = "power"`
- [ ] `PowerMenu.qml` deleted
- [ ] No stale references
- [ ] Quickshell reloads successfully without errors
- [ ] Clicking power button opens the RightSidebar with the 电源 view
- [ ] Each of the 4 items is clickable and triggers the correct action
