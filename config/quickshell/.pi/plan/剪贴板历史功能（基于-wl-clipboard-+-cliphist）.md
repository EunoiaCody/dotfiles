# 计划：剪贴板历史功能（基于 wl-clipboard + cliphist）

> 创建时间：7/17/2026, 10:46:37 PM
> 批准时间：7/17/2026, 10:53:09 PM

## 任务
使用 wl-clipboard 和cliphist 做一个剪贴板历史功能

现在我已对整个架构有了深入了解。让我制定一个全面的计划。

---

## Plan: 剪贴板历史功能（基于 wl-clipboard + cliphist）

### Overview

构建一个剪贴板历史管理器：使用 **cliphist** 作为后端存储/检索（Wayland 原生剪贴板历史守护进程），**wl-paste/wl-copy** 作为剪贴板读写工具。UI 层遵循现有的 RightSidebar 模式——在右侧面板中新增「剪贴板」视图，包含可搜索的历史列表，支持预览、粘贴和删除操作。同时在顶栏 QuickSettings 中添加触发按钮，并使用 IPC 处理器支持键盘快捷键。

### Affected Files

| 文件 | 变更类型 | 说明 |
|---|---|---|
| `Services/ClipboardService.qml` | **新建** | 剪贴板历史数据管理单例（Process 调用 cliphist） |
| `Services/qmldir` | 修改 | 注册 ClipboardService 单例 |
| `Common/WidgetState.qml` | 修改 | 添加 `clipboardView` 状态支持 |
| `Modules/Sidebars/Right/ClipboardContent.qml` | **新建** | 剪贴板历史面板 UI（列表 + 搜索） |
| `Modules/Sidebars/Right/QuickSettings.qml` | 修改 | 添加 ClipboardContent 切换到 view 路由 |
| `Modules/Bar/QuickSettings/QuickSettings.qml` | 修改 | 添加剪贴板触发按钮 |
| `Modules/Bar/QuickSettings/ClipboardButton.qml` | **新建** | 顶栏剪贴板图标按钮 |
| `AppShell.qml` | 修改 | 注册 clipboard IPC 处理器 |
| `Common/Paths.qml` | 修改 | 添加 cliphist 缓存/运行时路径 |

### Step-by-Step Plan

---

#### Phase 1: 后端服务 — ClipboardService

- [ ] **1.1 创建 `Services/ClipboardService.qml`**
  - 遵循 `pragma Singleton` 模式，继承 `QtObject`（不是 `Item`）
  - 包含两个 `Process` 对象：
    - `listProc`: 执行 `cliphist list`，通过 `SplitParser` 逐行解析 `id\tpreview` 格式
    - `decodeProc`: 执行 `cliphist decode <id>`，获取完整内容
    - `copyProc`: 执行 `wl-copy`，通过 stdin 写入所选条目
  - 核心属性：
    - `property var entries: []` — `[{id: 0, preview: "..."}]` 格式的条目数组
    - `property bool loading: false`
    - `property int entryCount: 0`
  - 核心方法：
    - `refresh()` — 运行 `cliphist list`，解析并更新 `entries`
    - `decode(id, callback)` — 异步解码单个条目
    - `copyToClipboard(id)` — 解码后通过 `wl-copy` 写入剪贴板
    - `deleteItem(query)` — 运行 `cliphist delete <query>`
    - `wipe()` — 运行 `cliphist wipe`
  - 自适应轮询：使用 `Timer { interval: 1500 }` 定期刷新（仅面板打开时启用）
  - 注释使用中文
  - 颜色使用 `Appearance.colors.*`
- [ ] **1.2 在 `Services/qmldir` 中注册 ClipboardService**
  - 新增一行：`singleton ClipboardService 1.0 ClipboardService.qml`
- [ ] **1.3 更新 `Common/Paths.qml`**（可选）
  - 若需要，添加 cliphist 数据目录的只读属性（通常为 `~/.local/share/cliphist`）

---

#### Phase 2: UI 面板 — ClipboardContent

- [ ] **2.1 创建 `Modules/Sidebars/Right/ClipboardContent.qml`**
  - 遵循 `WidgetPanel` 组件模式（参照 `NotificationsContent.qml`）
  - 标题：「剪贴板」，图标：`content_paste`
  - 顶部：搜索栏（`TextInput`），实时筛选条目
  - 主体：`StyledListView`，展示历史条目
  - 每个条目委托显示：
    - 预览文本（截断至单行，等宽字体）
    - 时间戳 / ID 徽章
    - hover 时显示「复制」和「删除」操作按钮
  - 底部：`RowLayout` 操作栏：
    - 「清除全部」按钮（调用 `ClipboardService.wipe()`）
    - 条目数量指示器
  - 搜索过滤：`entries.filter(e => e.preview.toLowerCase().includes(query.toLowerCase()))`
  - 属性 `contentImplicitHeight: 640`（与 NotificationsContent 一致）
- [ ] **2.2 在 `QuickSettings.qml` 中添加 ClipboardContent 路由**
  - 在现有 `contentImplicitHeight` switch 中添加 `case "clipboard": return clipboardContent.contentImplicitHeight`
  - 添加 `ClipboardContent { id: clipboardContent; ... }` 块及其 opacity/scale 动画（与现有 AudioContent 等模式一致）
- [ ] **2.3 更新 `Common/WidgetState.qml`**
  - 确保 `qsView` 能接受 `"clipboard"` 值（当前是自由字符串，已支持，但需在注释中说明）

---

#### Phase 3: 触发机制 — 按钮 + IPC

- [ ] **3.1 创建 `Modules/Bar/QuickSettings/ClipboardButton.qml`**
  - 参照现有按钮（如 `NotificationButton.qml`）的模式
  - 图标：Material Symbol `content_paste` 或 `content_copy`
  - 点击行为：设置 `WidgetState.qsView = "clipboard"`，切换 `WidgetState.qsOpen`
  - 激活状态指示器：当 `WidgetState.qsView === "clipboard"` 时高亮
  - 使用 `MaterialRippleButton` 基组件
- [ ] **3.2 在 QuickSettings Bar 的 RowLayout 中添加 ClipboardButton**
  - 编辑 `Modules/Bar/QuickSettings/QuickSettings.qml`
  - 在 `RowLayout { id: layout ... }` 中插入 `ClipboardButton { screen: root.screen }`（建议放在 NotificationButton 旁边）
- [ ] **3.3 在 `AppShell.qml` 中添加 IPC 处理器**
  - 新增 `IpcHandler { target: "clipboard" ... }`，包含方法：
    - `toggle()` — 打开/关闭剪贴板面板
    - `show()` — 仅打开
    - `hide()` — 仅关闭
  - 这样即可通过 `quickshell ipc call clipboard toggle` 绑定键盘快捷键

---

#### Phase 4: 细化与测试

- [ ] **4.1 连接生命周期管理**
  - 面板打开时：`ClipboardService.refresh()` + 启动轮询定时器
  - 面板关闭时：停止轮询定时器（节省资源）
- [ ] **4.2 粘贴操作流程**
  - 用户点击「复制」按钮 → `ClipboardService.copyToClipboard(entryId)`
  - Service 在后台调用 `cliphist decode <id>`，将 stdout 管道传输至 `wl-copy`
  - 复制成功后，面板可保持打开或自动关闭（带短暂确认反馈）
- [ ] **4.3 删除操作**
  - 单条删除：`cliphist delete <query>`（使用条目 ID 或预览文本作为查询条件）
  - 全部清除：`cliphist wipe`，然后 `refresh()`
- [ ] **4.4 语法验证**
  - 运行 `QT_QPA_PLATFORM=offscreen ./start-quickshell.sh` 进行无头 QML 加载测试
  - 确认所有导入解析、单例实例化、无崩溃
- [ ] **4.5 手动 QA**（需 Wayland 会话）
  - 启动 quickshell，检查顶栏是否出现剪贴板按钮
  - 点击按钮 → 右侧面板以剪贴板视图打开
  - 复制一些文本 → 条目出现在列表中
  - 搜索筛选条目、复制回剪贴板、删除单条、全部清除

---

### 额外探索：systemd 守护进程设置（可选）

为实现自动剪贴板历史采集（无需 `start-quickshell.sh` 中额外配置），可添加 `wl-paste --watch cliphist store` 作为后台进程。这属于基础设施层面，可放入单独的 `scripts/clipboard/` 或 `start-quickshell.sh` 中。当前将其列为可选项，因为用户可能已有自己的 cliphist 系统服务。

---

### Risks & Considerations

- **cliphist 依赖**：若系统未安装 `cliphist` 或 `wl-clipboard`，服务将静默失败。需在 QML 中添加 `Process.onError` 处理并显示友好提示（如 "cliphist 未安装"）。
- **MIME 类型处理**：cliphist 存储文本和图片。初始版本仅处理 `text/plain` 和 `text/uri-list` MIME 类型——图片粘贴可留作未来改进。
- **性能**：`cliphist list` 在数千条历史记录时可能较慢。建议使用 1.5 秒轮询间隔，并将预览截断至 100 字符以内。
- **并发安全**：两个 `Process` 调用（list + decode）可能重叠。确保 callback 模式处理好竞态条件。
- **Wayland 剪贴板限制**：不同于 X11，Wayland 剪贴板在应用关闭后无法持久化。cliphist 通过 `wl-paste --watch` 守护进程解决此问题。若该 watch 进程未运行，则不会捕获历史记录——需在 UI 或文档中予以说明。

### Estimated Impact

| 维度 | 数量 |
|---|---|
| 新建文件 | 3（ClipboardService.qml、ClipboardContent.qml、ClipboardButton.qml） |
| 修改文件 | 5（Services/qmldir、QuickSettings.qml、QuickSettings.qml bar、WidgetState.qml、AppShell.qml） |
| 删除文件 | 0 |
| 代码行数（预估） | ~250-350 行 QML |

---

**PLAN COMPLETE**

请审阅此计划。若您希望调整 UI 方案（例如，使用浮动弹窗替代 RightSidebar 面板）、更改触发机制或调整数据刷新策略，请告知我，我会据此修订计划。