# 天气位置手动配置 — 工作计划

## TL;DR

> **Quick Summary**: 在 Dashboard 天气面板（WeatherContent.qml）中增加设置按钮，点击弹出轻量配置对话框，允许用户输入固定城市名、纬度和经度。配置保存到本地 JSON 文件（`~/.config/quickshell/weather-location.json`），并加入 `.gitignore` 防止隐私泄露到 GitHub。启动时自动读取该配置并应用，替代默认的 IP 定位。
>
> **Deliverables**:
> - `.gitignore` 新增 `weather-location.json` 忽略规则
> - `Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml` 新文件：配置弹窗组件
> - `Modules/DynamicIsland/WeatherContent/WeatherContent.qml` 修改：添加设置按钮 + 弹窗调用 + JSON 读写
> - `weather-location.json` 用户自行创建的配置文件（不入 git）
>
> **Estimated Effort**: Medium（3 个文件，1 个新组件，JSON IO + 弹窗 UI）
> **Parallel Execution**: NO — 必须串行：先写弹窗组件 → 再改主面板
> **Critical Path**: Task 1 → Task 2 → Task 3 → Final QA

---

## Context

### Original Request
用户使用 Mod+I 打开 dashboard 时，天气栏的地址是根据 IP 来的，希望固定成真实的地址。同时要求：
1. 使用数据文件（如 JSON）存储位置
2. `.gitignore` 该数据文件（防止上传到 GitHub 泄露隐私）
3. 在天气栏地址旁边加一个设置位置的按钮
4. 弹窗形式：轻量对话框，含城市名、纬度、经度输入框 + 保存/取消按钮
5. 仅 dashboard 范围（WeatherContent.qml），不改动锁屏天气卡片
6. 设置按钮样式：仅图标（Material icon）

### Interview Summary
**Key Discussions**:
- 用户最初询问是否可以将地址固定为真实地址
- 方案确认：JSON 配置文件 + 设置弹窗
- 范围确认：仅 WeatherContent.qml（dashboard），不改 WeatherCard.qml
- 按钮样式：仅图标

**Research Findings**:
- `Clavis.Weather` 插件提供 `setManualLocation(lat, lon, name)`、`clearManualLocation()` 和 `hasManualLocation` 属性
- 插件自带持久化能力，但用户明确要求独立 JSON 文件（透明度、可手动编辑、备份友好）
- 代码库已有标准弹窗模式：`WallpaperColorPicker.qml` 使用 `PanelWindow` + `WlrLayer.Overlay`
- 可复用组件：`MaterialTextField.qml`（文本输入）、`DialogActionButton.qml`（操作按钮）
- 设置按钮位置：当前刷新按钮位于 `WeatherContent.qml` 第 159-209 行（地址名 Text 右侧），设置按钮应紧邻刷新按钮

### Metis Review
**Identified Gaps** (addressed):
- 插件自带持久化 vs JSON 持久化：采纳用户明确要求，以 JSON 为主持久化层，插件 `setManualLocation()` 仅作为运行时应用机制
- 弹窗模式：遵循代码库标准 `PanelWindow` + `WlrLayer.Overlay`（WallpaperColorPicker.qml 模式）
- 输入验证：纬度 [-90, 90]，经度 [-180, 180]，城市名非空
- 视觉指示：当 `hasManualLocation === true` 时，位置名旁显示小图标或后缀提示为手动设置
- 键盘交互：Escape 关闭、Tab 循环、Enter 触发保存
- 防重复点击：设置按钮用 `dialogOpen` 布尔值保护

---

## Work Objectives

### Core Objective
在 dashboard 天气面板添加一个设置按钮，点击后打开配置对话框，允许用户输入固定位置（城市名 + 经纬度）。配置保存到本地 JSON 文件，启动时自动加载。确保位置信息永不入 git。

### Concrete Deliverables
- `.gitignore` 新增忽略规则
- `WeatherLocationDialog.qml`（弹窗组件）
- `WeatherContent.qml`（设置按钮 + JSON IO + 弹窗集成）
- 运行时生成：`~/.config/quickshell/weather-location.json`

### Definition of Done
- [ ] 点击设置按钮弹出配置对话框
- [ ] 对话框预填充当前位置值（已有手动设置则填手动值，否则填 IP 定位值）
- [ ] 保存后写入 JSON 文件并立即刷新天气
- [ ] 取消后关闭对话框无改动
- [ ] 启动时检测到 JSON 则自动应用，无 JSON 则使用 IP 定位
- [ ] JSON 文件被 `.gitignore` 忽略
- [ ] 手动设置状态下，位置名旁有视觉提示

### Must Have
- 设置按钮（仅图标）位于天气地址名旁边
- PanelWindow 轻量弹窗（非全屏）
- 三个输入框：城市名（字符串）、纬度（数值）、经度（数值）
- 保存/取消按钮
- JSON 文件持久化
- `.gitignore` 保护
- 启动自动加载 JSON
- 输入边界验证（纬度 [-90,90]，经度 [-180,180]）

### Must NOT Have (Guardrails)
- 不改动 `WeatherCard.qml`（锁屏天气卡片）
- 不改动 `SidebarWeatherButton.qml`（侧边栏天气按钮）
- 不改动 `weather.py`（Python 天气脚本）
- 不改动 C++ Clavis 插件
- 不添加新 Service 单例
- 不改动 `Paths.qml`
- 不使用插件自带持久化作为主数据源（JSON 是主数据源）
- 不添加城市搜索/地理编码 API 调用（只接受原始输入）
- 不添加"最近城市"列表或历史记录
- 不添加单位切换或其他天气设置

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: NO — QML 项目无单元测试框架
- **Automated tests**: None
- **Agent-Executed QA**: 核心验证方式

### QA Policy
Every task MUST include agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **QML UI**: Playwright 无法直接测试 QML。改用 source code verification（grep/ast-grep 验证代码结构和绑定关系）
- **File system**: Bash 验证 JSON 文件创建/内容
- **Git**: Bash 验证 `.gitignore` 生效

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — foundation):
├── Task 1: .gitignore + JSON 读写工具函数 [quick]
└── Task 2: WeatherLocationDialog.qml 弹窗组件 [unspecified-high]

Wave 2 (After Wave 1 — integration):
├── Task 3: WeatherContent.qml 集成设置按钮 + 弹窗调用 + 启动加载 [unspecified-high]

Wave FINAL (After ALL tasks):
├── Task F1: Source compliance audit (oracle)
├── Task F2: Git ignore verification (quick)
└── Task F3: Real manual QA (unspecified-high)
-> Present results -> Get explicit user okay
```

### Dependency Matrix
- **Task 1**: None → 可被 Task 2 并行读取
- **Task 2**: None → 依赖 Task 1 的逻辑函数但实际文件独立
- **Task 3**: Task 1, Task 2 → 需弹窗组件和 JSON 逻辑都存在
- **F1-F3**: Task 3 → 最终验证

### Agent Dispatch Summary
- **Wave 1**: **2** tasks — T1 → `quick`, T2 → `unspecified-high`
- **Wave 2**: **1** task — T3 → `unspecified-high`
- **FINAL**: **3** tasks — F1 → `oracle`, F2 → `quick`, F3 → `unspecified-high`

---

## TODOs

- [x] 1. **`.gitignore` 新增忽略规则 + JSON 读写辅助函数**

  **What to do**:
  1. 在 `/home/eunoia/.config/quickshell/.gitignore` 末尾追加一行：`weather-location.json`
  2. 在 `WeatherContent.qml` 中添加两个辅助函数（放在 `Item` 根级别下，与其他函数并列）：
     - `readLocationConfig()`：使用 `Quickshell.Io` 或 `FileView` 读取 `~/.config/quickshell/weather-location.json`，返回 `{name, lat, lon}` 对象或 `null`
     - `writeLocationConfig(name, lat, lon)`：将对象序列化为 JSON 字符串，写入同一文件路径
  3. 在 `Component.onCompleted` 中调用 `readLocationConfig()`，如果存在且有效，立即调用 `WeatherPlugin.setManualLocation(lat, lon, name)` 并 `WeatherPlugin.refresh()`

  **Must NOT do**:
  - 不创建新的 Service 单例
  - 不改动 `Paths.qml`
  - 不在 `weather.py` 中添加任何逻辑

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 简单文件修改和函数添加，逻辑直接
  - **Skills**: []
    - 不需要特殊技能

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 2)
  - **Blocks**: Task 3 (需要 JSON 函数存在)
  - **Blocked By**: None

  **References**:
  - `Modules/ControlCenter/WallpaperColorPicker.qml:122` — `Quickshell.execDetached` 用法参考（虽然这里应该用 FileView/Io）
  - 代码库中的 `FileView` 用法：需要搜索 `FileView` 或 `Quickshell.Io` 的使用模式
  - `WeatherContent.qml:31-35` — `Component.onCompleted` 现有启动逻辑的位置

  **Acceptance Criteria**:
  - [ ] `.gitignore` 包含 `weather-location.json`
  - [ ] `WeatherContent.qml` 中有 `readLocationConfig` 函数
  - [ ] `WeatherContent.qml` 中有 `writeLocationConfig` 函数
  - [ ] `Component.onCompleted` 中在现有逻辑之后加入 JSON 读取和应用

  **QA Scenarios**:

  ```
  Scenario: .gitignore 生效验证
    Tool: Bash
    Preconditions: .gitignore 已修改
    Steps:
      1. echo '{"name":"Test","lat":0,"lon":0}' > /home/eunoia/.config/quickshell/weather-location.json
      2. cd /home/eunoia/.config/quickshell && git check-ignore weather-location.json
    Expected Result: 命令输出包含 "weather-location.json"
    Evidence: .sisyphus/evidence/task-1-gitignore.{ext}
  ```

  ```
  Scenario: JSON 函数存在性验证
    Tool: grep
    Preconditions: WeatherContent.qml 已修改
    Steps:
      1. grep -n "readLocationConfig" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml
      2. grep -n "writeLocationConfig" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml
      3. grep -n "weather-location.json" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml
    Expected Result: 所有 grep 都返回至少一行匹配
    Evidence: .sisyphus/evidence/task-1-json-functions.{ext}
  ```

  **Evidence to Capture**:
  - [ ] `.gitignore` 文件内容截图/文本
  - [ ] grep 结果截图

  **Commit**: NO (与 Task 2, 3 一起提交)

---

- [x] 2. **`WeatherLocationDialog.qml` 弹窗组件**

  **What to do**:
  1. 在 `Modules/DynamicIsland/WeatherContent/` 目录下创建新文件 `WeatherLocationDialog.qml`
  2. 参考 `WallpaperColorPicker.qml` 的 `PanelWindow` + `WlrLayer.Overlay` 模式，但做成轻量小弹窗（宽度约 400，高度约 320，居中显示）
  3. 组件接口：
     - `property bool shouldBeVisible: false` — 控制显示/隐藏
     - `property string initialCity: ""` — 初始城市名
     - `property real initialLat: 0` — 初始纬度
     - `property real initialLon: 0` — 初始经度
     - `property bool hasManualLocation: false` — 是否已手动设置（控制"恢复自动定位"按钮可见性）
     - `signal saved(string name, real lat, real lon)` — 保存时发出
     - `signal cleared()` — 恢复自动定位时发出
     - `signal cancelled()` — 取消时发出
  4. 弹窗内部布局（从上到下）：
     - 标题栏："设置位置" + 关闭图标按钮
     - 城市名输入框（`MaterialTextField`）：placeholder "城市名称（如：上海）"
     - 纬度输入框（`MaterialTextField`）：placeholder "纬度（-90 ~ 90）"
     - 经度输入框（`MaterialTextField`）：placeholder "经度（-180 ~ 180）"
     - "恢复自动定位"按钮：仅当 `hasManualLocation === true` 时显示，点击发出 `cleared()`
     - 底部按钮行：取消（`DialogActionButton`）+ 保存（`DialogActionButton`，`filled: true`）
  5. 交互细节：
     - Escape 键关闭弹窗（发出 cancelled）
     - 点击弹窗外区域关闭弹窗
     - 弹窗内 MouseArea 阻止点击穿透
     - 保存时验证：纬度 [-90, 90]，经度 [-180, 180]，城市名非空。验证失败时输入框边框变红（使用 `Material.accent` 或边框色），不关闭弹窗
     - Tab 键在三个输入框间循环
  6. 打开弹窗时，将 `initialCity/initialLat/initialLon` 同步到输入框的 `text` 属性
  7. 样式：使用 `Appearance.m3colors.m3surfaceContainerLow` 作为背景，`Appearance.rounding.normal` 作为圆角，`Appearance.animation.standard` 作为动画时长

  **Must NOT do**:
  - 不创建全屏弹窗（参考 WallpaperColorPicker 的尺寸策略，但缩小）
  - 不引入新的输入组件（必须使用 `MaterialTextField`）
  - 不调用 `WeatherPlugin` 方法（只发信号，由父组件处理）
  - 不直接操作文件 IO（只发信号）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 需要仔细参考现有弹窗模式，复用组件，确保交互细节正确
  - **Skills**: []
    - 不需要特殊技能，但需要仔细模仿现有代码风格

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 1)
  - **Blocks**: Task 3 (需要弹窗组件存在)
  - **Blocked By**: None

  **References**:
  - `Modules/ControlCenter/WallpaperColorPicker.qml:143-201` — `PanelWindow` + `WlrLayer.Overlay` + `WlrKeyboardFocus.Exclusive` + 外部点击关闭模式
  - `Modules/ControlCenter/WallpaperColorPicker.qml:173-199` — `FocusScope` + `Keys.onEscapePressed` + 内部 `MouseArea` 阻止点击穿透
  - `MaterialTextField.qml` — 输入框样式和属性
  - `DialogActionButton.qml` — 按钮样式和 `filled` 属性
  - `WeatherContent.qml:150-209` — 现有地址名和刷新按钮的布局（设置按钮将插入此处）

  **WHY Each Reference Matters**:
  - WallpaperColorPicker 是代码库中最接近的弹窗模式，必须遵循其 PanelWindow 结构
  - MaterialTextField/DialogActionButton 是代码库标准组件，保持视觉一致性
  - WeatherContent 中的地址区域决定了设置按钮的布局位置

  **Acceptance Criteria**:
  - [ ] 文件创建：`Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml`
  - [ ] 使用 `PanelWindow` + `WlrLayer.Overlay`
  - [ ] 包含三个 `MaterialTextField` 输入框
  - [ ] 包含保存/取消按钮（`DialogActionButton`）
  - [ ] 包含"恢复自动定位"按钮（条件显示）
  - [ ] Escape 关闭、外部点击关闭
  - [ ] 保存时验证输入范围
  - [ ] 信号接口完整（saved/cleared/cancelled）

  **QA Scenarios**:

  ```
  Scenario: 弹窗组件文件验证
    Tool: Bash / grep
    Preconditions: 文件已创建
    Steps:
      1. ls /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml
      2. grep -n "PanelWindow" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml
      3. grep -n "MaterialTextField" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml
      4. grep -n "DialogActionButton" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml
      5. grep -n "saved" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml
      6. grep -n "cleared" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml
      7. grep -n "cancelled" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml
    Expected Result: 所有 grep 都返回至少一行匹配
    Evidence: .sisyphus/evidence/task-2-dialog-structure.{ext}
  ```

  ```
  Scenario: 验证弹窗不使用全屏尺寸
    Tool: grep
    Preconditions: 文件已创建
    Steps:
      1. grep -n "width" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml | grep -v "implicitWidth"
      2. grep -n "height" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml | grep -v "implicitHeight"
    Expected Result: 弹窗尺寸应合理（宽度 <= 500，高度 <= 400）
    Evidence: .sisyphus/evidence/task-2-dialog-size.{ext}
  ```

  **Evidence to Capture**:
  - [ ] 弹窗文件内容截图/文本

  **Commit**: NO (与 Task 1, 3 一起提交)

---

- [x] 3. **`WeatherContent.qml` 集成：设置按钮 + 弹窗实例化 + JSON 联动**

  **What to do**:
  1. 在 `WeatherContent.qml` 中导入新弹窗组件：`import "./WeatherLocationDialog.qml" as WeatherDialogs` 或直接相对路径引用
  2. 在地址名显示区域（`infoSection` 内的 `Row`，第 148-210 行）添加设置图标按钮：
     - 紧挨刷新按钮右侧，尺寸 24x24，圆角 12
     - 图标使用 Material Symbols Outlined 字体，名称 `edit_location` 或 `location_on`
     - hover 时颜色变为 `Appearance.colors.colPrimary`
     - 点击时打开弹窗（设置 `dialog.shouldBeVisible = true`）
     - 使用 `dialogOpen` 布尔属性防止重复打开
  3. 在根 `Item` 下添加弹窗实例：
     ```qml
     WeatherLocationDialog {
         id: locationDialog
         shouldBeVisible: false
         initialCity: WeatherPlugin.locationName || ""
         initialLat: WeatherPlugin.latitude || 0
         initialLon: WeatherPlugin.longitude || 0
         hasManualLocation: WeatherPlugin.hasManualLocation
         onSaved: (name, lat, lon) => {
             writeLocationConfig(name, lat, lon)
             WeatherPlugin.setManualLocation(lat, lon, name)
             WeatherPlugin.refresh()
         }
         onCleared: () => {
             clearLocationConfig()  // 删除 JSON 文件
             WeatherPlugin.clearManualLocation()
             WeatherPlugin.refresh()
         }
         onCancelled: () => {
             locationDialog.shouldBeVisible = false
         }
     }
     ```
  4. 实现 `clearLocationConfig()` 函数：删除 `~/.config/quickshell/weather-location.json`
  5. 在手动设置状态下，给位置名添加视觉提示：
     - 当 `WeatherPlugin.hasManualLocation === true` 时，在位置名 Text 后附加一个小图标（如 `edit_location`，尺寸 12，颜色 `Appearance.colors.colOnSurfaceVariant`）
     - 或者在位置名 Text 的 `text` 属性后加一个小点/星号（不推荐，用图标更直观）
  6. 确保 `readLocationConfig` 的 `Component.onCompleted` 调用在 `syncWeatherData()` 之后或之前正确执行，不冲突

  **Must NOT do**:
  - 不改 `WeatherCard.qml`、`SidebarWeatherButton.qml`
  - 不改 `weather.py`
  - 不添加新 Service
  - 不使用硬编码颜色/尺寸（全部使用 Appearance.* 和 Sizes.*）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 需要精确修改现有 UI 布局，集成新组件，处理信号绑定，易出错
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocked By**: Task 1 (JSON 函数), Task 2 (弹窗组件)
  - **Blocks**: Final Verification

  **References**:
  - `WeatherContent.qml:148-210` — 地址名和刷新按钮所在 Row，设置按钮插入位置
  - `WeatherContent.qml:31-35` — `Component.onCompleted` 现有启动逻辑
  - `WallpaperColorPicker.qml` — 弹窗实例化在父组件中的模式
  - `ClavisWeather.qmltypes:82-88` — `hasManualLocation` 属性（bool, read, notify: dataChanged）
  - `ClavisWeather.qmltypes:286-294` — `setManualLocation`, `clearManualLocation` 方法签名

  **WHY Each Reference Matters**:
  - WeatherContent 的地址区域布局决定了设置按钮的精确位置和尺寸约束
  - Component.onCompleted 是添加启动自动加载逻辑的正确生命周期钩子
  - hasManualLocation 是显示视觉提示和"恢复自动定位"按钮的条件来源

  **Acceptance Criteria**:
  - [ ] `WeatherContent.qml` 中存在设置图标按钮（grep `edit_location` 或 `location_on` + `MouseArea` + `onClicked`）
  - [ ] 存在 `WeatherLocationDialog` 实例（grep `WeatherLocationDialog`）
  - [ ] `onSaved` 信号处理器调用 `writeLocationConfig` + `setManualLocation` + `refresh`
  - [ ] `onCleared` 信号处理器调用 `clearLocationConfig` + `clearManualLocation` + `refresh`
  - [ ] 存在 `hasManualLocation` 视觉提示（grep `hasManualLocation`）
  - [ ] 未修改范围外文件

  **QA Scenarios**:

  ```
  Scenario: 设置按钮存在性验证
    Tool: grep
    Preconditions: WeatherContent.qml 已修改
    Steps:
      1. grep -n "MouseArea" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml | head -5
      2. grep -n "edit_location\|location_on" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml
      3. grep -n "WeatherLocationDialog" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml
    Expected Result: 存在新的 MouseArea，存在图标名引用，存在弹窗组件引用
    Evidence: .sisyphus/evidence/task-3-settings-button.{ext}
  ```

  ```
  Scenario: 信号绑定验证
    Tool: grep
    Preconditions: WeatherContent.qml 已修改
    Steps:
      1. grep -n "onSaved" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml
      2. grep -n "onCleared" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml
      3. grep -n "setManualLocation" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml
      4. grep -n "clearManualLocation" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml
    Expected Result: 所有信号和插件方法都被引用
    Evidence: .sisyphus/evidence/task-3-signal-bindings.{ext}
  ```

  ```
  Scenario: 范围外文件未修改验证
    Tool: git
    Preconditions: 所有修改已完成
    Steps:
      1. cd /home/eunoia/.config/quickshell && git diff --name-only
    Expected Result: 仅输出 WeatherContent.qml、WeatherLocationDialog.qml、.gitignore
    Evidence: .sisyphus/evidence/task-3-scope-check.{ext}
  ```

  **Evidence to Capture**:
  - [ ] 设置按钮区域代码截图
  - [ ] 弹窗实例化代码截图
  - [ ] git diff --name-only 输出

  **Commit**: YES
  - Message: `feat(weather): add manual location configuration dialog`
  - Files: `.gitignore`, `Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml`, `Modules/DynamicIsland/WeatherContent/WeatherContent.qml`

---

## Final Verification Wave

> 3 review agents run in PARALLEL. ALL must APPROVE. Present results to user.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. Verify each deliverable exists, each guardrail respected (no scope leak). Check evidence files exist.
  Output: `Deliverables [N/N] | Guardrails [N/N] | VERDICT`

- [x] F2. **Git Ignore Verification** — `quick`
  Create a dummy `weather-location.json`, run `git check-ignore weather-location.json`, verify it returns the file path (ignored). Clean up dummy file.
  Output: `Git Ignore [PASS/FAIL] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`
  Source-level verification: read all modified/new files, verify:
  - Settings icon button exists with MouseArea + onClicked
  - Dialog uses PanelWindow + WlrLayer.Overlay
  - Dialog has 3 MaterialTextField inputs with correct bindings
  - Save button writes JSON via Quickshell.Io and calls setManualLocation + refresh
  - Cancel button closes dialog
  - JSON read logic exists in Component.onCompleted
  - hasManualLocation visual indicator exists
  - No modifications to forbidden files (WeatherCard.qml, SidebarWeatherButton.qml, weather.py)
  Output: `Checks [N/N] | VERDICT`

---

## Commit Strategy

- **1**: `feat(weather): add manual location configuration dialog`
  - Files: `.gitignore`, `Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml`, `Modules/DynamicIsland/WeatherContent/WeatherContent.qml`

---

## Success Criteria

### Verification Commands
```bash
# Verify .gitignore
grep "weather-location.json" /home/eunoia/.config/quickshell/.gitignore

# Verify new dialog file exists
ls /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherLocationDialog.qml

# Verify JSON read/write functions exist in WeatherContent.qml
grep -n "weather-location.json" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml

# Verify setManualLocation called
grep -n "setManualLocation" /home/eunoia/.config/quickshell/Modules/DynamicIsland/WeatherContent/WeatherContent.qml

# Verify no forbidden files modified
git diff --name-only | grep -v "WeatherContent.qml" | grep -v "WeatherLocationDialog.qml" | grep -v ".gitignore"
```

### Final Checklist
- [ ] 所有 "Must Have" 已实现
- [ ] 所有 "Must NOT Have" 已遵守
- [ ] `.gitignore` 生效（git check-ignore 通过）
- [ ] 未修改范围外文件
- [ ] 代码使用 Appearance.* 设计令牌（无硬编码颜色/尺寸）
