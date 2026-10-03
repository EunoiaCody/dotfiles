# StatIndet/quickshell 功能差异矩阵（本地 fork ↔ 上游 HEAD）

- **生成时间**：基于本地配置与上游 HEAD `bda7f74b`（2026-10-02）
- **本地基线**：上游 `6580fa315f`（2026-06-07），2026-06-09 抓取合并
- **本地文件**：156（qml/js/py/sh/conf/json）；**上游 base**：193；**上游 HEAD**：899
- **用途**：供用户勾选「要迁移的功能」，再由 agent 按功能拆分迁移任务
- **状态图例**：🟥 上游独有｜🟩 本地独有｜🟨 共有但有差异
- **依赖图例**：`无` / `matugen` / `i18n` / `C++:<插件>` / `外部工具:<名>` / `服务:<名>`
- **成本**：S（小，单文件级）／M（中，多文件）／L（大，模块级+依赖）
- **风险**：低／中／高

---

## 0. 基线与命名对齐表

| base（本地基线 6/7） | HEAD（上游 10/2） | 说明 |
|---|---|---|
| `Modules/DynamicIsland/**` | `Modules/Keystone/**` | 7/13 整体重命名 |
| `Common/DynamicIslandMotion.qml` | `Common/KeystoneMotion.qml` | 重命名 |
| `Services/Network.qml` | `Services/NetworkService.qml` | 重命名+扩展 |
| `Services/Idle.qml` | `Services/IdleService.qml` | 重命名 |
| `Services/Wlsunset.qml` | `Services/DisplayColor.qml` + `DisplayConfigService.qml` + `Clavis.Gamma` | 功能拆分 |
| `Services/LockSnapshot.qml` | `Modules/Lock/PreLockCapture.qml` + `scripts/capture/LockSnapshot.qml` | 迁移到 Lock 模块 |
| `core/plugin/audio` | `core/plugin/cava` | 音频插件重构（依赖 cava 库） |
| `core/plugin/sysmon` | `Services/SystemMonitorService.qml` + 外部 `key-cli` | 系统监测改为外部后端 |
| `Common/Appearance.qml`（matugen） | 本地改为读 `ColorMap`（Catppuccin 桥接） | **本地保留固定配色，不引入 matugen** |
| `Modules/Sidebars/Left/**`（base 已有） | `Modules/Sidebars/Dashboard/**` | 用户当时**未迁移**左侧栏；上游已重构重命名 |
| `Modules/ControlCenter/**`（base 16 文件） | 72 文件 | 用户当时**只迁移了壁纸 3 文件** |

**C++ Clavis 插件对照**

| base（本地已编译 5 个，跳过 Audio） | HEAD（13 个） |
|---|---|
| `Clavis.Audio`（跳过，缺 cava） | `Clavis.Cava`（替代 Audio） |
| `Clavis.Keyboard` | `Clavis.Keyboard` |
| `Clavis.Media` | `Clavis.Media` |
| `Clavis.Niri` | `Clavis.Niri` |
| `Clavis.Sysmon` | （已移除，改用外部 key-cli） |
| `Clavis.Weather` | `Clavis.Weather` |
| — | `Clavis.Files`（文件搜索/选择器） |
| — | `Clavis.Gamma`（显示伽马） |
| — | `Clavis.WeatherMap`（天气地图） |
| — | `Clavis.WindowPreview`（窗口缩略图） |
| — | `Clavis.Lyrics`（歌词后端） |
| — | `Clavis.DesktopCards`（桌面卡片） |
| — | `Clavis.Runtime`（运行时/热重载） |
| — | `Clavis.I`（i18n） |

---

## 1. 灵动岛（DynamicIsland ↔ Keystone）

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 主体容器/状态机 | `Keystone/Keystone.qml` | `DynamicIsland/DynamicIsland.qml` | 🟨 | 无 | L | 高（命名+大量重构） |
| Pill 药丸形态 | `Styles/Pill/Pill.qml` | 本地自有形态 | 🟥 | 无 | M | 中 |
| Bangs 刘海形态 | `Styles/Bangs/Bangs.qml` | 无 | 🟥 | 无 | M | 中 |
| Long 长抽屉 + Caelestia 动效 | `Styles/Shared/{AttachedEdgeCurve,KeystoneHoverController,Horizontal/VerticalKeystoneLayout}` | 无 | 🟥 | 无 | L | 中 |
| FullDisplay 全屏状态栏 | `FullDisplay/{FullIslandFrame,FullStatusBar,FullStatusItem}` | 无 | 🟥 | 无 | M | 中 |
| 横/竖向布局 | `Styles/Shared/Horizontal/VerticalKeystoneLayout` | 无 | 🟥 | 无 | M | 中 |
| 键盘锁指示（Caps/Num） | `Styles/Shared/KeyboardLockIndicator.qml` | 无 | 🟥 | C++:Keyboard | S | 低 |
| 录制视觉（波形/分裂） | `Styles/Recording/**` | 本地 `Tools/ToolsBackend` + `scripts/capture` | 🟨 | 无 | M | 中 |
| 云盘上传内容 | `CloudUploadContent/CloudUploadContent.qml` | 无 | 🟥 | 服务:CloudUploadService | M | 高（依赖 rclone） |
| 工具内容/后端 | `Tools/{ToolsBackend,ToolsContent}` | 同 | 🟨 | 无 | S | 低 |
| 音量内容 | `VolumeContent/VolumeContent.qml` | 同 | 🟨 | 无 | S | 低 |
| 天气内容 | `WeatherContent/**`（13 文件） | `WeatherContent/WeatherContent` + `WeatherLocationDialog` | 🟨 | C++:Weather、服务:WeatherPlugin | M | 中 |
| 通知内容 | `NotificationContent/NotificationContent.qml` | 同 | 🟨 | 无 | S | 低 |
| Hub 内容 | `Hub/HubContent.qml` | 同 | 🟨 | 无 | S | 低 |

## 2. Dashboard / 挖孔卡片

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| Dashboard 轮播容器 | `DashboardContent/DashboardContent.qml` | `OverviewContent/OverviewContent.qml` | 🟨 | 无 | M | 中 |
| Keyhole 挖孔卡片 | `DashboardContent/KeyholeCard.qml` | 无 | 🟥 | 无 | M | 中 |
| 时钟卡 | `DashboardContent/DashboardClock.qml` | `ClockContent/ClockContent.qml` | 🟨 | 无 | M | 中 |
| 日历卡 | `DashboardContent/CalendarCard.qml` | `OverviewContent/CalendarWidget.qml` | 🟨 | 无 | S | 低 |
| 天气卡 | `DashboardContent/DashboardWeatherCard.qml` | `WeatherContent` | 🟨 | C++:Weather | M | 中 |
| 番茄钟卡 | `DashboardContent/DashboardPomodoroCard.qml` | 无 | 🟥 | 服务:TimerService | S | 低 |
| 用户卡 | `DashboardContent/UserCard.qml` | 无 | 🟥 | 无 | S | 低 |
| 一言/日签 | 无 | `OverviewContent/IllustrationHitokoto.qml` | 🟩 | 无 | — | — |
| 日程/系统信息卡 | 无 | `OverviewContent/{ScheduleWidget,SysInfoWidget}.qml` | 🟩 | 无 | — | — |

## 3. 媒体 / 歌词

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 媒体封面/背景 | `MediaContent/{CaelestiaCover,MediaBackdrop,MediaCover}.qml` | `MediaContent/MediaContent.qml` | 🟨 | C++:Media | M | 中 |
| 歌词（横/竖/频谱/专辑图） | `LyricsContent/{HorizontalLyricsLayout,VerticalLyricsLayout,LyricsSpectrum,LyricsAlbumArt}.qml` | `LyricsContent/LyricsContent` + `Common/{LyricsSyncEngine,LyricsDaemon}` + `Widgets/common/SpringLyricView` | 🟨（本地逐字实现更完整） | C++:Lyrics、服务:LyricsTrackService | M | 中 |
| Caelestia 频谱 | `MediaContent` + `Clavis.Cava` | `Widgets/common/RadialSpectrum` + `Services/AudioSpectrum` | 🟨 | C++:Cava | M | 中 |
| 歌词抓取脚本 | `Services/LyricsTrackService`（C++） | `scripts/media/{lyrics_fetcher,title_parser}.py` | 🟩（本地 Python 方案） | 无 | — | — |

## 4. 天气 / 地图

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 天气主界面 | `WeatherContent/WeatherContent.qml` | 同 | 🟨 | C++:Weather | M | 中 |
| 5 日预报/月相/日出日落/AQI/参数 | `WeatherContent/{WeatherFiveDayForecast,WeatherMoonPhase,WeatherSunriseSunset,WeatherAQIIndicator,WeatherParameters}.qml` | 部分 | 🟨 | C++:Weather | M | 中 |
| **天气地图** | `WeatherContent/{WeatherMapCard,MapLegend,WeatherMapLayerSelector,FrostedMapSurface}` + `Modules/Map/**` | 无 | 🟥 | C++:WeatherMap、外部:MapTiler 密钥 | L | 高 |
| 3D 地图 | `Modules/Map/{MapLibreMap,MapLibreView,MapLibreWeatherMap,MapCoordinateMarker,...}` | 无 | 🟥 | C++:WeatherMap | L | 高 |
| 位置选择器 | `ControlCenter/{LocationPicker,LocationPickerWindow,LocationMapAttribution}` | 无 | 🟥 | C++:Weather | M | 中 |
| 位置手动配置对话框 | 无 | `DynamicIsland/WeatherContent/WeatherLocationDialog.qml` | 🟩 | 无 | — | — |

## 5. Dock（上游独有）

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| Dock 主容器 | `Dock/{DockSurface,DockHost,DockBubbleSurface}` | 无 | 🟥 | 无 | L | 中 |
| 图标放大/拖拽排序 | `Dock/{DockItem,DockDragVisual}` | 无 | 🟥 | 无 | M | 中 |
| 文件夹扇出/文件堆/回收站 | `Dock/{DockFolderFan,DockFolderMenu,DockFolderModel,DockFileTile,DockFilePopup,DockFileArtwork,DockFileIcon,DockFileDrag}` | 无 | 🟥 | C++:Files | L | 高 |
| 窗口缩略图预览 | `Dock/{DockPreviewPopup,DockWindowCard}` | 无 | 🟥 | C++:WindowPreview、外部:tools/window-preview | L | 高 |
| 最小化动画（Genie/Scale） | `Dock/*` + `Clavis.Niri` 最小化 API | 无 | 🟥 | C++:Niri（新 API） | L | 高 |

## 6. 电源菜单（上游独有）

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| PowerMenu 窗口 | `PowerMenu/{PowerMenu,PowerMenuWindow}.qml` | 无（本地 `Bar/PowerButton` + `Sidebars/Right/PowerContent`） | 🟥 | 服务:PowerMenuService、PowerService、systemd | M | 中 |

## 7. 锁屏

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 默认锁屏样式 | `Lock/{DefaultLock,DefaultLockContent,DefaultLockStatus,CaelestiaLock}.qml` | `Lock/{Lock,LockContent,LockSurface}.qml` + 7 Cards | 🟨 | 无 | M | 中 |
| 预捕获快照 | `Lock/PreLockCapture.qml` + `scripts/capture/LockSnapshot.qml` | `Services/LockSnapshot.qml` + `scripts/capture/record.sh` | 🟨 | Quickshell ScreencopyView | S | 低 |
| 状态栏/媒体控件 | `DefaultLockStatus.qml` | `Cards/{MediaCard,SystemGrid,WeatherCard}.qml` | 🟨 | 无 | S | 低 |
| PAM 鉴权 | `Lock/pam/password.conf` | 同 | 共有 | PAM | — | — |

## 8. 侧边栏

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 左侧 Dashboard 侧栏 | `Sidebars/Dashboard/{DashboardSidebar,WeatherView,InfoView,ProfileHeaderCard,...}`（~40 文件） | 无（用户当时未迁移） | 🟥 | C++:Weather | L | 中 |
| 信息工具（番茄钟/秒表/任务/待办/定时器/日历） | `Sidebars/Dashboard/infoTools/{PomodoroTimer,Stopwatch,TaskList,TodoWidget,TimerWidget,CalendarWidget}` | 无 | 🟥 | 服务:TimerService、TodoService | M | 中 |
| 通知中心列表（拖拽管理） | `Sidebars/Dashboard/notifications/**`（14 文件） | `Services/NotificationManager` + `DynamicIsland/NotificationContent` | 🟨 | 无 | M | 中 |
| 天气趋势图/卡片 | `Sidebars/Dashboard/{WeatherTrendChart,Weather*Card}.qml` | 无 | 🟥 | C++:Weather | M | 中 |
| 右侧 QuickSettings 内容 | `Sidebars/QuickSettings/{Audio,Bluetooth,Idle}Content` | `Sidebars/Right/{Audio,Bluetooth,Brightness,Clipboard,Network,Notifications,Power,Settings}Content` | 🟨（本地内容更多） | 无 | M | 中 |
| 侧栏可调位置/细粒度卡片 | `Common/SidebarPolicy.js` + 各 Window | 无 | 🟥 | 无 | M | 中 |

## 9. 控制中心 / 设置中心

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 设置中心框架（导航栏/路由/页面宿主） | `ControlCenter/{ControlCenterWindow,SettingsPageHost,NavigationRail*,PageTransitionLayer}` | `Modules/ControlCenter/WallpaperPage` | 🟥 | 无 | L | 中 |
| 通用设置页 | `ControlCenter/{GeneralPage,GeneralBarPage,GeneralSidebarPage,GeneralEffectsPage,GeneralOverviewPage}` | 无 | 🟥 | 无 | M | 中 |
| 显示/伽马设置 | `ControlCenter/{DisplaysPage,DisplayConfigurationPage,DisplayAdvancedSettings,GammaControlPage,DisplayLayoutCanvas,DisplayColumnWidths}` | 无 | 🟥 | C++:Gamma、服务:DisplayConfigService | L | 高 |
| 网络设置页 | `ControlCenter/{NetworkPage,AddNetworkPage,SavedNetworksPage,NetworkConfigWindow,NetworkProfileEditor}` | `Sidebars/Right/NetworkContent` | 🟨 | 服务:NetworkService | M | 中 |
| 蓝牙设置页 | `ControlCenter/{BluetoothDevicePage,BluetoothPairingPage,ConnectedDevicesPage}` | `Sidebars/Right/BluetoothContent` | 🟨 | 服务:BluetoothService | M | 中 |
| niri 配置页 | `Services/NiriConfigService` + `scripts/system/niri_config.py` | 无 | 🟥 | 外部工具:python kdl | M | 中 |
| 默认应用/开机自启 | `ControlCenter/{DefaultAppsPage,AutostartPage}` + `Services/{DefaultApplicationsService,AutostartService}` | 无 | 🟥 | 无 | M | 中 |
| 账户/头像/banner | `ControlCenter/{AccountPage,ProfileBannerEditor}` + `Services/AvatarService` | 无 | 🟥 | 无 | M | 中 |
| 快捷键设置 + shortcut map | `Services/ShortcutMapService` + `Common/ShortcutKeySymbols.js` | 无 | 🟥 | 无 | L | 中 |
| 云盘/rclone/备份 | `ControlCenter/{BackupSetupPage,BackupTaskPage,CloudRemoteManagerWindow,CloudRemoteWizard,ComputerBackupWindow}` + `Services/RcloneService` | 无 | 🟥 | 外部工具:rclone | L | 高 |
| Dock/Bar/Keystone 位置设置 | `ControlCenter/{DockPage,GeneralBarPage,KeystonePage,KeystoneSection,EdgePositionSelector,BarLayoutDragCoordinator}` | 无 | 🟥 | 无 | M | 中 |
| 水平时钟自定义 | `ControlCenter/{HorizontalClockPage,HorizontalClockPreview,ClockSliderSetting}` | 无 | 🟥 | 无 | S | 低 |
| 语言/地区 | `ControlCenter/LanguageAndRegionPage` + `Services/I18nService` | 无 | 🟥 | i18n | M | 中 |
| 光标主题 | `ControlCenter/CursorThemeSelect` + `scripts/theme/list_cursor_icon_themes.sh` | 无 | 🟥 | 无 | S | 低 |
| 贝塞尔曲线编辑器 | `ControlCenter/{BezierCurveEditor,BezierCurveLayerEditor}` | 无（用户当时明确跳过） | 🟥 | 无 | M | 低 |
| 主题/配色（matugen 模板） | `ControlCenter/ThemePage` + `Services/{ThemeService,MatugenTemplateService}` + `matugen/**` | 本地固定 Catppuccin + `ColorMap` | 🟥 | matugen | M | 高（与本地策略冲突） |

## 10. 启动器 / Spotlight

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| Spotlight 网格/样式/搜索栏 | `Launcher/{SpotlightAppGrid,SpotlightStyle,SpotlightSearchBar,SpotlightResultsPanel}` | `Launcher/{AppPage,RofiStyle,LauncherWindow}` | 🟨 | 无 | L | 中 |
| App 提供者/拖拽/使用频率 | `Launcher/{SpotlightAppProvider,SpotlightAppDrag}` + `Services/SpotlightAppUsage` | `Launcher/AppPage` | 🟨 | 无 | M | 中 |
| 文件搜索 | `Launcher/SpotlightFileProvider` + `Services/FileSearchService` | 无 | 🟥 | C++:Files | M | 中 |
| 剪贴板提供者/detail | `Launcher/{SpotlightClipboardProvider,SpotlightClipboardDetails}` | `Sidebars/Right/ClipboardContent` | 🟨 | 无 | M | 中 |
| 命令/搜索引擎/汇率/时区 | `Launcher/{SpotlightCommandProvider,SpotlightSearchProvider,SpotlightCurrencyController,SpotlightConversionEditor,SpotlightToolPanel}` | 无 | 🟥 | 无 | M | 中 |
| 壁纸提供者 | `Launcher/SpotlightWallpaperProvider` | 无 | 🟥 | 服务:WallpaperService | S | 低 |
| 会话控制 | `Launcher/SpotlightSessionController` | 无 | 🟥 | 无 | S | 低 |

## 11. Bar

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 横向/竖向 Bar | `Bar/{BarAxis,HorizontalBarWindow,VerticalBarWindow,HorizontalBarContent,VerticalBarContent,BarSection,BarContent,BarComponentLoader}` | `Bar/Bar.qml`（单一） | 🟨 | 无 | M | 中 |
| 媒体控件条 | `Bar/Media/MediaBar.qml` | 无 | 🟥 | 服务:MediaManager | S | 低 |
| 电池 | `Bar/QuickSettings/Battery.qml` | 无 | 🟥 | 无 | S | 低 |
| 资源饼 | `Bar/SysMonitor/ResourcePie.qml` | `Bar/SysMonitor/SysMonitor.qml` | 🟨 | 服务:SystemMonitorService | S | 低 |
| 托盘/工作区/活动窗口 | `Bar/{Tray,Workspaces,ActiveWindow}/**` | 同 | 🟨 | C++:Niri | S | 低 |
| 快捷设置滚轮/药丸背景 | `Bar/QuickSettings/*`、`Widgets/common/{TopBarPill,TopBarPillBackground,WheelScrollController}` | 本地 QuickSettings 子目录 | 🟨 | 无 | M | 中 |

## 12. 剪贴板

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 剪贴板服务（历史/搜索/文件） | `Services/ClipboardService.qml` | `Services/ClipboardService.qml` | 🟨 | 外部工具:wl-clipboard | M | 中 |
| detail 面板/滚动条/MD3 输入框 | `Launcher/SpotlightClipboardDetails` + `Widgets/common/{Material*TextField,StyledScrollBar}` | `Sidebars/Right/ClipboardContent` | 🟨 | 无 | M | 中 |

## 13. 录制 / 录音

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 录制服务/协调 | `Services/{RecordingService,RecordingCoordinator,AudioRecordingService}` | `DynamicIsland/Tools/ToolsBackend` + `scripts/capture/record.sh` | 🟨 | 外部工具:slurp/wf-recorder | M | 中 |
| Pill 分裂/波形动效 | `Keystone/Styles/Recording/**`（9 文件） | 无 | 🟥 | 无 | M | 中 |

## 14. 系统监测

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 系统监测服务 | `Services/SystemMonitorService.qml` | `Services/`（无）+ `Bar/SysMonitor` | 🟨 | 外部工具:key-cli | M | 中 |
| SystemCards（时钟/电池/网络/存储/指标/迷你图） | `Modules/SystemCards/**`（32 文件）+ `Services/SystemCardService` | 无 | 🟥 | 服务:SystemCardService | L | 中 |

## 15. 通知

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 通知服务/中心列表/拖拽管理 | `Services/NotificationManager` + `Sidebars/Dashboard/notifications/**` | `Services/NotificationManager` + `DynamicIsland/NotificationContent` | 🟨 | 无 | M | 中 |

## 16. 桌面卡片 / 文件选择器 / 热角 / 区域选取（上游独有）

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 桌面卡片 | `Modules/DesktopCards/**`（5） + `Services/SystemCardDrag*` | 无 | 🟥 | C++:DesktopCards | L | 中 |
| 文件选择器窗口 | `Modules/FilePicker/FilePickerWindow.qml` | `ControlCenter/WallpaperFileBrowser`（仅壁纸） | 🟨 | C++:Files | M | 中 |
| 热角 | `Modules/HotCorners/HotCorners.qml` | 无 | 🟥 | 无 | S | 低 |
| 区域选取 | `Modules/RegionSelector/**` + `Services/RegionSelectionService` | `scripts/capture/record.sh`（slurp） | 🟨 | 外部工具:slurp | S | 低 |

## 17. 壁纸

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 壁纸背景（简化） | `Wallpaper/WallpaperBackground.qml` | 同 | 🟨 | 无 | S | 低 |
| 过渡着色器/视差 | `Wallpaper/{WallpaperTransitionSurface,WallpaperImageViewport}` + `Services/WallpaperSceneService` + `assets/shaders` | 无（用户当时跳过着色器） | 🟥 | 无 | M | 中 |
| 桌面壁纸/概览壁纸 | `Wallpaper/{DesktopWallpaper,OverviewWallpaper}.qml` | 无 | 🟥 | 无 | M | 中 |
| 壁纸调色板/Zen | `Wallpaper/ZenPaletteRenderer` + `Services/{WallpaperPaletteSession,MediaPalette}` | `Services/MediaPalette` | 🟨 | 无 | M | 中 |
| 壁纸管理页 | `ControlCenter/Wallpaper*` | `ControlCenter/Wallpaper*` + `Launcher/WallpaperPage` | 🟨 | 无 | S | 低 |

## 18. i18n（上游独有）

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 多语言（中/繁/英） | `i18n/clavis_{zh_CN,zh_TW,en_US}.ts` + `Services/I18nService` + `Clavis.I` | 无（中文硬编码） | 🟥 | C++:I | M | 中 |

## 19. 构建 / 安装（上游独有）

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| CMake/安装脚本/打包 | `CMakeLists.txt`、`install.sh`、`packaging/`、`VERSION`、`scripts/install/*` | `start-quickshell.sh`（Clavis 环境包装） | 🟨 | 无 | M | 中 |
| 开发/热重载 | `scripts/dev/*`、`Common/KeystoneMotion` + `Clavis.Runtime` | 无 | 🟥 | C++:Runtime | M | 中 |

## 20. C++ 核心插件

| 功能 | 上游入口 | 本地入口 | 状态 | 依赖 | 成本 | 风险 |
|---|---|---|---|---|---|---|
| 插件构建 | `core/plugin/{cava,desktopcards,files,gamma,i18n,keyboard,lyrics,media,niri,runtime,weather,weathermap,windowpreview}` | 已编译 5 个（Keyboard/Media/Niri/Weather/Sysmon） | 🟨 | Qt6/cmake/cava/librclone 等 | L | 高 |

---

## 附：迁移优先级建议（低风险 → 高风险）

1. **低成本高收益（S，纯 QML，无新依赖）**
   - Bar：电池、媒体控件条、资源饼对齐、托盘/药丸背景
   - Dashboard：日历卡、番茄钟卡、用户卡、Keyhole 卡
   - 热角 HotCorners、区域选取 RegionSelector、光标主题、水平时钟自定义
   - 锁屏预捕获、键盘锁指示
   - 录制 Pill 分裂动效（纯 QML 部分）
2. **中等成本（M，需适配命名/服务）**
   - 侧边栏信息工具（番茄钟/秒表/待办/定时器）
   - Spotlight 网格 + 命令/搜索/汇率/时区
   - 网络/蓝牙设置页
   - 快捷键配置系统 + shortcut map
   - PowerMenu
   - Wallpaper 过渡/视差/桌面壁纸/调色板
   - 通知中心列表
   - i18n（若需要多语言）
3. **高成本/高依赖（L，需新 C++ 插件或外部工具）**
   - Dock（依赖 Files/WindowPreview/Niri 最小化）
   - 天气地图 / 3D 地图（依赖 WeatherMap + MapTiler 密钥）
   - 设置中心框架 + 显示/伽马设置（依赖 Gamma）
   - 云盘 rclone + 备份（依赖 rclone）
   - 左侧 Dashboard 侧栏（天气趋势，依赖 Weather）
   - DesktopCards / SystemCards（依赖 DesktopCards 插件）
   - C++ 插件整体升级（13 个）
4. **不推荐**
   - matugen 动态主题（与本地固定 Catppuccin + `ColorMap` 策略冲突）
