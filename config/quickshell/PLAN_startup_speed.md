## Plan: 提升 Quickshell 启动速度

### Overview（根因与策略）

经过完整代码审计 + 本地实测，确认三个启动成本来源，按影响排序：

1. **不可见 UI 的 eager 实例化**：`LauncherWindow`（`visible: false` 但三个页面全部内联创建，AppPage 启动时轮询触发 `DesktopEntries` 全量扫描 134 个 .desktop + 图标解析 + 初始搜索建模）、`HubContent` 四个 tab 全部 eager（WeatherContent 启动即网络请求 + 天文计算 Timer ×2、SysInfoWidget 进程 running:true、ScheduleWidget cat 进程、IllustrationHitokoto 扫图进程 + 一言网络请求）、`DynamicIsland` 9 个内容组件树全部内联 eager（仅 opacity 切换）。
2. **启动进程风暴**（约 15–20 个进程）：nmcli ×4 + 常驻 monitor、壁纸目录 `find`、`mkdir -p` ×3、hostname 检测、主题检测 ×2、brightness 工具检测、pidof hypridle、天气/一言网络请求等。
3. **QML 磁盘缓存完全失效**（上游 quickshell issue #735，`qs:@/` 虚拟 URI 绕过 Qt 缓存，本地已实测验证：每个文件都报 "File has to be a local file"）。**但实测影响有限**：125 个文件解析仅 ~268ms（本机无巨型数据表文件，最大 QML 44KB）。缓存无法从配置侧修复，只能通过减少启动时编译量来压缩这 ~300-400ms。

**已验证没问题的部分**（不要动）：RightSidebar 内容已是 Loader 懒加载；锁屏 `WlSessionLock.surface` 是 Component，锁定时才实例化；壁纸着色器经 `effectLoader` 按需加载；所有 Image 均 `asynchronous: true`；AudioSpectrum 是无进程 stub；LyricsDaemon 按需启动；单屏环境（DP-1），每屏重复系数 ×1。

**策略**：懒加载不可见 UI（减少启动编译量 + 消除 DesktopEntries 扫描 + 消除天气网络请求）→ 推迟非关键进程 → 可选结构优化。

### Affected Files

**Phase 1（测量插桩，临时）**
- `start-quickshell.sh` — 可选：exec 前记录 `EPOCHREALTIME` 时间戳
- `AppShell.qml` — 临时：`Component.onCompleted` 打时间戳日志（验证后移除）

**Phase 2（懒加载，核心收益）**
- `Modules/Launcher/LauncherWindow.qml` — 主内容树包进 `Loader`（`asynchronous: true`，active 绑定「曾打开过」标志），`prepareOpen` 首次等待 `onLoaded` 再显示窗口
- `Modules/Launcher/AppPage.qml` — 确认 `startupPollTimer` 随 Loader 延后创建即可（预计无需改动或仅微调 running 条件）
- `Modules/DynamicIsland/Hub/HubContent.qml` — Overview/Media/Wallpaper/Weather 四个 tab 改为 `Loader`，`active: root.currentIndex === N || 已加载标志[N]`（首次激活后常驻以保状态）
- `Modules/DynamicIsland/DynamicIsland.qml` — HubContent / NotificationContent / MediaContent / ToolsContent / AudioContent 包 `Loader`，active 绑定对应 mode（或-mode-曾进入）；为 `toolsWidget.stopAudio()`、`hub` 等直接引用加 null guard

**Phase 3（进程风暴）**
- `Services/WallpaperService.qml` — `Component.onCompleted` 移除立即 `scan()`，改为 3–5s 空闲 Timer 预扫描（`cycle()` 的 `pendingCycleAction` 按需路径已存在，兜底首次 cycle）
- `Services/Network.qml`（可选，低优先）— 启动 4 个 nmcli 调用合并为 1–2 个
- 验证：Phase 2 落地后 Hub 内进程（sysinfo/schedule/hitokoto/weather）自动从启动路径消失

**Phase 4（可选进阶）**
- `Modules/DynamicIsland/DynamicIsland.qml`、`Modules/Sidebars/Right/RightSidebar.qml`、`Modules/Launcher/LauncherWindow.qml`、`Modules/Bar/Tray/Tray.qml` — `Qt5Compat.GraphicalEffects` → `QtQuick.Effects.MultiEffect`（渲染性能，非启动解析）
- 跟踪上游 #735 修复，定期升级 `quickshell-git`
- 评估 `shell.qml` 的 `//@ pragma UseQApplication` 是否必需（QApplication 启动略慢，但 Tray/DBus 可能依赖，需实测）

### Step-by-Step Plan

#### Phase 1: 建立测量基线
- [ ] 在终端手动重启 shell 测量真实启动：`kill` 当前实例 → `time ./start-quickshell.sh`（对比进程启动到 AppShell.onCompleted 日志的时间差）
- [ ] `start-quickshell.sh` exec 前加临时 `echo $EPOCHREALTIME > /tmp/qs_boot_ts`；`AppShell.qml` onCompleted 加临时 `console.log("[boot] AppShell ready", Date.now()/1000)`
- [ ] 用 `QT_LOGGING_RULES="qt.qml.diskcache=true"` + offscreen 跑分记录启动期编译的文件数（当前实测 125 个文件 / ~268ms 部分加载）
- [ ] 记录启动进程清单：`ps` 观察 nmcli/find/mkdir/python 等子进程数量作为前后对比
- [ ] 记录基线数值到本文件「验证记录」小节

#### Phase 2: 懒加载不可见 UI
- [ ] **2.1 Launcher 懒加载**：`LauncherWindow.qml` 中把承载 StackLayout 的主内容 Item 包入 `Loader { asynchronous: true; active: root.contentRequested }`；新增 `property bool contentRequested: false`，在 `prepareOpen()` 置 true；首次打开时若 `loader.status !== Loader.Ready` 则在 `onLoaded` 后再完成显示动画；验证 `AppPage.startupPollTimer`、DesktopEntries 扫描、LaunchTracker 均推迟到首次打开
- [ ] **2.2 Hub tab 懒加载**：`HubContent.qml` 四个 tab 改 Loader，active 绑定 `currentIndex` 且首次激活后保持 true；WeatherContent 不再随启动创建（消除启动网络请求 + 2 个常驻 Timer）
- [ ] **2.3 灵动岛次级内容懒加载**：`DynamicIsland.qml` 中 HubContent（active: isHubMode 或曾进入）、MediaContent（active: expanded 且非 lyrics/hub 或曾进入）、NotificationContent、ToolsContent、AudioContent 依次包 Loader；**保留 eager**：ClockContent（默认可见）、compact LyricsContent、VolumeContent（音量 OSD 需即时）
- [ ] **2.4 null guard**：`toolsWidget.stopAudio()` → `toolsLoader.item ? toolsLoader.item.stopAudio() : null`；`hub`、`onRequestShowAudio` 等跨组件引用逐一检查
- [ ] **2.5 功能回归**：launcher 首开/二开、搜索、切页；hub 四 tab 切换状态保持；灵动岛通知/媒体/工具/音频模式进出动画

#### Phase 3: 推迟启动进程
- [ ] **3.1** `WallpaperService.qml`：onCompleted 移除 `root.scan()`，加 `Timer { interval: 4000; running: true; repeat: false; onTriggered: root.scan() }` 空闲预扫描
- [ ] **3.2** 验证启动进程清单收敛（目标：启动进程从 ~15-20 降至 ~8-10）
- [ ] **3.3**（可选）`Network.qml` 启动 nmcli 调用合并；不合并则跳过

#### Phase 4: 可选结构优化（单独评估，可不做）
- [ ] Qt5Compat.GraphicalEffects → QtQuick.Effects.MultiEffect 迁移（逐文件）
- [ ] 关注 quickshell-mirror/quickshell#735，升级 quickshell-git 后复测磁盘缓存
- [ ] 评估去掉 `UseQApplication` pragma 的可行性（实测 tray 是否正常）

#### Phase 5: 复测与清理
- [ ] 用 Phase 1 方法复测，对比基线并记录
- [ ] 移除/禁用临时计时插桩（或保留在 `QS_BOOT_TIMING` 环境变量开关后）
- [ ] 更新 AGENTS.md？（不需要——行为不变时跳过）

### Risks & Considerations

- **首开延迟**：Launcher/Hub/媒体面板首次打开有 ~50–300ms 加载 → 用 `asynchronous: true`（不卡帧）+「首次激活后常驻」缓解；Launcher 首开延迟可被打开动画掩盖
- **Loader.item 空引用**：DynamicIsland 内对 `toolsWidget`、`hub` 的直接引用在未加载时为 null → 全部改经 `loader.item` 并加 guard；逐处 grep 验证
- **通知/音量 OSD 即时性**：通知到达需立即展示 → NotificationContent 可在首条通知时异步加载（岛展开动画天然掩盖）；VolumeContent 保持 eager
- **壁纸首次 cycle**：scan 推迟后，开机后首次 `ipc wallpaper next` 需先扫描 → `pendingCycleAction` 机制已存在可兜底；4s 空闲预扫描基本消除该窗口
- **QML 绑定求值时机**：Loader 内组件创建晚，外部对其属性的绑定需在 item 存在后求值（用 `loader.item ? ... : default`）
- **测量干扰**：手动重启 shell 测量会短暂中断桌面面板，选择可接受的时间窗口操作；offscreen 测试不影响线上会话
- **上游修复不可控**：#735 未修复前，启动编译量优化有上限（全量解析 ~300-400ms 为地板）；不要为了追求极致而过度拆分文件

### Estimated Impact

- Files to create: 0（计划文档除外）
- Files to modify: 5–7（LauncherWindow、AppPage(可能)、HubContent、DynamicIsland、WallpaperService、Network(可选)、AppShell/start 脚本(临时插桩)）
- Files to delete: 0
- 预期收益：启动期 QML 编译文件数 -30%~50%（Launcher 4 文件 ~40KB + Hub ~60KB + 岛次级内容 ~30KB 及各自依赖树）；启动进程数减半；DesktopEntries 扫描（134 应用 + 图标解析）、天气/一言网络请求、壁纸 find 全部移出启动关键路径

### 验证记录（执行时填写）

| 指标 | 基线 | Phase 2 后 | Phase 3 后（最终） |
|---|---|---|---|
| 启动到 AppShell ready | **495ms**（warm restart） | **390ms**（-21%） | **391/392/392ms**（三次稳定，**-103ms / -21%**） |
| 启动期编译文件数 | 125（offscreen 部分加载实测） | Launcher 4 文件 + Hub 4 tab 树 + 岛 5 内容树移出启动路径 | 同左 |
| 启动关键路径外部工作 | DesktopEntries 扫描（134 .desktop + 图标解析）、天气/一言网络请求、壁纸 find、sysinfo/schedule 进程 | 全部推迟到首次打开对应 UI | 壁纸 find 再推迟到启动后 4s 空闲 |
| 备注 | 热启动测量；冷启动（登录时 CPU/IO 竞争）收益会大于 21%（减少的是真实工作量：进程 fork、网络请求、D-Bus/扫描） | | |

**Phase 4 结论（可选，均为「不做」决策）**：Qt5Compat→MultiEffect 属渲染重构、有视觉回归风险，不属启动关键路径；上游 #735 仍 open，保持 quickshell-git 定期升级；`UseQApplication` 移除对 tray/DBus 有风险、收益仅 ~10-30ms，保留。

**遗留问题（超出本计划范围）**：`Services/ThemeService.qml:360` 调用不存在的 `Appearance.reloadColors()`（matugen 时代的残留；当前固定 Catppuccin 调色板下无害，仅一条 TypeError 警告）。建议后续直接删除该调用或改为条件调用。

**备份**：修改前文件保存在 `.pi/backups/startup-speed-baseline/`。

### 回归修复记录（用户反馈后）

**症状**：灵动岛点击展开空白；Mod+I（`ipc island hub`）打开 Hub 多 tab 内容重叠错位。

**根因**：QML `Loader` 会把加载项强制 resize 到自身大小（覆盖内容自身的 `width: implicitWidth` 绑定——调试日志实测 HubContent 终值 1600）。初版改造给 Loader 设了 `anchors.fill: parent`（staticCanvas 1600×1200），导致所有懒加载内容被拉伸到 1600×1200：HubContent 内部 tab 布局全部错位；MediaContent 被拉伸后可视区域（岛裁剪窗口 540×210）内几乎无内容 → 显示为空白。

**修复**：几何（anchors/尺寸）一律移到 Loader 上；隐式尺寸内容（HubContent、Overview/Media tab）用 `width: item ? item.implicitWidth : 0` 绑定（两者均有显式 implicitWidth，无绑定循环）；显式尺寸内容直接给 Loader 固定尺寸。同时给 AppPage delegate 的 `model.app` 引用加空值防护（首开时建模竞态的瞬态 TypeError）。

**验证**：截图确认 Hub 四 tab 布局正常；hub/launcher IPC 开关无错误；启动时间复测 373ms（与优化后一致，修复无开销）。
