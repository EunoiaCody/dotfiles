# 迁移任务拆分 · 依赖与执行顺序

> 输入：`feature-matrix.md` 中用户勾选的 13 个功能
> 生成时间：上游 HEAD `bda7f74b`

## 已选功能（13）

| # | 功能 | 成本 | 风险 | 关键依赖 |
|---|------|------|------|----------|
| F1 | Dock 停靠栏 | L | 高 | C++:Files/WindowPreview/Niri(minimize)、DockService、WindowPreviewService、FileActionService |
| F2 | 文件选择器 FilePicker | M | 中 | C++:Files |
| F3 | C++ 核心插件整体升级 | L | 高 | 编译环境（见 Wave 0） |
| F4 | 设置中心框架（通用/显示伽马/niri/网络/蓝牙/默认应用/自启/账户） | L | 高 | C++:Gamma、NetworkService、BluetoothService、NiriConfigService、DefaultApplicationsService、AutostartService、AvatarService、I18nService |
| F5 | 灵动岛新形态与动效（pill/bangs/long/full/竖横向 + Caelestia） | L | 中 | 无（纯 QML） |
| F6 | 歌词增强（横竖布局/频谱/专辑图） | M | 中 | C++:Lyrics、LyricsTrackService（本地 Python 可作回退） |
| F7 | Bar 增强（横竖向/媒体控件/电池/资源饼/药丸背景） | M | 中 | 纯 QML + Widgets（TopBarPill/WheelScrollController…） |
| F8 | 右侧边栏 QuickSettings 内容升级 | M | 中 | 纯 QML + Services |
| F9 | 通知中心列表（拖拽管理）升级 | M | 中 | 纯 QML + NotificationManager |
| F10 | 壁纸管理页升级 | S | 低 | 纯 QML |
| F11 | 剪贴板服务升级 + detail 面板 | M | 中 | 纯 QML + ClipboardService + Widgets |
| F12 | 锁屏新默认样式 + 预捕获快照 | M | 中 | 纯 QML（ScreencopyView） |
| F13 | 媒体封面/背景/Caelestia 频谱升级 | M | 中 | C++:Cava（**暂不可用**，频谱用本地 AudioSpectrum 兜底） |

## 依赖关系

```
Wave 0  C++ 插件（F3）  ──┬──> F1 Dock（Files/WindowPreview/Niri）
                          ├──> F2 FilePicker（Files）
                          ├──> F4 设置中心（Gamma）
                          ├──> F6 歌词增强（Lyrics）
                          └──> F13 频谱（Cava — 缺失，降级）
F5 灵动岛新形态（纯 QML）──> F6/F13 的挂载点（先改主体再接内容）
F10 壁纸管理页（独立）
F11 剪贴板（独立）
F12 锁屏（独立）
F9 通知（独立）
F7 Bar / F8 侧栏（独立，但复用 Widgets）
```

## Wave 0 结果（已完成）

**C++ 插件构建：成功（265 步，exit 0），隔离安装未启用。**

- 已构建 11 个插件：`DesktopCards, Files, Gamma, I18n, Keyboard, Lyrics, Media, Niri, Runtime, Weather, WindowPreview`
- **跳过 2 个**（缺系统依赖，无 sudo 无法安装）：
  - `Cava` — 缺 `libcava`（`cava` 包无 pkg-config 文件）→ 频谱功能降级用本地 `Services/AudioSpectrum.qml`
  - `WeatherMap` — 缺 `Qt6Keychain`（仓库无此包；用户未选地图功能，影响可控）
- 补丁：`core/CMakeLists.txt` 去除 `Qt6Keychain` 必需项、`cava`/`weathermap` 子目录；`core/src/CMakeLists.txt` 移除 `ClavisWeatherMapCore`
- 隔离安装路径：`~/.local/share/qt6/qml-next/Clavis/`（**工作插件 `~/.local/share/qt6/qml/Clavis/` 未改动**）
- 导入验证：`qml6` 加载 Files/Niri/Gamma/Lyrics/Runtime/I18n/WindowPreview 全部成功（正向 exit 0，反向对照 exit 2）

**启用方式（待迁移对应功能时执行，勿提前）**：在 `start-quickshell.sh` 中把 `~/.local/share/qt6/qml-next` 前置到 `QML2_IMPORT_PATH`，并将其各模块目录加入 `LD_LIBRARY_PATH`。启用前必须核对新版插件 API 与现有 QML 是否兼容。

## 执行顺序（低风险 → 高风险）

- [x] **F2 FilePicker**（M，C++:Files）— ✅ 已完成并提交 `e724da0`
  - 新增 `Modules/FilePicker/`、`Widgets/common/{RippleButton,RippleEffect,StateLayer,CompositorBlurRegion}.qml`、`Services/BlurService.qml`(shim)、`Common/Fonts.qml`、`Appearance.interaction` 令牌
  - 运行时验证：quickshell 隔离实例加载零错误
  - 备注：`BlurService` 为精简 shim（上游完整版依赖 `NiriConfigService`/`Clavis.Runtime`），后续需要 niri 动态模糊时再替换
- [ ] **F10 壁纸管理页**（M，纯 QML）— 🔄 进行中（FilePicker 依赖已解除）
1. F11 剪贴板（M）
2. F12 锁屏（M）
3. F9 通知中心（M）
4. F7 Bar 增强（M）
5. F8 侧栏 QuickSettings（M）
6. F5 灵动岛新形态（L）
7. F13 媒体封面/背景（M）
8. F6 歌词增强（M）
9. F4 设置中心框架（L）
10. F1 Dock（L）

## 每个功能的迁移规约（DoD）

- 适配：`Keystone → DynamicIsland` 命名、`matugen → ColorMap/Appearance` 配色、`qsTr()` 文本剥离或本地化、C++ API 核对
- 验证：`qmllint` 全绿 → `quickshell -l` 无错误 → 无头/交互截图
- 提交：一功能一提交，失败可单独回滚
- 记录：更新本文件与 `feature-matrix.md` 的采纳/跳过状态

## F10 壁纸 —— 迁移前发现（需先解决）

上游 HEAD 的壁纸体系与本地的集成点不一致，不能直接替换：

1. `WallpaperService.qml`（head 729 行）**移除了 `primaryInstance`**（本地 AppShell 用它做扫描门控），并新增依赖 `NiriConfigService.snapshot/revision` → 需要先移植 `Services/NiriConfigService.qml`（依赖 `Clavis.Runtime`，属新插件，需先启用 `qml-next` 导入路径）。
2. `PersonalizationConfig.qml` 需要合并大量新键：`desktopWallpaperBackend`、`awww*`（transition type/fps/step/angle/position/wave）、`overview*`（per-monitor、use-desktop、backdrop rule）、`perModeWallpaper` 扩展等。
3. 需要新增 `Services/{AwwwWallpaperService,WallpaperSceneService,WallpaperPaletteSession}.qml` + `Common/functions/{WallpaperSource,AwwwCommand,WallpaperMath,ZenPalette,WallpaperPaletteScope}.js` + `Common/SidebarPolicy.js` + `Widgets/common/WallpaperActions.qml` + `Modules/Wallpaper/{DesktopWallpaper,OverviewWallpaper,WallpaperImageViewport,WallpaperTransitionSurface}.qml`。
4. `WallpaperSceneService` import `Clavis.Niri`：需核对新版 `Clavis.Niri` API 与本地旧插件的兼容性（若启用 qml-next 需整体回归测试）。

**建议**：F10 与「启用新 Clavis 插件（qml-next）」绑定；先完成 `NiriConfigService` + `PersonalizationConfig` 合并，再替换 `WallpaperService`，最后接 UI。

## 进度更新（增量）

- ✅ **F2 FilePicker**（提交 `e724da0`）
- ✅ **基础设施：C++ 插件**（11 个，隔离安装 `~/.local/share/qt6/qml-next`）
- ✅ **基础设施：key-cli**（`~/.local/bin/key`，v2026.9.25）
- ✅ **基础设施：NiriConfigService + niri 脚本链**（提交 `6eeff9b`）——启用 qml-next 追加路径提供 `Clavis.Runtime`
- ✅ **基础设施：M3Shapes**（本地源码构建，提交 `c417943`）——解锁 Caelestia/SystemCards/shape 特性
- ✅ **F13 媒体封面/背景**（提交 `e809941`）：`MediaContent`/`MediaCover`/`CaelestiaCover` + `WaveProgressBar` + media 配置键
  - 备注：`MediaBackdrop`（coverStyle="background" 的背景铺底）尚未接入 Keystone 表面，默认 `rounded` 不受影响

### 下一个建议
- 优先做 **F12 锁屏** 或 **F7 Bar**（均需补少量新 widget/服务）
- F10 壁纸仍需 PersonalizationConfig 大合并；F9 通知与上游左 Dashboard 侧栏耦合；F5 Keystone 依赖大量新 widget/服务

- ✅ **F7 Bar 增强（增量）**（提交 `25d0d97`）：
  - QuickSettings 新增 **Battery**（UPower）；Bar 右侧新增 **MediaBar**（媒体控件，随播放显隐）
  - 新增 `PowerService`、`ThemeIcon`、`SystemFormat.js`；Widgets：IconButton/MediaSourceIcon/TopBarPill/TopBarPillBackground/WheelScrollController/MaterialCard/BarActionButton/BarCircularButton/BarLabelButton
  - `Sizes` 补 bar* 令牌；`ThemeService.iconThemeRevision`；`PersonalizationConfig.barPosition/barShowValues`
  - 未做：横/竖向 Bar 整体重构、ResourcePie 接入（本地 SysMonitor 结构不同）

- 🔄 **F10 壁纸（第 1 部分，提交 `7270a8f`）**：后端 + 新渲染架构
  - 已完成：JS 工具链、`AwwwWallpaperService`/`WallpaperSceneService`/`WallpaperPaletteSession`、上游 `WallpaperService`、`PersonalizationConfig` 大合并（overview/awww/parallax/commitPalette）、`WidgetState` 侧栏状态、`Modules/Wallpaper` 新组件（Overview/Desktop/TransitionSurface/ImageViewport/ZenPaletteRenderer）、`WallpaperBackground` 切换为上游架构
  - 验证：AppShell 编译通过；`WallpaperBackground` 渲染零错误；本地裁剪版 `WallpaperPage` 兼容
  - ⏳ 待办（第 2 部分）：上游 `ControlCenter/WallpaperPage`（1219 行）需要设置中心 widget 框架（`SettingsRow/SettingsSection/Section/FlatSettingsSection/SearchAnchor/ButtonLabel/InlineStatusBanner/MaterialSlider/SplitMenuButton/StyledButtonGroup/BezierCurveEditor/BezierCurveLayerEditor/NiriSetupPrompt/WallpaperPreview/WallpaperImageViewport` 等 ~16 个）→ 与 **F4 设置中心** 重合，建议随 F4 一起做
  - 备注：旧 `Clavis.Niri` 缺 `setFloatingParallaxOffsets`，浮动窗口视差暂不生效（被 `typeof` 守卫，无报错）

- ✅ **共享基础层**（提交 `09a6231`）：补齐 38 个上游 `Widgets/common`/`Components`/`Common` 文件 + `ControlCenterService`（全部编译零错误）
- ✅ **F6 歌词增强**（提交 `53a4171`）：上游 `Clavis.Lyrics` 歌词系统（横/竖布局、专辑图、频谱）+ `LyricsTrackService`；保留本地 Python 歌词栈供 Media 面板；`LyricsContent` 加 `active/showCover/showSpectrum` 兼容属性
- 🔎 **F8 右侧栏**：上游重构为 `Modules/Sidebars/QuickSettings`（`QuickSettingsSidebar`/`QuickSettings`/`AudioContent`/`BluetoothContent`/`IdleContent`/`MicrophoneContent`/`NightModeContent`/`SettingsContent`），状态模型为 `WidgetState.quickSettingsOpen/quickSettingsView`（本地为 `qsOpen/qsView`），需新增 `IdleService`、`Widgets/audio/ApplicationVolumeRow`，并切换 AppShell 的右侧栏 → 结构性移植，单独一轮
- 🔎 **F4 设置中心**：需要 ControlCenter 框架 + 大量页面 + `DisplayConfigService/DefaultApplicationsService/AutostartService/AvatarService/...`（部分依赖 matugen，需按“固定 Catppuccin”策略裁剪）→ 大工程，单独多轮
- 🔎 **F9 通知**：上游通知中心在左侧 `Sidebars/Dashboard`（含 67 文件）→ 需先建左侧 Dashboard 侧栏

## 最终方案：整壳采用上游 HEAD（路线 B，提交 `468bfba`）

用户选择以**上游 HEAD 为底座**整壳替换，保留固定 Catppuccin 配色桥。

- **替换**：`Modules/`、`Services/`、`Widgets/`、`Components/` 全部改为上游；`Common/` 取上游的 Metrics/Typography/KeystoneMotion/Paths/WidgetState/functions/generated/SidebarPolicy/RecordingState/ShortcutKeySymbols/NiriActionNames/settings-routes；`AppShell.qml`/`shell.qml` 用上游。
- **保留**：`Common/ColorMap.qml`（Catppuccin→M3，token 与上游 100% 对齐）+ `Common/Appearance.qml`（re-export + interaction + matugen 兼容桩）+ `Common/Fonts.qml`（Nerd Font）+ `Common/Animations.qml`。
- **qmldir**：上游依赖 CMake 生成，本方案手写全树 qmldir（`module qs.*`）。
- **降级**（缺系统依赖，无 sudo）：`AudioSpectrum`/`AudioRecordingVisual`（缺 libcava/Cava）、`MeteoIcon`（缺 qt6-lottie → 用 SVG）。
- **启动**：`start-quickshell.sh` 改为 `qml-next` 插件优先 + M3Shapes + `~/.local/lib`。
- **验证**：`Configuration Loaded`，零错误；Clavis 配置/缓存目录已初始化。

**已知限制**：天气地图需 `Clavis.WeatherMap`（缺 qtkeychain-qt6，未构建）；音频频谱需 libcava；动画天气图标回退为 SVG。
**回退**：`git checkout pre-head-adoption -- .`（或 `git reset --hard pre-head-adoption`）。
