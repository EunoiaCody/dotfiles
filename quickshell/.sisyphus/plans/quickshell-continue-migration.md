# Plan: Quickshell 继续迁移 (StatIndet → 本地)

## TL;DR

> **Quick Summary**: 继续将 StatIndet/quickshell 的缺失模块迁移到本地配置：
> 右侧边栏 (RightSidebar)、壁纸管理 (WallpaperPage/FileBrowser/ColorPicker)、
> 简化版壁纸背景 (WallpaperBackground)，以及相关脚本。同时做架构重构和代码清理。
>
> **Deliverables**:
> - `Modules/Sidebars/Right/` — 6 个文件 (QuickSettings/Audio/Network/Sliders/Settings)
> - `Modules/ControlCenter/` — 3 个文件 (WallpaperPage/FileBrowser/ColorPicker，删过渡效果)
> - `Modules/Wallpaper/` — 1 个简化版 WallpaperBackground.qml (纯图片，无着色器)
> - `scripts/` — 追加 weather/schedule/system 脚本
> - `shell.qml` + `AppShell.qml` — 架构重构 (shell → AppShell)
> - 代码清理：删旧 modules/, 弃用 Clock, shell.qml.bak
>
> **Estimated Effort**: Medium (10-15 tasks)
> **Parallel Execution**: YES — 4 waves, Wave 2 has 4 parallel tracks
> **Critical Path**: Task 1 → Task 5 → Task 8 → Task 9 → F1-F4

---

## Context

### Original Request
用户已部分完成从 https://github.com/StatIndet/quickshell 的迁移（Common/Services/Components/Widgets, Modules/Bar/DynamicIsland/Launcher/Lock, Clavis C++ 插件），
现在要继续完成其余模块的迁移。

### Interview Summary
**Key Decisions**:
- **右侧边栏 (RightSidebar)**：6 文件，全部迁移
- **壁纸管理 (ControlCenter 部分)**：仅 WallpaperPage/WallpaperFileBrowser/WallpaperColorPicker
- **WallpaperPage.qml 需修改**：删除「过渡效果」区域（引用未迁移的 BezierCurveEditor）
- **壁纸背景**：简化版，仅图片显示，无着色器特效
- **架构**：改为 shell.qml → AppShell.qml → 各模块
- **清理**：删除旧 modules/ 目录、AppShell 中弃用 Clock、shell.qml.bak
- **脚本**：迁移 weather/media(已有)/schedule/system，跳过 capture/theme
- 跳过：Left Sidebar, matugen, assets, ControlCenter 其余部分

### Self-Review (Gap Analysis)
**Auto-Resolved**:
- WallpaperPage.qml 含过渡效果区域 → 需裁剪（明确知道依赖关系）
- WallpaperBackground.qml 需简化 → 写新版本（明确知道范围）
- WallpaperService.qml 需确认方法覆盖 → 作为审计任务

---

## Work Objectives

### Core Objective
将 StatIndet/quickshell 剩余模块迁移完毕，同时进行架构重组。

### Concrete Deliverables
- `Modules/Sidebars/Right/` (6 个 QML 文件 + qmldir 注册)
- `Modules/Wallpaper/` (简化版 WallpaperBackground.qml + qmldir 注册)
- `Modules/ControlCenter/WallpaperPage.qml` (裁剪版，删过渡效果)
- `Modules/ControlCenter/WallpaperFileBrowser.qml`
- `Modules/ControlCenter/WallpaperColorPicker.qml`
- `Services/WallpaperService.qml` (方法审计后的最终版)
- `scripts/weather/weather.py`
- `scripts/schedule/parse_schedule.py`
- `scripts/system/overview.sh`
- `shell.qml` (薄层，只加载 AppShell)
- `AppShell.qml` (包含 Bar/DynamicIsland/RightSidebar/Lock/Launcher)

### Must Have
- [ ] quickshell 能正常启动，所有已迁移模块可工作
- [ ] 右侧边栏可用（QuickSettings, Audio, Network, QuickSliders）
- [ ] 壁纸管理界面可用（选择文件/颜色作为壁纸）
- [ ] 壁纸背景显示正常（简化版，无特效）
- [ ] 旧 modules/ 目录已删除，没有残留引用报错

### Must NOT Have (Guardrails)
- [ ] 不要迁移 Left Sidebar（天气仪表板）的 37 个文件
- [ ] 不要迁移 BezierCurveEditor / BezierCurveLayerEditor
- [ ] 不要迁移 matugen/templates/
- [ ] 不要迁移 assets/shaders/（无着色器特效）
- [ ] 不要修改已有的 Bar/DynamicIsland/Launcher/Lock 模块的核心逻辑

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: NO
- **Automated tests**: None
- **Agent-Executed QA**: ALWAYS — use interactive_bash (start quickshell and verify window/client existence), curl for IPC

### QA Policy
Every task MUST include agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — 3 parallel audits + fetches):
├── Task 1: Audit WallpaperService.qml method signatures
├── Task 2: Check old modules/ for remaining imports
└── Task 3: Fetch remote files from GitHub

Wave 2 (After Wave 1 — 4 parallel tracks):
├── Task 4: Migrate RightSidebar (6 files + qmldir)
├── Task 5: Migrate Wallpaper management (3 files, strip transitions)
├── Task 6: Create simplified WallpaperBackground.qml
└── Task 7: Copy scripts (weather/schedule/system)

Wave 3 (After Wave 2 — sequential architecture + cleanup):
├── Task 8: Rewrite shell.qml → AppShell architecture
├── Task 9: Rewrite AppShell.qml (add RightSidebar, remove Clock)
├── Task 10: Delete old modules/ + shell.qml.bak
└── Task 11: Final audit + cleanup sweep

Wave FINAL (After ALL tasks):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality + build check
├── F3: Real QA — start quickshell, verify panels
└── F4: Scope fidelity check
```

---

## TODOs

- [ ] 1. Audit WallpaperService.qml — 检查方法签名是否覆盖所有需求

  **What to do**:
  - 读取 `local:/Services/WalledpaperService.qml` 和 `remote:Services/WallpaperService.qml` 对比方法签名
  - 需要的核心方法：
    - `parentFolder(path)` — 取父目录
    - `basename(path)` — 取文件名
    - `isColorSource(path)` — 判断颜色源
    - `setWallpaper(path, screenName, persist)` — 设置壁纸
    - `clearWallpaper(screenName, persist)` — 清除壁纸
    - `cyclePrevious/persist`, `cycleNext(persist)`, `cycleRandom(persist)`
    - `setWallpaperFolder(path)` — 设置壁纸文件夹
    - `setWallpaperFillMode(mode)`, `setTransitionDurationMs(ms)`, `setTransitionEasingMode(mode)`, `setTransitionBezierCurve(curve)`
    - `setTransitionType(type)`
    - `wallpaperForScreen(screenName)`, `fillModeForScreen(screenName)`, `qtFillMode(mode)`, `shaderFillMode(mode)`
    - `revision`, `settingsRevision`, `currentWallpaper`
    - `addRecentWallpaperColor(color)`, `recentWallpaperColors`
  - 如果有缺失方法，在本地 WallpaperService.qml 中追加
  - 确保 `qs.Services/qmldir` 中 WallpaperService 已注册为 singleton

  **Must NOT do**:
  - 不要修改 WallpaperService 已有的功能逻辑
  - 不要重命名已有方法

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: None (audit only, results used by Tasks 5, 6)
  - **Blocked By**: None

  **References**:
  - `local:Services/WallpaperService.qml` — 本地现有版本
  - `https://raw.githubusercontent.com/StatIndet/quickshell/main/Services/WallpaperService.qml` — 远程版本（需对比）
  - `local:Services/qmldir` — 确认注册

  **QA Scenarios**:
  ```
  Scenario: Verify WallpaperService loads
    Tool: Bash
    Preconditions: quickshell test environment available
    Steps:
      1. Read Services/qmldir — confirm "singleton WallpaperService" line exists
      2. Read WallpaperService.qml — confirm it's a Singleton with pragma Singleton
    Expected Result: qmldir has the singleton declaration, file is valid QML singleton
    Evidence: .sisyphus/evidence/task-1-service-check.txt

  Scenario: Verify key methods exist
    Tool: Bash
    Steps:
      1. ast_grep_search for "function parentFolder(" in WallpaperService.qml
      2. ast_grep_search for "function isColorSource("
      3. ast_grep_search for "function setWallpaperFolder("
      4. ast_grep_search for "property (var|readonly).*currentWallpaper"
    Expected Result: All key functions/properties present
    Evidence: .sisyphus/evidence/task-1-methods.txt
  ```

  **Commit**: YES (groups with Task 5, 6)
  - Message: `feat(wallpaper): update WallpaperService with needed methods for wallpaper management`
  - Files: `Services/WallpaperService.qml`, `Services/qmldir`

- [ ] 2. Check old modules/ directory for remaining import references

  **What to do**:
  - grep 整个代码库查找对旧 `modules/` 的 import 引用
  - 检查 `modules/` 目录中的组件名（Bluetooth, Clock, Network, Notifications, PowerMenu, SystemMonitor, SystemTray, TrayMenu, Volume, Workspaces）是否在任何地方被 import
  - 特别检查 AppShell.qml 中的 `Modules.Clock {}` — 确认这是唯一引用
  - 检查 shell.qml, AppShell.qml 和其他文件是否有 `import "modules"` 或 `import qs.modules` 之类的语句
  - 记录结果，为 Task 10 安全删除做准备

  **Must NOT do**:
  - 不要删除文件（Task 10 负责删除）
  - 不要修改旧 modules/ 中的文件

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: Task 10 (deletion)
  - **Blocked By**: None

  **References**:
  - `local:modules/` — 10 个旧版文件
  - `local:shell.qml`, `local:AppShell.qml` — 主要检查点

  **QA Scenarios**:
  ```
  Scenario: Check import references
    Tool: Bash
    Steps:
      1. rg -l "modules/Bluetooth\|import.*modules" --type qml
      2. rg -l "Modules\.Clock\|Modules\.Bluetooth\|Modules\.Network" --type qml
      3. grep -rn "Modules\." AppShell.qml shell.qml
    Expected Result: Only "Modules.Clock" in AppShell.qml remains as reference
    Evidence: .sisyphus/evidence/task-2-import-audit.txt
  ```

  **Evidence to Capture**:
  - [ ] All import references found, recorded
  - [ ] Confirmation: only deprecatd Clock in AppShell.qml references old modules

  **Commit**: NO (audit only)

- [ ] 3. Fetch remote files from GitHub

  **What to do**:
  - 从 StatIndet/quickshell GitHub 仓库下载所有需要迁移的文件
  - 使用 Bash (curl/wget) 或 webfetch 获取每个文件的原始内容
  - 暂存到临时位置 `/tmp/quickshell-migration/`
  - 下载内容：
    - `Modules/Sidebars/Right/` × 6: RightSidebar.qml, AudioContent.qml, NetworkContent.qml, QuickSettings.qml, QuickSliders.qml, SettingsContent.qml
    - `Modules/ControlCenter/` × 3: WallpaperPage.qml, WallpaperFileBrowser.qml, WallpaperColorPicker.qml
    - `Modules/Wallpaper/WallpaperBackground.qml`（作为参考，但用简化版替代）
    - `scripts/weather/weather.py`, `scripts/schedule/parse_schedule.py`, `scripts/system/overview.sh`

  **Must NOT do**:
  - 不要写入本地 quickshell 目录（后续 Task 负责拷贝）

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2)
  - **Blocks**: Tasks 4, 5, 7
  - **Blocked By**: None

  **References**:
  - `https://github.com/StatIndet/quickshell/tree/main/Modules/Sidebars/Right`
  - `https://github.com/StatIndet/quickshell/tree/main/Modules/ControlCenter`
  - `https://github.com/StatIndet/quickshell/tree/main/scripts/weather`
  - `https://github.com/StatIndet/quickshell/tree/main/scripts/schedule`
  - `https://github.com/StatIndet/quickshell/tree/main/scripts/system`

  **QA Scenarios**:
  ```
  Scenario: Verify files downloaded
    Tool: Bash
    Steps:
      1. ls /tmp/quickshell-migration/Modules/Sidebars/Right/ — expect 6 files
      2. ls /tmp/quickshell-migration/Modules/ControlCenter/ — expect 3 files
      3. ls /tmp/quickshell-migration/scripts/ — expect 3 dirs
    Expected Result: All expected files present
    Evidence: .sisyphus/evidence/task-3-fetched-files.txt
  ```

  **Commit**: NO (intermediary step)

- [ ] 4. Migrate RightSidebar (6 files + qmldir)

  **What to do**:
  - 从 `/tmp/quickshell-migration/Modules/Sidebars/Right/` 拷贝到 `local:Modules/Sidebars/Right/`
  - 创建 `Modules/Sidebars/Right/qmldir`（如果远程有就复制，没有就创建）
  - 更新 `Modules/qmldir` — 注册 RightSidebar 和 Sidebars 模块
  - 检查文件间相对 import 路径是否匹配本地结构
  - RightSidebar 文件列表：
    1. `RightSidebar.qml` — 主窗口/入口
    2. `AudioContent.qml` — 音频控制内容
    3. `NetworkContent.qml` — 网络控制内容
    4. `QuickSettings.qml` — 快捷设置开关
    5. `QuickSliders.qml` — 快捷滑块（亮度/音量）
    6. `SettingsContent.qml` — 设置内容

  **Must NOT do**:
  - 不要修改 RightSidebar 的逻辑
  - 不要修改已有模块

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6, 7)
  - **Blocks**: Task 8 (AppShell 需要包含 RightSidebar)
  - **Blocked By**: Task 3

  **References**:
  - `/tmp/quickshell-migration/Modules/Sidebars/Right/` — 源文件
  - `local:Modules/Bar/Bar.qml` — 参考现有模块的注册方式
  - `local:Modules/qmldir` — 需要更新
  - `local:Modules/` — 创建 Sidebars/Right/ 子目录

  **QA Scenarios**:
  ```
  Scenario: RightSidebar files placed correctly
    Tool: Bash
    Steps:
      1. ls Modules/Sidebars/Right/ — verify 6 files present
      2. cat Modules/qmldir — verify "RightSidebar" registration line
    Expected Result: All files in place, qmldir updated
    Evidence: .sisyphus/evidence/task-4-files.txt

  Scenario: QML syntax check
    Tool: Bash
    Steps:
      1. For each .qml file in Modules/Sidebars/Right/:
         qmllint (or ast_grep for basic syntax validation)
    Expected Result: No syntax errors (note: qmllint may not be available, fallback to ast_grep check for valid QML structure)
    Evidence: .sisyphus/evidence/task-4-syntax.txt
  ```

  **Evidence to Capture**:
  - [ ] File listing of Modules/Sidebars/Right/
  - [ ] Modules/qmldir diff

  **Commit**: YES (with Task 5 if same wave)
  - Message: `feat(sidebar): add RightSidebar module (Audio/Network/QuickSettings/Sliders/Settings)`
  - Files: `Modules/Sidebars/Right/*`, `Modules/qmldir`

- [ ] 5. Migrate Wallpaper management (3 files, strip transitions)

  **What to do**:
  - 从 `/tmp/quickshell-migration/Modules/ControlCenter/` 获取 WallpaperPage.qml
  - 创建 `Modules/ControlCenter/` 目录
  - **裁剪 WallpaperPage.qml**：删除整个「过渡效果」(过渡效果/Transition Effects) 区域 —— 该区域包含：
    - Section { title: "过渡效果" / "Transition Effects" } 完整代码块
    - 引用 BezierCurveEditor, BezierCurveLayerEditor 的部分
    - SegmentedButtonGroup 中 transitionTypes 相关的
    - EasingActionGroup, EasingGroupButton 组件定义
    - MaterialAccessibleSlider 中 transitionDurationMs 相关的
    - SplitMenuButton 中 easing modes 相关的
    - BezierCurveLayerEditor 实例
  - 保留：当前壁纸预览、选择文件夹、选择颜色、清除壁纸、循环切换（上一张/随机/下一张）、填充模式
  - 复制 WallpaperFileBrowser.qml 和 WallpaperColorPicker.qml 到 `Modules/ControlCenter/`（无需修改）
  - 创建 `Modules/ControlCenter/qmldir`
  - 更新 `Modules/qmldir` — 注册 ControlCenter 模块

  **Must NOT do**:
  - 不要保留任何引用 BezierCurveEditor/BezierCurveLayerEditor 的代码
  - 不要修改 WallpaperFileBrowser.qml 和 WallpaperColorPicker.qml 的内容

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 6, 7)
  - **Blocks**: Task 9 (AppShell 整合)
  - **Blocked By**: Task 3

  **References**:
  - `/tmp/quickshell-migration/Modules/ControlCenter/WallpaperPage.qml` — 需裁剪的源文件
  - `/tmp/quickshell-migration/Modules/ControlCenter/WallpaperFileBrowser.qml` — 直接复制
  - `/tmp/quickshell-migration/Modules/ControlCenter/WallpaperColorPicker.qml` — 直接复制
  - `local:Modules/qmldir` — 需更新
  - `local:Common/Appearance.qml` — WallpaperPage 引用的颜色变量

  **QA Scenarios**:
  ```
  Scenario: Verify transition effects removed from WallpaperPage.qml
    Tool: Bash
    Steps:
      1. grep -n "BezierCurve\|过渡效果\|Transition Effect\|BezierCurveEditor\|BezierCurveLayerEditor" Modules/ControlCenter/WallpaperPage.qml
    Expected Result: No matches — all transition references removed
    Evidence: .sisyphus/evidence/task-5-no-transitions.txt

  Scenario: Verify essential UI preserved
    Tool: Bash
    Steps:
      1. grep "chooseWallpaperFile\|chooseWallpaperColor\|cyclePrevious\|cycleNext\|cycleRandom" Modules/ControlCenter/WallpaperPage.qml
      2. cat Modules/qmldir — check for ControlCenter registration
    Expected Result: Wallpaper selection/cycling functions present, module registered
    Evidence: .sisyphus/evidence/task-5-essentials.txt
  ```

  **Commit**: YES (with Task 4 if same wave)
  - Message: `feat(wallpaper): add wallpaper management page (WallpaperPage/FileBrowser/ColorPicker), strip transitions`
  - Files: `Modules/ControlCenter/*`, `Modules/qmldir`

- [ ] 6. Create simplified WallpaperBackground.qml

  **What to do**:
  - 创建 `Modules/Wallpaper/` 目录
  - 写一个**简化版** WallpaperBackground.qml（远程版本 400+ 行含着色器特效）
  - 简化版只需要：
    - `PanelWindow` 作为底层窗口（WlrLayershell.layer: Background）
    - `WlrLayershell.namespace: "clavis-wallpaper"`
    - 绑定到每个屏幕（使用 Variants + model: Quickshell.screens）
    - `Image` 显示壁纸（异步加载、PreserveAspectCrop）
    - 监听 `WallpaperService.wallpaperForScreen(screenName)` 变化
    - 支持颜色纯色壁纸（Rectangle 显示颜色）
    - 没有 ShaderEffect, 没有过渡动画, 没有 Loader
    - 约 50-80 行
  - 创建 `Modules/Wallpaper/qmldir`
  - 更新 `Modules/qmldir` — 注册 Wallpaper 模块

  **Must NOT do**:
  - 不要包含任何 GLSL 着色器引用
  - 不要包含 BezierCurveEditor/BezierCurveLayerEditor 引用
  - 不要复制 assets/shaders/ 目录

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 7)
  - **Blocks**: Task 9 (AppShell 整合)
  - **Blocked By**: Task 1 (需要确认 WallpaperService API)

  **References**:
  - `https://raw.githubusercontent.com/StatIndet/quickshell/main/Modules/Wallpaper/WallpaperBackground.qml` — 远程完整版（参考架构）
  - `local:Services/WallpaperService.qml` — 调用的服务 API
  - `local:Services/PersonalizationConfig.qml` — 配置引用
  - `local:Common/Paths.qml` — 文件路径工具

  **QA Scenarios**:
  ```
  Scenario: Simplified wallpaper QML syntax check
    Tool: Bash
    Steps:
      1. ast_grep for "ShaderEffect\|Loader\|transitionAnimation\|frag.qsb" in Modules/Wallpaper/WallpaperBackground.qml
    Expected Result: Zero matches — no GLSL/shader references
    Evidence: .sisyphus/evidence/task-6-no-shaders.txt

  Scenario: Verify basic structure
    Tool: Bash
    Steps:
      1. grep "PanelWindow\|WlrLayershell\|WallpaperService\|Image\|imageUrl" Modules/Wallpaper/WallpaperBackground.qml
      2. cat Modules/qmldir — check Wallpaper registration
    Expected Result: Has PanelWindow, layershell, image display, module registered
    Evidence: .sisyphus/evidence/task-6-structure.txt
  ```

  **Evidence to Capture**:
  - [ ] Simplified QML file
  - [ ] No shader references confirmed
  - [ ] Modules/qmldir updated

  **Commit**: YES (with Task 5 if same wave)
  - Message: `feat(wallpaper): add simplified wallpaper background module (image only, no shaders)`
  - Files: `Modules/Wallpaper/*`, `Modules/qmldir`

- [ ] 7. Copy scripts (weather/schedule/system)

  **What to do**:
  - 从 `/tmp/quickshell-migration/scripts/` 复制以下到 `local:scripts/`：
    - `weather/weather.py` → `scripts/weather/weather.py`
    - `schedule/parse_schedule.py` → `scripts/schedule/parse_schedule.py`
    - `system/overview.sh` → `scripts/system/overview.sh`
  - 确保 `scripts/` 下所需的子目录存在
  - 确认已有 `scripts/media/lyrics_fetcher.py`（无需再次复制）
  - 给脚本加执行权限：`chmod +x`

  **Must NOT do**:
  - 不要复制 scripts/capture/ 和 scripts/theme/
  - 不要覆盖已有的 scripts/media/ 文件

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 6)
  - **Blocks**: None
  - **Blocked By**: Task 3

  **References**:
  - `/tmp/quickshell-migration/scripts/` — 源文件
  - `local:scripts/` — 目标目录（已有 media/ 和 lyrics_fetcher.py）

  **QA Scenarios**:
  ```
  Scenario: Scripts copied and executable
    Tool: Bash
    Steps:
      1. ls -la scripts/weather/ scripts/schedule/ scripts/system/
      2. file scripts/weather/weather.py
      3. head -3 scripts/weather/weather.py
    Expected Result: All scripts present, weather.py is Python, has shebang
    Evidence: .sisyphus/evidence/task-7-scripts.txt
  ```

  **Commit**: YES
  - Message: `feat(scripts): add weather/schedule/system scripts`
  - Files: `scripts/weather/*`, `scripts/schedule/*`, `scripts/system/*`

- [ ] 8. Rewrite shell.qml — 改为 AppShell 薄代理层

  **What to do**:
  - 将当前 54 行的 `shell.qml` 替换为远程风格的薄层（约 5 行）
  - 新 `shell.qml` 内容：
    ```qml
    //@ pragma UseQApplication
    import QtQuick
    import Quickshell

    ShellRoot {
        AppShell {}
    }
    ```
  - 删除所有当前 `shell.qml` 中的直接模块导入和实例化代码

  **Must NOT do**:
  - 不要丢失 `//@ pragma UseQApplication` 指令
  - 不要添加任何不在远程 `shell.qml` 中的内容

  **Parallelization**:
  - **Can Run In Parallel**: NO (sequential, depends on AppShell being ready)
  - **Parallel Group**: Sequential
  - **Blocks**: Task 10 (cleanup can happen after)
  - **Blocked By**: Task 9 (AppShell 必须先就绪)

  **References**:
  - `https://raw.githubusercontent.com/StatIndet/quickshell/main/shell.qml` — 远程薄层版本
  - `local:shell.qml` — 当前版本（备份前请读取）
  - `local:shell.qml.bak` — 旧备份（可删除）

  **QA Scenarios**:
  ```
  Scenario: Verify shell.qml content
    Tool: Bash
    Steps:
      1. cat shell.qml
      2. grep "AppShell" shell.qml
      3. grep "ShellRoot" shell.qml
    Expected Result: shell.qml has ShellRoot + AppShell only (~5 lines), no module imports
    Evidence: .sisyphus/evidence/task-8-shell.txt
  ```

  **Evidence to Capture**:
  - [ ] Final shell.qml content

  **Commit**: YES (with Task 9)
  - Message: `refactor(shell): thin shell.qml to proxy AppShell, matching remote architecture`
  - Files: `shell.qml`

- [ ] 9. Rewrite AppShell.qml — 整合 RightSidebar + 移除 Clock

  **What to do**:
  - 读取当前 `AppShell.qml`
  - 修改内容：
    1. **添加 import** `import qs.Modules.Sidebars.Right`（或对应注册的模块名）
    2. **安装 RightSidebar**：添加 `RightSidebar {}` 实例（参考远程在 Bar 之后的位置）
    3. **删除弃用 Clock**：移除 `Modules.Clock {}` 和 `Variants { model: Quickshell.screens; Modules.Clock {} }` 的整个块
    4. **保持在 AppShell 级别安装 WallpaperBackground**（如果用户需要）:
       - 可选的：添加 `WallpaperBackground {}` 实例
       - 注：壁纸背景需要在 Bar 等上层窗口之前渲染
    5. **保持**：Bar, DynamicIsland, LockWarmup, Lock (+IPC), LauncherWindow (+IPC)
    6. 更新注释说明新的架构
  - 确保 import 语句正确
  - 确认没有重复的模块实例化

  **Must NOT do**:
  - 不要删除 Lock, Bar, DynamicIsland, Launcher 及其 IPC handler
  - 不要重命名 id 引用（sessionLocker, rofiLauncher）

  **Parallelization**:
  - **Can Run In Parallel**: NO (sequential)
  - **Parallel Group**: Sequential
  - **Blocks**: Task 8 (shell.qml 需要 AppShell)
  - **Blocked By**: Tasks 4, 5, 6 (需要模块就绪)

  **References**:
  - `local:AppShell.qml` — 当前版本
  - `https://raw.githubusercontent.com/StatIndet/quickshell/main/AppShell.qml` — 远程版本（参考整体结构）
  - `local:Modules/qmldir` — 确认所有模块已注册

  **QA Scenarios**:
  ```
  Scenario: Verify deprecated Clock removed
    Tool: Bash
    Steps:
      1. grep -n "Clock" AppShell.qml
    Expected Result: No matches (Clock removed, no reference to deprecated Clock)
    Evidence: .sisyphus/evidence/task-9-no-clock.txt

  Scenario: Verify new modules included
    Tool: Bash
    Steps:
      1. grep "RightSidebar\|WallpaperBackground" AppShell.qml
      2. grep "Bar\|DynamicIsland\|LockWarmup\|sessionLocker\|rofiLauncher" AppShell.qml
    Expected Result: RightSidebar + WallpaperBackground present, all existing modules preserved
    Evidence: .sisyphus/evidence/task-9-modules.txt
  ```

  **Commit**: YES (with Task 8)
  - Message: `refactor(appshell): add RightSidebar, remove deprecated Clock, integrate new modules`
  - Files: `AppShell.qml`

- [ ] 10. Delete old modules/ directory + shell.qml.bak

  **What to do**:
  - 删除 `modules/`（小写）目录及其全部 10 个文件：
    - `modules/Bluetooth.qml`
    - `modules/Clock.qml`
    - `modules/Network.qml`
    - `modules/Notifications.qml`
    - `modules/PowerMenu.qml`
    - `modules/SystemMonitor.qml`
    - `modules/SystemTray.qml`
    - `modules/TrayMenu.qml`
    - `modules/Volume.qml`
    - `modules/Workspaces.qml`
  - 删除 `shell.qml.bak`
  - 确认在 Task 2 中已确认没有其他文件引用旧 modules/

  **Must NOT do**:
  - 不要删除 `Modules/`（大写）—— 这是新版模块目录
  - 不要删除 `Services/`, `Common/`, `Widgets/`, `Components/`
  - 先确认 Task 2 的审计结果

  **Parallelization**:
  - **Can Run In Parallel**: NO (sequential)
  - **Parallel Group**: Sequential (after Tasks 8, 9)
  - **Blocks**: None
  - **Blocked By**: Task 2 (确认安全删除), Tasks 8, 9 (架构迁移完成)

  **References**:
  - `local:modules/` — 待删除目录
  - `local:shell.qml.bak` — 待删除文件
  - Task 2 audit results — 确认无残留引用

  **QA Scenarios**:
  ```
  Scenario: Verify old directories deleted
    Tool: Bash
    Steps:
      1. ls modules/ 2>&1 || echo "modules/ deleted successfully"
      2. ls shell.qml.bak 2>&1 || echo "shell.qml.bak deleted successfully"
    Expected Result: Both paths do not exist
    Evidence: .sisyphus/evidence/task-10-deleted.txt

  Scenario: Verify no breakage
    Tool: Bash
    Steps:
      1. rg -l "from.*modules/" --type qml 2>/dev/null || echo "No old import references found"
    Expected Result: No old import references remain
    Evidence: .sisyphus/evidence/task-10-no-refs.txt
  ```

  **Commit**: YES
  - Message: `chore(cleanup): remove deprecated modules/ directory and shell.qml.bak`
  - Files: `modules/*` (deleted), `shell.qml.bak` (deleted)

- [ ] 11. Final audit + cleanup sweep

  **What to do**:
  - 对整个配置做最终检查：
    - 所有 qmldir 文件引用一致（没有漏注册的模块）
    - 没有 dangling import（引用了不存在的模块）
    - 检查 `.gitignore` 是否合理（Sisyphus 相关）
    - 检查 `start-quickshell.sh` 是否仍然有效（Clavis 插件路径）
    - 检查 `shell.qml.bak` 是否确定已删除
    - 运行 `quickshell --validate`（如果有的话）或至少语法检查
  - 运行 `git status` 查看更改概览

  **Must NOT do**:
  - 不要做功能修改（本 task 只做检查）

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (after Task 10)
  - **Blocks**: Wave FINAL
  - **Blocked By**: Tasks 8, 9, 10

  **References**:
  - `local:Modules/qmldir`, `local:Services/qmldir` — 确认注册一致
  - `local:start-quickshell.sh` — 启动脚本
  - `local:.gitignore` — gitignore

  **QA Scenarios**:
  ```
  Scenario: qmldir consistency check
    Tool: Bash
    Steps:
      1. For each qmldir in Modules/, Modules/Bar/, Modules/DynamicIsland/, Modules/Sidebars/Right/, Modules/ControlCenter/, Modules/Wallpaper/, Modules/Launcher/, Modules/Lock/:
         grep "\.qml" | while read line; do
           module_file=$(echo "$line" | awk '{print $NF}')
           [ -f "Modules/$module_file" ] || echo "MISSING: $module_file"
         done
    Expected Result: No missing files
    Evidence: .sisyphus/evidence/task-11-qmldir-check.txt

  Scenario: git status review
    Tool: Bash
    Steps:
      1. git status --short
      2. git diff --stat
    Expected Result: Changes are in expected files only
    Evidence: .sisyphus/evidence/task-11-git-status.txt
  ```

  **Commit**: NO (no code changes, review only)

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, curl endpoint, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Verify all .qml files have valid QML structure. Check for: dangling imports, invalid module references, any remaining references to old modules/ directory, commented-out transition code in WallpaperPage.qml.
  Output: `QML files [N clean/N issues] | Imports [CLEAN/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start from clean checkout. Verify: each qmldir correctly exports its modules, file structure matches convention, scripts are executable.
  Output: `qmldir [N/N valid] | Files [N/N present] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

| Task | Message | Files |
|------|---------|-------|
| 1,5,6 | `feat(wallpaper): update WallpaperService, add wallpaper management + simplified background` | `Services/WallpaperService.qml`, `Services/qmldir`, `Modules/ControlCenter/*`, `Modules/Wallpaper/*`, `Modules/qmldir` |
| 4 | `feat(sidebar): add RightSidebar module (Audio/Network/QuickSettings/Sliders/Settings)` | `Modules/Sidebars/Right/*`, `Modules/qmldir` |
| 7 | `feat(scripts): add weather/schedule/system scripts` | `scripts/weather/*`, `scripts/schedule/*`, `scripts/system/*` |
| 8,9 | `refactor(shell): thin shell.qml + integrate RightSidebar in AppShell, remove deprecated Clock` | `shell.qml`, `AppShell.qml` |
| 10 | `chore(cleanup): remove deprecated modules/ directory and shell.qml.bak` | `modules/*` (deleted), `shell.qml.bak` (deleted) |

---

## Success Criteria

### Verification Commands
```bash
ls Modules/Sidebars/Right/        # 6 files present
ls Modules/ControlCenter/         # WallpaperPage, WallpaperFileBrowser, WallpaperColorPicker
ls Modules/Wallpaper/             # WallpaperBackground.qml + qmldir
ls modules/ 2>/dev/null           # Should fail: directory deleted
cat shell.qml                     # ~5 lines, ShellRoot + AppShell
cat AppShell.qml                  # Has Bar, DynamicIsland, RightSidebar, Lock, Launcher (no Clock)
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] RightSidebar module files in place
- [ ] Wallpaper management UI files in place
- [ ] Simplified WallpaperBackground in place
- [ ] No references to old modules/ directory
- [ ] AppShell.qml has no deprecated Clock
- [ ] shell.qml.bak deleted
