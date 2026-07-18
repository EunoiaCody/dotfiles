# Plan: AppLauncher 三大问题修复

## Overview

对 `Modules/Launcher/` 进行三处修复，参考 caelestia-shell 的实现模式：
1. 修复首次打开时频率排序无效（`LaunchTracker` 异步加载竞态）
2. 启用鼠标滚轮滚动（移除 `interactive: false`）
3. 添加搜索动画（利用已有的 `ElementMoveAnimation` + 过渡效果）

核心策略：**基于现有架构修复**，而非重写。caelestia-shell 使用 C++ SQLite 插件 (`AppDb`) 同步加载频率，我们用异步 `FileView`，所以需要修复加载时序而非照搬。

---

## Affected Files

| 文件 | 改动类型 | 变更说明 |
|------|----------|----------|
| `Common/LyricsSyncEngine.qml` | （参考，不改） | — |
| `Services/LaunchTracker.qml` | **修改** | 添加 `ready` 信号，确保启动时立即加载 |
| `Modules/Launcher/AppPage.qml` | **修改** | 等待 LaunchTracker ready；启用滚轮 + 动画 |
| `Modules/Launcher/WindowPage.qml` | **修改** | 启用滚轮；添加动画过渡 |
| `Modules/Launcher/WallpaperPage.qml` | **修改** | 启用滚轮 |
| `Widgets/common/StyledListView.qml` | 可能修改 | 确保 `handleWheel` 在非平滑模式也能工作 |

---

## Step-by-Step Plan

### Phase 1: 修复首次打开频率排序问题 (Priority: 🔴)

**根因**: `LaunchTracker` 的 `frequencies` 通过异步 `FileView` 加载，而 `AppPage.search()` 在 `startupPollTimer` 只等 `DesktopEntries.applications.values.length > 0`，未等 `LaunchTracker` 就绪。首次打开时 `frequencies` 为 `{}`，所有 app 频率为 0，退化为纯字母序。

#### Step 1.1 — 修改 `LaunchTracker.qml`：添加 ready 信号 & 强制初始化
- [ ] 在 `LaunchTracker` 中添加 `property bool ready: false`
- [ ] 在 `freqFile.onLoaded` 中设置 `ready = true`
- [ ] 将 `ensureDir` Process 改为在 `Component.onCompleted` 中立即执行（而非等到首次访问）
- [ ] 添加 `signal frequenciesReady()` — 当 `ready` 变为 true 时 emit

#### Step 1.2 — 修改 `AppPage.qml`：等待 LaunchTracker 就绪
- [ ] 修改 `startupPollTimer` 的 `onTriggered`，增加条件：
  ```javascript
  if (DesktopEntries.applications.values.length > 0 && LaunchTracker.ready) {
      root.search(root.query)
      running = false
  }
  ```
- [ ] 若 LaunchTracker 尚未就绪，Timer 继续轮询（每 50ms）
- [ ] 添加防御：若 `DesktopEntries` 已加载但 2 秒后 LaunchTracker 仍未就绪，直接使用 fallback 字母序

---

### Phase 2: 启用鼠标滚轮滚动 (Priority: 🟡)

**根因**: `AppPage.qml`、`WindowPage.qml`、`WallpaperPage.qml` 三个页面的 ListView 均设置 `interactive: false`，完全禁用了交互滚动。

已有基础设施：`StyledListView.qml` 已实现完整的滚轮处理（`handleWheel`、`wheelDeltaY`、`smoothWheelEnabled`、`MouseArea.onWheel`）。只需启用即可。

#### Step 2.1 — 修改 `AppPage.qml` 的 `appsList`
- [ ] 移除 `interactive: false`
- [ ] 将 `smoothWheelEnabled` 从 `false` 改为 `PersonalizationConfig.scrollSmoothEnabled`（继承已有配置）
- [ ] 保留 `boundsBehavior: Flickable.StopAtBounds`
- [ ] 设置 `maximumFlickVelocity: 3000`（参考 caelestia-shell）
- [ ] 确保 `setCurrentIndex` / `ensureCurrentVisible` 仍然通过键盘导航正常工作

#### Step 2.2 — 修改 `WindowPage.qml` 的 `windowsList`
- [ ] 同上：移除 `interactive: false`
- [ ] 启用 `smoothWheelEnabled`

#### Step 2.3 — 修改 `WallpaperPage.qml` 的 `wallpaperList`
- [ ] 同上：移除 `interactive: false`
- [ ] 启用 `smoothWheelEnabled`

#### Step 2.4 — 键盘导航与滚轮的协调
- [ ] 确保 `onWheel` handler 在 `StyledListView` 中能正确处理 event（已有 `MouseArea` 覆层处理）
- [ ] 验证：滚轮滚动后，`currentIndex` 更新（或让 `highlightFollowsCurrentItem` 保持 index 不变，仅 visual scroll）
- [ ] 注意：当前 `setCurrentIndex` 使用 `appsList.contentY = firstVisibleIndex * rofiStyle.listStep` 进行分页，改用平滑滚动后需确保键盘上下仍能跳转到正确位置

---

### Phase 3: 添加搜索动画 (Priority: 🟢)

**根因**: `AppPage.qml` 中 `StyledListView` 的 `animateAppearance: false`、`animateMovement: false` 禁用了所有过渡动画。搜索时结果列表瞬间切换，无视觉反馈。

已有基础设施：`StyledListView.qml` 已定义了完整的 `add`/`remove`/`move`/`displaced` 过渡（使用 `ElementMoveAnimation`）。

caelestia-shell 参考：`AppList.qml` 在 `onStateChanged` / `transitions` 中做 crossfade + scale 过渡。

#### Step 3.1 — 启用已有的列表动画
- [ ] 在 `AppPage.qml` 中，将 `appsList` 的：
  ```
  animateAppearance: false  → true
  animateMovement: false    → true
  ```

#### Step 3.2 — 添加搜索状态切换动画（参考 caelestia-shell `ContentList.qml`）
- [ ] 在 `AppPage.qml` 中添加一个 `state` 属性：`property string displayState: query.trim() === "" ? "browse" : "search"`
- [ ] 添加 `transitions`：
  ```qml
  transitions: Transition {
      SequentialAnimation {
          ParallelAnimation {
              NumberAnimation { target: appsList; property: "opacity"; from: 1; to: 0; duration: 120; easing.type: Easing.InCubic }
              NumberAnimation { target: appsList; property: "scale"; from: 1; to: 0.95; duration: 120 }
          }
          PropertyAction { target: appsList; property: "opacity"; value: 0 }
          ScriptAction { script: /* update model happens automatically via query binding */ }
          PropertyAction { target: appsList; property: "opacity"; value: 1 }
          ParallelAnimation {
              NumberAnimation { target: appsList; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
              NumberAnimation { target: appsList; property: "scale"; from: 0.95; to: 1; duration: 180 }
          }
      }
  }
  ```
- [ ] 使用 caelestia-shell 的 `Anim` 定时常量或项目已有的 `Appearance.animation.*` 令牌

#### Step 3.3 — 同样为 WindowPage 添加动画
- [ ] `WindowPage.qml`：启用 `animateAppearance: true` + `animateMovement: true`

---

### Phase 4: 集成测试 & 回退验证

- [ ] **测试 1**: 清除 `~/.cache/quickshell/app-launch-freq.json`，重启 quickshell，首次打开 launcher → 应显示字母序（无历史数据时正确行为）
- [ ] **测试 2**: 启动几次 app 后关闭/重开 launcher → 应显示频率排序
- [ ] **测试 3**: 用鼠标滚轮在 AppPage/WindowPage/WallpaperPage 中滚动 → 应平滑滚动
- [ ] **测试 4**: 键盘上下键 → 高亮跳转正确，可视区域自动跟随
- [ ] **测试 5**: 输入搜索文字 → 列表应有淡入淡出动画
- [ ] **测试 6**: 清空搜索文字 → 应平滑过渡回浏览视图
- [ ] **测试 7**: 快速连续输入 → 不应有动画堆积/闪烁

---

## Risks & Considerations

| 风险 | 严重度 | 缓解措施 |
|------|--------|----------|
| 启用 `interactive: true` 后 ListView 可能捕获键盘事件，干扰 `Keys.onUpPressed` 等 | 中 | 保留显式的 `Keys` 处理器；若有冲突，使用 `Keys.onPressed` 的 `event.accepted = true` 优先 |
| 滚轮滚动与 `ensureCurrentVisible()` 分页逻辑冲突 | 中 | `ensureCurrentVisible` 在键盘导航时仍手动计算 contentY；需确保两者不互相覆盖。可以检查 `scrollAnimation.running` 来判断是否在滚轮滚动中 |
| `LaunchTracker.ready` 可能永远不触发（文件不存在等边缘情况） | 低 | Step 1.2 已有 2 秒 fallback 超时 |
| 动画可能导致 item 闪烁（popin + crossfade 叠加） | 低 | Phase 3 中的 `PropertyAction` 确保在替换 model 时 opacity 重置为 0，避免闪烁 |
| caelestia-shell 的 `Anim` 组件使用了 `Anim.DefaultEffects` 等枚举，quickshell 没有这个组件 | 低 | 不直接照搬 `Anim`；使用项目已有的 `Appearance.animation.*` 令牌和标准 `NumberAnimation` |

---

## Estimated Impact

- 文件新建：0
- 文件修改：4 (`LaunchTracker.qml`, `AppPage.qml`, `WindowPage.qml`, `WallpaperPage.qml`)
- 可能修改：1 (`StyledListView.qml` — 仅在滚轮事件处理需要微调时)
- 文件删除：0
- 预计代码行数变化：~100 行（净增约 60 行）

---

## Reference Comparison: caelestia-shell vs 当前 quickshell

| 功能 | caelestia-shell | quickshell (当前) | 修复方案 |
|------|----------------|-------------------|----------|
| 频率存储 | C++ `AppDb` SQLite (同步) | `LaunchTracker` JSON + `FileView` (异步) | 添加 ready 信号协调时序 |
| 滚轮滚动 | `StyledListView` 默认 interactive | `interactive: false` | 移除限制 |
| 搜索动画 | `transitions: Transition { SequentialAnimation { fade+scale } }` | `animateAppearance: false` | 启用 + 添加 state transition |
| 高亮跟踪 | `highlightFollowsCurrentItem: false` + 手动 Behavior on y | `highlightFollowsCurrentItem: true` + `highlightMoveDuration: 0` | 保留当前方式（更简单） |
| 列表组件 | 自研 `StyledListView` + `Anim` | 自研 `StyledListView` + `ElementMoveAnimation` | 兼容 |

---

PLAN COMPLETE
