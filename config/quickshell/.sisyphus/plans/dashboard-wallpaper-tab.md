# Dashboard 壁纸 Tab 功能实施计划

## TL;DR

> **Quick Summary**: 在现有 dashboard（`modules/Clock.qml`）中新增“壁纸”tab，读取 `~/Wallpapers/`（png/jpg/jpeg/webp）并展示横向可滚动预览；支持 Left/Right（wrap）切换、非线性动画、选中项放大；Enter 执行 `awww img ...` 并自动关闭 dashboard。  
> **Deliverables**:
> - Dashboard 顶部新增 “壁纸” tab 与内容面板
> - 壁纸数据加载/筛选/排序模型（`~/Wallpapers/`）
> - 键盘导航 + 选中态非线性动画 + 视图滚动对齐
> - Enter 应用壁纸（`awww`）并关闭窗口
> - 完整 agent-executed QA 场景与证据
>
> **Estimated Effort**: Medium  
> **Parallel Execution**: YES - 3 waves + final verification  
> **Critical Path**: T1 → T3 → T6 → T8 → T9 → Final

---

## Context

### Original Request
用户要求在 dashboard 的“日历”“媒体”旁增加“壁纸”tab：
- 切到“壁纸”tab时显示 `~/Wallpapers/` 下壁纸预览
- 横向一排，可左右滚动
- Left/Right 键切换，带动画
- 当前选中壁纸放大，其他较小，使用非线性动画
- Enter 确认应用壁纸并自动关闭 dashboard
- 使用 `awww img` 切换（含指定 transition 参数）

### Interview Summary
**Key Discussions**:
- 壁纸目录：`~/Wallpapers/`
- 扩展名：`png/jpg/jpeg/webp`
- 边界行为：`wrap`
- 初始选中：当前正在使用的壁纸
- 应用命令：
  - `awww img "$NEXT" --transition-type any --transition-bezier ".23,.43,.69,-0.29" --transition-step 90 --transition-fps 120 >>/tmp/niri-wallpaper.log 2>&1`
- 测试策略：不新增自动化测试基础设施（“直接做”）

**Research Findings**:
- Dashboard tab 声明、切换、内容渲染和关闭生命周期集中在 `modules/Clock.qml`
- 键盘与 Process 模式可参考 `modules/Network.qml`
- 选中态/动画模式可参考 `modules/Workspaces.qml` 与 `modules/Clock.qml` 内现有动画
- 面板关闭/生命周期可参考 `modules/Volume.qml`、`modules/Notifications.qml`

### Metis Review
**Identified Gaps** (addressed in this plan):
- 当前壁纸识别策略可能失败（软链接/绝对路径差异）→ 增加标准化路径匹配 + fallback
- 空目录/加载失败/命令失败场景需明确 → 增加错误态 UI 与 QA 场景
- 键盘焦点丢失导致 Left/Right 不触发 → 增加 tab 激活时强制聚焦策略
- 范围膨胀风险（递归扫描、复杂缓存、多显示器）→ 明确排除

---

## Work Objectives

### Core Objective
在不破坏现有 Calendar/Media 体验的前提下，最小侵入扩展 `modules/Clock.qml`，交付可键盘操作、动画平滑、可落地应用壁纸并自动关闭的 Wallpaper tab。

### Concrete Deliverables
- `modules/Clock.qml`：新增 tab 元素与 `currentTab===2` 内容面板
- `modules/Clock.qml`：新增 wallpaper 数据模型、选择索引、键盘处理、apply Process
- `modules/Clock.qml`：新增空态/错误态提示与命令执行后关闭流程
- `.sisyphus/evidence/`：每个任务场景的运行证据

### Definition of Done
- [ ] 进入 dashboard 可见“壁纸”tab，点击可切换到壁纸面板
- [ ] 从 `~/Wallpapers/` 加载 `png/jpg/jpeg/webp`，展示为横向预览列表
- [ ] Left/Right 键可循环切换（wrap），选中项明显放大，动画为非线性
- [ ] Enter 执行 `awww img ...` 应用选中壁纸，并自动关闭 dashboard
- [ ] 空目录/命令失败不会崩溃，用户可见状态反馈

### Must Have
- 使用用户给定 `awww` 参数模板执行
- 初始选中尽量对齐当前生效壁纸
- wrap 导航
- agent 可执行验证，无需人工手测

### Must NOT Have (Guardrails)
- 不改动日历/媒体业务逻辑（仅必要 wiring）
- 不引入新的测试框架/CI 基建
- 不扩展到递归扫描子目录、多显示器差异化配置、在线壁纸源
- 不使用阻塞式命令导致 UI 卡死

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** - 所有验证由执行 agent 完成。

### Test Decision
- **Infrastructure exists**: 未检测到可复用自动化测试基础设施（按当前工作区扫描）
- **Automated tests**: None（按用户“直接做”决策）
- **Framework**: none（本任务不新增）

### QA Policy
每个任务都包含 agent-executed QA 场景（happy + error/edge），并生成证据文件：
` .sisyphus/evidence/task-{N}-{scenario-slug}.{ext} `

- **UI/交互**: 使用 Playwright 或等效可视化验证方式（若环境不支持则用日志+截图替代）
- **命令/API**: 使用 Bash 执行命令并断言退出/日志
- **模块行为**: 使用运行日志、状态文本、UI状态快照交叉验证

---

## Execution Strategy

### Parallel Execution Waves

```text
Wave 1 (Foundation - 可并行):
├── T1: 现有 dashboard 结构锚点与最小改动点固定 [quick]
├── T2: 壁纸数据源与过滤/排序策略实现 [quick]
├── T3: 当前壁纸识别与初始索引策略 [unspecified-high]
├── T4: awww 执行器与日志/错误回传 [quick]
└── T5: 动画参数与缩放曲线定义（非线性） [visual-engineering]

Wave 2 (Feature Assembly - 可并行):
├── T6: 新增“壁纸”tab与内容容器接线 [quick] (depends: T1)
├── T7: 横向预览列表与焦点样式落地 [visual-engineering] (depends: T2,T5)
├── T8: Left/Right wrap 导航与焦点管理 [unspecified-high] (depends: T3,T7)
└── T9: Enter 应用壁纸 + 自动关闭 dashboard [quick] (depends: T4,T8)

Wave 3 (Hardening - 可并行):
├── T10: 空态/错误态/降级路径处理 [unspecified-high] (depends: T6,T9)
└── T11: 集成回归与证据归档 [quick] (depends: T6~T10)

Wave FINAL (4 parallel reviews):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Real manual QA replay (unspecified-high)
└── F4: Scope fidelity check (deep)
```

### Dependency Matrix

- **T1**: Blocked By: None → Blocks: T6
- **T2**: Blocked By: None → Blocks: T7
- **T3**: Blocked By: None → Blocks: T8
- **T4**: Blocked By: None → Blocks: T9
- **T5**: Blocked By: None → Blocks: T7
- **T6**: Blocked By: T1 → Blocks: T10, T11
- **T7**: Blocked By: T2, T5 → Blocks: T8, T11
- **T8**: Blocked By: T3, T7 → Blocks: T9, T11
- **T9**: Blocked By: T4, T8 → Blocks: T10, T11
- **T10**: Blocked By: T6, T9 → Blocks: T11
- **T11**: Blocked By: T6, T7, T8, T9, T10 → Blocks: FINAL

### Agent Dispatch Summary

- **Wave 1**: T1/T2/T4→`quick`, T3→`unspecified-high`, T5→`visual-engineering`
- **Wave 2**: T6→`quick`, T7→`visual-engineering`, T8→`unspecified-high`, T9→`quick`
- **Wave 3**: T10→`unspecified-high`, T11→`quick`
- **Final**: F1→`oracle`, F2/F3→`unspecified-high`, F4→`deep`

---

## TODOs

- [x] 1. 固定改动锚点（Clock tab 架构）

  **What to do**:
  - 在 `modules/Clock.qml` 中确认 tab `ListModel`、`Repeater`、`currentTab`、内容区 `visible: root.currentTab===N` 的具体锚点。
  - 仅标记新增“壁纸”tab所需最小改动区域，避免误触 Calendar/Media 逻辑。

  **Must NOT do**:
  - 不重构现有 tab 架构。
  - 不改动 Calendar/Media 数据逻辑。

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 定位与最小接线任务，范围小。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T6
  - **Blocked By**: None

  **References**:
  - `modules/Clock.qml` - tab 模型、tab 切换和内容显示主文件。
  - `modules/Volume.qml` - 面板显示/关闭生命周期参考。

  **Acceptance Criteria**:
  - [ ] 明确新增 tab 与内容块插入点（文件级 + 区块级）。
  - [ ] 未修改任何非目标逻辑。

  **QA Scenarios**:
  ```
  Scenario: 锚点确认
    Tool: Bash
    Preconditions: 工作区可读取
    Steps:
      1. 打开 modules/Clock.qml，定位 ListModel/Repeater/currentTab 相关区块
      2. 记录插入点（tab 列表 + 内容面板）
    Expected Result: 插入点明确且唯一
    Failure Indicators: 无法定位或需大范围改动
    Evidence: .sisyphus/evidence/task-1-anchor-map.txt

  Scenario: 非目标变更防护
    Tool: Bash
    Preconditions: 完成初步修改后
    Steps:
      1. 查看变更文件列表
      2. 确认仅限目标文件与区域
    Expected Result: 无 Calendar/Media 非必要改动
    Evidence: .sisyphus/evidence/task-1-scope-guard.txt
  ```

- [x] 2. 实现壁纸数据源加载（目录+扩展过滤）

  **What to do**:
  - 从 `~/Wallpapers/` 读取文件。
  - 过滤扩展名：`png/jpg/jpeg/webp`（大小写兼容）。
  - 构建用于 UI 展示的模型（路径、显示名、排序键）。

  **Must NOT do**:
  - 不递归扫描子目录（当前范围排除）。
  - 不引入额外缓存系统。

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 数据装载与过滤属于直接实现。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T7
  - **Blocked By**: None

  **References**:
  - `modules/Clock.qml` - 本任务目标模型定义位置。
  - `modules/Network.qml` - Process/异步命令模式参考。

  **Acceptance Criteria**:
  - [ ] 仅包含四类扩展名文件。
  - [ ] 空目录时模型为空但不报崩溃。

  **QA Scenarios**:
  ```
  Scenario: 正常加载支持格式
    Tool: Bash
    Preconditions: ~/Wallpapers 中含 png/jpg/jpeg/webp
    Steps:
      1. 打开壁纸 tab
      2. 观察模型项数量与文件数量一致（仅支持格式）
    Expected Result: 列表正确显示支持格式
    Failure Indicators: 漏图或出现不支持格式
    Evidence: .sisyphus/evidence/task-2-load-happy.txt

  Scenario: 空目录降级
    Tool: Bash
    Preconditions: ~/Wallpapers 暂时为空
    Steps:
      1. 打开壁纸 tab
      2. 检查 UI 空态文本
    Expected Result: 显示空态，不崩溃
    Evidence: .sisyphus/evidence/task-2-empty-state.txt
  ```

- [x] 3. 当前壁纸识别与初始索引匹配

  **What to do**:
  - 读取当前生效壁纸信息（结合现有运行环境可用方式）。
  - 将当前壁纸路径标准化后与模型比对，命中则设为初始选中。
  - 未命中时 fallback 到第一项。

  **Must NOT do**:
  - 不假设路径格式总是完全一致（需规范化比较）。

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 涉及环境差异、路径匹配与回退策略。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T8
  - **Blocked By**: None

  **References**:
  - `modules/Clock.qml` - 初始状态注入与 tab 激活时机。
  - 用户提供命令模式（awww） - 路径来源一致性参考。

  **Acceptance Criteria**:
  - [ ] 当前壁纸在列表中时，默认选中该项。
  - [ ] 未匹配时稳定回落到第 1 项。

  **QA Scenarios**:
  ```
  Scenario: 命中当前壁纸
    Tool: Bash
    Preconditions: 当前壁纸文件位于 ~/Wallpapers 且在模型中
    Steps:
      1. 打开壁纸 tab
      2. 检查选中项是否为当前生效文件
    Expected Result: 初始高亮即当前壁纸
    Failure Indicators: 选中偏移到其他项
    Evidence: .sisyphus/evidence/task-3-current-match.txt

  Scenario: 未命中回退
    Tool: Bash
    Preconditions: 当前壁纸不在 ~/Wallpapers
    Steps:
      1. 打开壁纸 tab
      2. 检查默认索引
    Expected Result: 默认选中第一项
    Evidence: .sisyphus/evidence/task-3-fallback-first.txt
  ```

- [x] 4. awww 执行器封装与日志落盘

  **What to do**:
  - 使用 Process 执行用户给定命令模板。
  - 参数包含 `--transition-type any --transition-bezier ".23,.43,.69,-0.29" --transition-step 90 --transition-fps 120`。
  - 输出追加到 `/tmp/niri-wallpaper.log`。

  **Must NOT do**:
  - 不硬编码不存在的路径变量。
  - 不吞掉失败结果（需可观测）。

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 命令拼装与调用，路径清晰。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T9
  - **Blocked By**: None

  **References**:
  - `modules/Network.qml` - Process 调用与生命周期模式。
  - 用户命令样例 - 参数必须一致。

  **Acceptance Criteria**:
  - [ ] 执行命令与用户提供模板参数一致。
  - [ ] 日志写入 `/tmp/niri-wallpaper.log`。

  **QA Scenarios**:
  ```
  Scenario: 成功执行 awww
    Tool: Bash
    Preconditions: awww 可执行、目标文件有效
    Steps:
      1. 在壁纸 tab 选定一张图
      2. 触发应用
      3. 检查 /tmp/niri-wallpaper.log 新增记录
    Expected Result: 命令成功执行并有日志
    Failure Indicators: 命令未触发或无日志
    Evidence: .sisyphus/evidence/task-4-awww-success.txt

  Scenario: 执行失败可观测
    Tool: Bash
    Preconditions: 构造不可用文件路径
    Steps:
      1. 触发应用
      2. 检查日志错误信息
    Expected Result: 失败信息可见，不导致崩溃
    Evidence: .sisyphus/evidence/task-4-awww-failure.txt
  ```

- [x] 5. 非线性动画曲线与选中放大规格定义

  **What to do**:
  - 定义选中项 scale 与非选中项 scale（例如 1.00 vs 0.85）。
  - 使用非线性 easing（OutCubic / OutBack 或等价）。
  - 统一动画时长并避免跳变。

  **Must NOT do**:
  - 不使用线性匀速动画替代。
  - 不出现瞬间缩放突变。

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: 核心是视觉动效体验。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T7
  - **Blocked By**: None

  **References**:
  - `modules/Workspaces.qml` - 焦点视觉变化模式。
  - `modules/Clock.qml` - 现有动画节奏。

  **Acceptance Criteria**:
  - [ ] 选中项明显大于非选中项。
  - [ ] 动画观感非线性且平滑。

  **QA Scenarios**:
  ```
  Scenario: 选中放大效果
    Tool: Playwright
    Preconditions: 壁纸列表>=3
    Steps:
      1. 打开壁纸 tab
      2. 连续按 Right 两次
      3. 比较当前项与相邻项尺寸
    Expected Result: 当前项显著更大
    Failure Indicators: 尺寸几乎一致或无动画
    Evidence: .sisyphus/evidence/task-5-scale.png

  Scenario: easing 非线性
    Tool: Playwright
    Preconditions: 可记录过渡截图序列
    Steps:
      1. 切换一次索引并抓取过渡帧
      2. 对比前中后阶段速度变化
    Expected Result: 过渡速度变化明显（非匀速）
    Evidence: .sisyphus/evidence/task-5-easing.png
  ```

- [x] 6. 新增“壁纸”tab 与内容容器接线

  **What to do**:
  - 在 tab `ListModel` 新增 `壁纸` 项。
  - 在内容区域新增 `currentTab===2` 容器。
  - 维持与现有 tab 的同层结构与显示逻辑。

  **Must NOT do**:
  - 不改动日历/媒体业务内容。
  - 不破坏既有 tab 索引交互。

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 明确 wiring 操作。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2
  - **Blocks**: T10, T11
  - **Blocked By**: T1

  **References**:
  - `modules/Clock.qml` - tab 声明、currentTab 分支渲染。

  **Acceptance Criteria**:
  - [ ] 头部可见“壁纸”tab。
  - [ ] 切换后出现壁纸内容容器。

  **QA Scenarios**:
  ```
  Scenario: tab 接入成功
    Tool: Playwright
    Preconditions: dashboard 可打开
    Steps:
      1. 打开 dashboard
      2. 点击“壁纸”tab
      3. 检查内容切换
    Expected Result: 壁纸容器显示
    Failure Indicators: tab 不显示或切换无反应
    Evidence: .sisyphus/evidence/task-6-tab.png

  Scenario: 既有 tab 回归
    Tool: Playwright
    Preconditions: 同上
    Steps:
      1. 切回日历/媒体
      2. 检查内容正常
    Expected Result: 旧功能不受影响
    Evidence: .sisyphus/evidence/task-6-regression.png
  ```

- [x] 7. 横向预览列表与滚动对齐实现

  **What to do**:
  - 实现横向单行预览展示。
  - 选中变化时保证当前项可见并优先居中。
  - 使用稳定缩略比例，避免拉伸变形。

  **Must NOT do**:
  - 不做纵向列表替代。
  - 不出现滚动抖动。

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: 列表布局与可视对齐。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: T8, T11
  - **Blocked By**: T2, T5

  **References**:
  - `modules/Clock.qml` - 现有容器布局。
  - `modules/Workspaces.qml` - 焦点偏移视觉参考。

  **Acceptance Criteria**:
  - [ ] 一排横向预览可浏览。
  - [ ] 索引变化时当前项保持可见。

  **QA Scenarios**:
  ```
  Scenario: 长列表横向浏览
    Tool: Playwright
    Preconditions: 壁纸>=10
    Steps:
      1. 打开壁纸 tab
      2. 连续按 Right 至末端附近
      3. 检查当前项是否始终可见
    Expected Result: 当前项始终在可视区
    Failure Indicators: 当前项滚出屏幕
    Evidence: .sisyphus/evidence/task-7-scroll.png

  Scenario: 少量数据布局
    Tool: Playwright
    Preconditions: 壁纸<=3
    Steps:
      1. 打开壁纸 tab
      2. 左右切换检查布局
    Expected Result: 无错位、无闪烁
    Evidence: .sisyphus/evidence/task-7-small.png
  ```

- [ ] 8. Left/Right wrap 导航与焦点管理

  **What to do**:
  - 壁纸 tab 激活时自动聚焦按键容器。
  - Left/Right 执行索引变化 + wrap。
  - 仅在壁纸 tab 吞键，避免影响其他 tab。

  **Must NOT do**:
  - 不要求用户先鼠标点击才能键盘导航。
  - 不在非壁纸 tab 抢占左右键。

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 焦点与按键路由复杂度较高。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: T9, T11
  - **Blocked By**: T3, T7

  **References**:
  - `modules/Network.qml` - Keys 事件写法。
  - `modules/Clock.qml` - tab 激活生命周期。

  **Acceptance Criteria**:
  - [ ] Left/Right 可循环切换。
  - [ ] tab 来回切换后仍可直接按键操作。

  **QA Scenarios**:
  ```
  Scenario: wrap 边界验证
    Tool: Playwright
    Preconditions: 列表>=2
    Steps:
      1. 第一项按 Left
      2. 末项按 Right
    Expected Result: 首尾互转成功
    Failure Indicators: 卡边不动或异常
    Evidence: .sisyphus/evidence/task-8-wrap.txt

  Scenario: 焦点恢复验证
    Tool: Playwright
    Preconditions: 可切tab
    Steps:
      1. 壁纸→媒体→壁纸
      2. 直接按 Right
    Expected Result: 立即响应键盘
    Evidence: .sisyphus/evidence/task-8-focus.txt
  ```

- [ ] 9. Enter 应用壁纸并自动关闭 dashboard

  **What to do**:
  - Enter 触发 `awww img "$NEXT" ...` 应用当前选中。
  - 应用触发后关闭 dashboard（复用现有关闭生命周期）。
  - 防止重复触发（短时防抖/状态锁）。

  **Must NOT do**:
  - 不在无选中项时盲目执行命令。
  - 不关闭失败时静默无反馈。

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 命令触发 + close wiring。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2
  - **Blocks**: T10, T11
  - **Blocked By**: T4, T8

  **References**:
  - `modules/Clock.qml` - dashboardOpen 关闭流。
  - `modules/Network.qml` - Process 调用模式。

  **Acceptance Criteria**:
  - [ ] Enter 后命令触发且窗口关闭。
  - [ ] 连续按 Enter 不会触发多次并发执行。

  **QA Scenarios**:
  ```
  Scenario: Enter 成功路径
    Tool: Playwright + Bash
    Preconditions: 可用壁纸项、awww 可执行
    Steps:
      1. 打开壁纸 tab，选中某项
      2. 按 Enter
      3. 检查窗口关闭 + 日志更新
    Expected Result: 应用成功并关闭 dashboard
    Failure Indicators: 未关闭或未执行命令
    Evidence: .sisyphus/evidence/task-9-enter-success.txt

  Scenario: 重复按 Enter 防抖
    Tool: Playwright + Bash
    Preconditions: 同上
    Steps:
      1. 快速连按 Enter
      2. 检查日志触发次数
    Expected Result: 单次有效执行（或受控次数）
    Evidence: .sisyphus/evidence/task-9-enter-debounce.txt
  ```

- [ ] 10. 空态/错误态/降级处理

  **What to do**:
  - 空目录显示空态提示。
  - 加载失败/命令失败给出可见提示（文本或状态区）。
  - 当前壁纸识别失败时回退首项并提示可继续操作。

  **Must NOT do**:
  - 不因异常导致面板不可交互。
  - 不将错误仅写日志而无 UI 反馈。

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 异常分支与用户可观测性。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: T11
  - **Blocked By**: T6, T9

  **References**:
  - `modules/Clock.qml` - 状态显示区域接入点。
  - `/tmp/niri-wallpaper.log` - 错误证据来源。

  **Acceptance Criteria**:
  - [ ] 空目录有明确空态文案。
  - [ ] 错误路径有可见提示且不崩溃。

  **QA Scenarios**:
  ```
  Scenario: 空目录提示
    Tool: Playwright
    Preconditions: ~/Wallpapers 为空
    Steps:
      1. 打开壁纸 tab
      2. 检查提示文本
    Expected Result: 空态文案显示
    Evidence: .sisyphus/evidence/task-10-empty-ui.png

  Scenario: 命令失败提示
    Tool: Bash + Playwright
    Preconditions: 构造失败命令条件
    Steps:
      1. 按 Enter 触发失败
      2. 查看 UI 提示与日志
    Expected Result: UI 有错误反馈且可继续操作
    Evidence: .sisyphus/evidence/task-10-error-ui.txt
  ```

- [ ] 11. 集成回归与证据归档

  **What to do**:
  - 汇总执行所有任务场景。
  - 归档证据至 `.sisyphus/evidence/` 并建立清单。
  - 复核日历/媒体无回归。

  **Must NOT do**:
  - 不跳过失败场景。
  - 不遗漏证据文件。

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 执行与归档流程化工作。
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3
  - **Blocks**: FINAL
  - **Blocked By**: T6, T7, T8, T9, T10

  **References**:
  - `.sisyphus/evidence/` - 证据归档目标路径。

  **Acceptance Criteria**:
  - [ ] 所有任务至少 1 happy + 1 edge 证据。
  - [ ] 生成证据清单可追溯到任务编号。

  **QA Scenarios**:
  ```
  Scenario: 证据完整性
    Tool: Bash
    Preconditions: T1~T10 已执行
    Steps:
      1. 列出 .sisyphus/evidence/task-* 文件
      2. 对照任务检查缺失
    Expected Result: 无缺失
    Evidence: .sisyphus/evidence/task-11-evidence-index.txt

  Scenario: 回归复核
    Tool: Playwright
    Preconditions: 功能已集成
    Steps:
      1. 打开 dashboard
      2. 验证日历/媒体/壁纸三 tab 均可用
    Expected Result: 三 tab 均正常
    Evidence: .sisyphus/evidence/task-11-regression.png
  ```

---

## Final Verification Wave (MANDATORY)

- [ ] F1. **Plan Compliance Audit** — `oracle`
  - 核对 Must Have / Must NOT Have，逐条映射实现证据与文件行级事实。
  - 输出：`Must Have [N/N] | Must NOT Have [N/N] | VERDICT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  - 运行 lint/type checks（如项目存在），检查改动文件的可维护性、无无效日志污染。
  - 输出：`Quality checks | Findings | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  - 按所有任务 QA 场景逐条执行并复核证据文件完整性。
  - 输出：`Scenarios [N/N] | Integration | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  - 验证无范围膨胀：未实现多显示器/递归扫描/外部来源等排除项。
  - 输出：`Scope Compliance | Unaccounted Changes | VERDICT`

---

## Commit Strategy

- 建议 2~3 个原子提交：
  1) tab+model scaffolding
  2) interaction+animation
  3) hardening+qa evidence updates

---

## Success Criteria

### Verification Commands
```bash
# 示例（按实际仓库可执行命令替换）
qmlscene --version
```

### Final Checklist
- [ ] 所有 Must Have 完成
- [ ] 所有 Must NOT Have 未违反
- [ ] Enter 应用后 dashboard 自动关闭
- [ ] 所有 QA 证据文件存在并可追溯
