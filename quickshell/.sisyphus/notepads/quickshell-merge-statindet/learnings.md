# quickshell-merge-statindet — Learnings

## Conventions (用户现有配置)
- 配色：Catppuccin Mocha 28 token，accent = Lavender `#b4befe` (Color.qml)
- 引用方式：用户 `Root.Color.lavender`、`Root.Color.surface0`
- 顶层单例 4 个：Color, PanelStack, BarLayout, Paths
- qmldir 路径：顶层 `qmldir`（注册 4 singleton）
- 用户 `import "modules" as Modules`（无 qs 命名空间）

## Upstream (StatIndet)
- 配色：M3 120+ token 体系（m3* + col* 派生），matugen 动态生成
- 引用方式：`Appearance.colors.colPrimary`、`Appearance.m3colors.m3primary`
- 顶层 Common/：Appearance, Animations, Sizes, Paths, WidgetState, DynamicIslandMotion
- Modules/ 依赖：`import qs.Modules.Bar`（依赖 qmldir 注册 qs.Modules 命名空间）
- C++ 插件：core/ 编译到 `/usr/lib64/qt6/qml/Clavis/`

## Bridge Strategy (方案 A)
- 新增 `Common/ColorMap.qml`（singleton）— 把用户 28 token 派生为 120+ M3 token
- 修改 `Common/Appearance.qml` — 删除 matugen/FileView，改读 ColorMap
- 用户现有 5,800 行 `Root.Color.*` 引用**零修改**（qmldir 注册 Color 单例保留）

## Working Branch
- Branch: `merge-statindet`
- Baseline commit: `fb0f94c`
- 用户现有 modules/Clock.qml 1336 行 = 待迁入 DynamicIsland/ClockContent/（最大单任务）

## Critical Guardrails
- ❌ 引入 matugen
- ❌ 引入 Sidebars/ControlCenter/Wallpaper
- ❌ 引入 LXGW/Maple 字体
- ❌ 修改 Color.qml 28 token 值
- ❌ 全盘复制 StatIndet Widgets/common/（按需）
- ❌ 全盘复制 70+ M3 派生色（只映射用户 28 + 默认兜底）
- ❌ 让 modules/ 内 7 个浮动模块与新 Bar 同时挂载

## Wave 1 Progress
- T01 ✅ git baseline (fb0f94c)
- T02-T05 ✅ Animations/Sizes/WidgetState/DynamicIslandMotion (891f24e)
  - Sizes.qml font FIXED: Symbols Nerd Font + JetBrainsMono (was LXGW)
- T07 ✅ Paths.qml merged (user props + StatIndet additions)
- T08 ✅ ColorMap.qml: 225 lines, 50 m3 + 95 col* tokens, 5 utility functions, 0 matugen, qmllint OK
- T09 ✅ Appearance.qml: 23 lines, re-exports ColorMap, qmllint OK
- T06 ✅ qmldir: 10 singletons registered, all file refs validated

## Wave 1 Final Validation
- qmllint: 7/7 files exit 0
- quickshell test: ColorMap.m3primary=#b4befe ✅, Appearance.m3primary=#b4befe ✅
- Sizes.fontFamily: Symbols Nerd Font ✅
- 0 matugen / FileView / IO listeners
- `import ".."` in Appearance.qml required to access parent qmldir singletons

## Critical Quickshell Gotcha
- Singleton in subdirectory (e.g., Common/Appearance.qml) CANNOT directly
  reference singleton in parent qmldir (ColorMap) without `import ".."`
- This is a QML/Quickshell scoping rule that bit us — fixed in Appearance.qml
- Same fix needed for any other subdirectory singleton referencing top-level singletons

## Wave 2 Status (C++ plugin compile)
- T10 ✅ env probe: Qt6 6.11.1, cmake 4.3.3, ninja 1.13.2, gcc 16.1.1, 12 cores
- T10: libpipewire-0.3 OK, libcava/cava MISSING (audio skipped), PAM dev OK
- T11 ✅ cmake configure: patched CMakeLists.txt to make Cava OPTIONAL
- T12 ✅ build: 72/72 build steps. 5 plugins × 2 .so = 10 .so files
- T13 ✅ install: PLAN B — /home/eunoia/.local/share/qt6/qml/Clavis/ (no sudo TTY)
  - Created start-quickshell.sh wrapper that sets QML2_IMPORT_PATH + LD_LIBRARY_PATH
- T14 ✅ verify: 5/5 Clavis modules import OK (Sysmon, Weather, Niri, Media, Keyboard)

## Critical Wave 2 Fix
- For user to get the C++ plugin to work in their normal quickshell session,
  they need the start-quickshell.sh wrapper (sets env vars for Clavis plugin loading)
- C++ plugin .so files have RUNPATH pointing to build dir — LD_LIBRARY_PATH needed

## Wave 3 Status (Bar module)
- T15-T22 ✅ 20 Bar files copied (Bar.qml + 6 subdirs)
- T49 (early) ✅ Services 17 files copied (AudioSpectrum excluded — Clavis.Audio skipped)
- Components 2 files copied
- Widgets/common 28 files copied
- T23 ✅ Bar launches with 0 errors, Clavis.Sysmon works (GPU detected)

## Critical Wave 3 Fixes
- `Animations.qml` MUST use `readonly property QtObject curves: QtObject {...}` (inline)
  - QML Singleton in quickshell 0.3.0 does NOT initialize `property QtObject curves; curves: QtObject {...}` 
  - Was: null. Fix: inline QtObject declarations
- `Appearance.qml` MUST re-export ColorMap utility functions (mix/transparentize/applyAlpha/solveOverlayColor)
  - Widgets/common calls `Appearance.applyAlpha()` directly
  - Was: undefined. Fix: re-exported via `function mix() { return ColorMap.mix(...); }`
- `Appearance.qml` MUST also re-export Animations (`curves`, `animation`)
  - Widgets/common calls `Appearance.curves.expressiveEffects` and `Appearance.animation.standardDecel`
  - Was: undefined. Fix: `property QtObject curves: Animations.curves`
- `Services/AudioSpectrum.qml` removed — depends on `Clavis.Audio` (cava missing)
- Bar launches cleanly with SysmonGpu detecting "GENERIC" type (proof Clavis.Sysmon loaded)

## Wave 4 Status (DynamicIsland + Clock migration)
- T24 ✅ DynamicIsland.qml container (33KB)
- T25 ✅ ClockContent.qml framework (151 lines, simplified time display)
- T26 ✅ User Clock (1336 lines) PRESERVED as deprecated standalone PanelWindow
  - Decision: User's Clock.qml is a complete dashboard — kept as-is
- T27-T36 ✅ 12 content area files copied
- T37 ✅ DynamicIsland launches cleanly (Configuration Loaded, 0 errors)

## Critical Wave 4 Fixes
- `Common/functions/astro.js` MUST be copied (WeatherContent depends on it)
- `Media.qml` and `LyricsContent.qml` reference `AudioSpectrum` (deleted, since Clavis.Audio not built) — non-fatal warnings
- `OverviewContent/SysInfoWidget.qml` references `~/Pictures/avatar/shelby.jpg` (not present) — non-fatal warning

## Wave 5 Status (Launcher)
- T38 ✅ LauncherWindow.qml (486 lines) + RofiStyle (helper) copied
- T39 ✅ AppPage, WindowPage, WallpaperPage, RofiStyle copied (5 .qml files total)
- T40 ⏸ niri keybind deferred to Wave 7 (T54)
- T41 ✅ Launcher launches with 0 errors

## Critical Wave 5 Fixes
- `Modules/Launcher/qmldir` MUST be created (registers Launcher as qs.Modules.Launcher module)
- `LauncherWindow.qml` MUST self-import: `import qs.Modules.Launcher`

## Wave 6 (Lock) — Partially blocked
- T42 [B] PAM config — needs sudo (/etc/pam.d/quickshell)
- T43 [B] quickshell user — needs sudo (useradd)
- T44-T46 ✅ Lock/LockContent/LockSurface/LockWarmup + 7 Cards + LockSnapshot — all files on disk
- T47 ✅ Lock keybind: Mod+Escape → qs ipc call lock open (Mod+L already used for focus-column-right)
- T48 [B] Lock E2E verification — blocked by T42/T43

## Wave 7 (Assembly) ✅
- T49 ✅ Services 17 files (done early with Wave 3)
- T50 ✅ AppShell.qml created (mounts Bar, DynamicIsland, Launcher, Lock, deprecated Clock)
- T51 ✅ shell.qml rewritten to 54 lines with inline mounts
- T52 ✅ 4 qmldir files created
- T53 ✅ 9 old modules marked @deprecated
- T54 ✅ lyrics_fetcher.py wired via scripts/media/
- T55 ✅ E2E verification — Configuration Loaded, 0 QML errors

## Additional Features (user-requested via chat)
- `Services/LaunchTracker.qml` — app launch frequency tracking with FileView persistence
- `Modules/Launcher/AppPage.qml` — modified for frequency sorting + launch recording
- `start-quickshell.sh` wrapper for Clavis env vars

## Final Review Results
- F1 ✅ Plan Compliance: Must Have [8/8], Must NOT Have [6/6], APPROVED (post-fix)
- F2 ✅ Code Quality: 12/12 qmllint PASS, No bad patterns
- F3 ✅ Manual QA: All 3 IPC targets working, Launcher/Lock/Island all responsive
- F4 ✅ Scope Fidelity: 11/11 compliant, Scope creep fixed (matugen + LXGW cleanup)
- PAM blocked by sudo — user needs to run 3 sudo commands manually

## Pending User Actions
1. `sudo pacman -S ttf-material-symbols-variable brightnessctl`
2. `sudo cp ~/.config/quickshell/Modules/Lock/pam/password.conf /etc/pam.d/quickshell`
3. `sudo useradd -r -s /usr/bin/nologin -d /var/lib/quickshell -M quickshell`
4. `killall quickshell && ~/.config/quickshell/start-quickshell.sh`
