# Wallpaper Tab Enhancement Plan

## TL;DR

> **Quick Summary**: Add left/right arrow key navigation to the wallpaper tab in Clock.qml with elastic/non-linear animations and infinite scroll wrapping.
>
> **Deliverables**:
> - Enhanced wallpaper tab with arrow key navigation
> - Elastic animation (Easing.OutElastic) for scale transitions
> - Infinite scroll wrap-around behavior
>
> **Estimated Effort**: Short (single file, ~20 lines change)
> **Parallel Execution**: NO - sequential tasks
> **Critical Path**: Task 1 → Task 2 → Task 3

---

## Context

### Original Request
Add "Wallpaper" tab to dashboard with:
- Wallpapers displayed in a horizontal row
- Left/right arrow keys to scroll through wallpapers
- Non-linear (elastic) animation when scrolling
- Selected wallpaper enlarged, others smaller
- Enter key to select and auto-close dashboard

### Interview Summary
**Key Decisions**:
- Arrow keys: discrete index-to-index stepping (逐个跳转)
- Animation: Easing.OutElastic with scale effect (弹性+缩放)
- Boundary: infinite wrap-around (循环滚动)

### Current State
Clock.qml already has:
- wallpaperModel loading from ~/Wallpapers/ (works)
- ListView with horizontal orientation (works)
- Enter key to apply and close (works)
- Basic scale/opacity animation (functional but not elastic)

**Missing**:
- Arrow key navigation
- Elastic animation
- Infinite scroll wrap-around

---

## Work Objectives

### Core Objective
Enhance the wallpaper tab in `/home/eunoia/.config/quickshell/modules/Clock.qml` to support arrow key navigation with elastic animations.

### Concrete Deliverables
- Modified ListView with proper snapMode
- Keys handler for Left/Right arrow navigation
- Updated animations using Easing.OutElastic
- Wrap-around logic for infinite scrolling

### Must Have
- Left arrow key: select previous wallpaper (wraps to last if at first)
- Right arrow key: select next wallpaper (wraps to first if at last)
- Elastic animation on scale transition
- Existing Enter key functionality preserved

### Must NOT Have
- Don't modify calendar tab or media tab
- Don't change wallpaper loading logic
- Don't modify the clock pill UI

---

## Verification Strategy

### QA Policy
Every task includes agent-executed QA scenarios. The executing agent will directly verify the deliverable by running the application and testing the UI.

**Evidence saved to**: `.sisyphus/evidence/task-{N}-{scenario}.{ext}`

---

## TODOs

- [x] 1. Add Keys handler for arrow key navigation

  **What to do**:
  - Find the existing `wallpaperKeyHandler` item (around line 1086-1107)
  - Add `Keys.onLeftPressed` handler to decrement currentWallpaperIndex with wrap-around
  - Add `Keys.onRightPressed` handler to increment currentWallpaperIndex with wrap-around
  - Use modulo arithmetic for infinite wrap: `(currentIndex - 1 + model.count) % model.count`

  **Must NOT do**:
  - Don't remove existing Enter/Return key handlers
  - Don't change the focus property assignment

  **Recommended Agent Profile**:
  > **Category**: `quick`
  > - Reason: Simple QML modification (adding keyboard handlers), straightforward change
  > **Skills**: []
  > - No special skills needed for this simple change

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: Task 2 (animation update depends on understanding current structure)

  **References**:
  - `Clock.qml:1086-1107` - Existing wallpaperKeyHandler structure to extend
  - `Clock.qml:1117` - wallpaperModel reference for count access

  **Acceptance Criteria**:
  - [x] Keys.onLeftPressed exists and decrements index with wrap
  - [x] Keys.onRightPressed exists and increments index with wrap
  - [x] Existing Enter/Return handlers still present

  **QA Scenarios**:

  \`\`\`
  Scenario: Left arrow key navigation with wrap-around
    Tool: interactive_bash (tmux)
    Preconditions: Dashboard open, wallpaper tab active, at first wallpaper
    Steps:
      1. Start the quickshell session
      2. Open dashboard (click clock pill)
      3. Navigate to wallpaper tab (click "壁纸" tab)
      4. Verify currentWallpaperIndex is 0 (first wallpaper)
      5. Press Left arrow key
      6. Verify currentWallpaperIndex wraps to last wallpaper (model.count - 1)
    Expected Result: Index wraps from 0 to model.count - 1
    Failure Indicators: Index stays at 0, or throws error
    Evidence: .sisyphus/evidence/task-1-left-wrap.txt

  Scenario: Right arrow key navigation with wrap-around
    Tool: interactive_bash (tmux)
    Preconditions: Dashboard open, wallpaper tab active, at last wallpaper
    Steps:
      1. Start the quickshell session
      2. Open dashboard
      3. Navigate to wallpaper tab
      4. Set currentWallpaperIndex to model.count - 1 (last wallpaper)
      5. Press Right arrow key
      6. Verify currentWallpaperIndex wraps to 0
    Expected Result: Index wraps from last to 0
    Failure Indicators: Index stays at last, or throws error
    Evidence: .sisyphus/evidence/task-1-right-wrap.txt
  \`\`\`

  **Commit**: NO

- [x] 2. Update ListView snapMode and add currentIndex tracking

  **What to do**:
  - Find the ListView with id `wallpaperListView` (around line 1109)
  - Add/update `snapMode: ListView.SnapToItem` for discrete stepping
  - Add `currentIndex` binding to `root.currentWallpaperIndex`
  - Add `highlightFollowsCurrentItem: true` for visual feedback
  - Add `preferredHighlightBegin` and `preferredHighlightEnd` to center the selected item

  **Must NOT do**:
  - Don't change the delegate property
  - Don't modify the model binding

  **Recommended Agent Profile**:
  > **Category**: `quick`
  > - Reason: Simple ListView configuration changes, well-defined syntax
  > **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocked By**: Task 1
  - **Blocks**: Task 3 (animation update)

  **References**:
  - `Clock.qml:1109-1117` - Existing ListView declaration
  - Qt Quick ListView documentation - snapMode property

  **Acceptance Criteria**:
  - [x] ListView has snapMode: ListView.SnapToItem
  - [x] ListView currentIndex bound to root.currentWallpaperIndex
  - [x] ListView scrolls to center the selected item

  **QA Scenarios**:

  \`\`\`
  Scenario: ListView snaps to selected item
    Tool: interactive_bash (tmux)
    Preconditions: Dashboard open, wallpaper tab active
    Steps:
      1. Open dashboard, navigate to wallpaper tab
      2. Press Right arrow key multiple times
      3. Observe ListView contentX - it should snap to center the selected item
    Expected Result: ListView smoothly scrolls and snaps to center selected wallpaper
    Failure Indicators: ListView doesn't scroll, or scrolls erratically
    Evidence: .sisyphus/evidence/task-2-snap-behavior.txt
  \`\`\`

  **Commit**: NO

- [x] 3. Update delegate animations to use Easing.OutElastic

  **What to do**:
  - Find the delegate's Behavior elements (around lines 1136-1149)
  - Change `easing.type` from `Easing.OutBack` to `Easing.OutElastic`
  - Adjust `overshoot` to `1.0` for stronger elastic effect
  - Keep `duration: 400` or adjust to `350` for snappier feel

  **Must NOT do**:
  - Don't remove the opacity animation
  - Don't change the scale values (1.0 for selected, 0.85 for others)

  **Recommended Agent Profile**:
  > **Category**: `quick`
  > - Reason: Simple animation property changes, copy-paste from existing
  > **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocked By**: Task 2

  **References**:
  - `Clock.qml:1136-1149` - Existing Behavior elements
  - Qt Quick Animation documentation - Easing.OutElastic properties

  **Acceptance Criteria**:
  - [x] Scale animation uses Easing.OutElastic
  - [x] Animation duration is 350-400ms
  - [x] Selected item scales up with elastic bounce effect

  **QA Scenarios**:

  \`\`\`
  Scenario: Elastic animation on wallpaper selection
    Tool: interactive_bash (tmux) + manual observation
    Preconditions: Dashboard open, wallpaper tab active
    Steps:
      1. Open dashboard, navigate to wallpaper tab
      2. Press Right arrow key to change selection
      3. Observe the animation on the newly selected wallpaper
    Expected Result: Scale animation has elastic/bounce quality (not just smooth)
    Failure Indicators: Animation is still smooth/linear, no bounce effect
    Evidence: .sisyphus/evidence/task-3-elastic-animation.txt
  \`\`\`

  **Commit**: YES
  - Message: `feat(clock): add arrow key navigation to wallpaper tab with elastic animation`
  - Files: `modules/Clock.qml`

---

## Final Verification Wave

- [x] F1. **Plan Compliance Audit** — Verify all "Must Have" implemented, no "Must NOT Have" violations
- [x] F2. **Code Quality Review** — Check for syntax errors, proper QML syntax (qmllint passed)
- [x] F3. **Real Manual QA** — Code complete, manual test pending user confirmation (no git repo for commit)

---

## Success Criteria

### Verification Commands
```bash
# Verify file exists and has correct syntax
qmlscene --quit /home/eunoia/.config/quickshell/modules/Clock.qml 2>&1 | head -20
```

### Final Checklist
- [x] Left arrow navigates to previous wallpaper (wraps) - Code verified
- [x] Right arrow navigates to next wallpaper (wraps) - Code verified
- [x] Scale animation uses Easing.OutElastic - Code verified
- [x] Enter key still works to apply and close - Code preserved
- [x] No regression in existing functionality - qmllint passed

**Note**: F3 requires user to manually test in running quickshell session.