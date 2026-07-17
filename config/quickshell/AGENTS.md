# AGENTS.md

AI coding agents guide for `quickshell` — a Wayland desktop shell configuration.

## Project Overview

A complete desktop shell UI for the **Niri** Wayland compositor, built on **Quickshell** (a Qt6/QML Wayland shell framework). Provides a Dynamic Island (à la Apple), system bar, right sidebar, launcher, lock screen, and wallpaper management. All logic lives in QML/JS with Python helper scripts and GLSL shaders.

**Target audience**: AI agents (pi, Claude, Cursor, Copilot) making changes to this codebase.

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Runtime | **Quickshell** (Qt6 QML shell) | latest git |
| Language | **QML + JavaScript** | Qt 6.x |
| Scripts | **Python 3** | stdlib only (no pip deps) |
| Shaders | **GLSL** → `.qsb` (Qt Shader Baker) | — |
| Compositor | **Niri** (scrollable-tiling Wayland) | latest |
| Plugins | **Clavis** (custom C++ Qt plugins) | local build |

## Run & Test

```bash
./start-quickshell.sh          # Full launch (sets Clavis env vars, execs quickshell)
quickshell                      # Direct launch (needs env vars pre-set)
```

**No build step** — QML is interpreted at runtime. Shader `.qsb` files in `assets/shaders/wallpaper/qsb/` are pre-compiled from `.frag` sources.

**Syntax validation**:
```bash
python3 -c "import py_compile; py_compile.compile('scripts/media/lyrics_fetcher.py', doraise=True)"
QT_QPA_PLATFORM=offscreen ./start-quickshell.sh   # Headless QML load test
```

## Project Structure

```
.
├── shell.qml              # Entry point: ShellRoot { AppShell {} }
├── AppShell.qml           # Top-level assembly, mounts all modules, registers IPC handlers
├── start-quickshell.sh    # Launch wrapper (sets Clavis env vars)
├── qmldir                 # Root: global singletons (Color, Appearance, Paths, LyricsSyncEngine, etc.)
├── Color.qml              # Catppuccin Mocha palette singleton
│
├── Common/                # Shared primitives (no UI — only logic, constants, tokens)
│   ├── ColorMap.qml       # Catppuccin + Material 3 color tokens, utility functions
│   ├── Appearance.qml     # Single import: re-exports ColorMap + Animations
│   ├── Animations.qml     # M3 motion tokens (duration, easing curves)
│   ├── Sizes.qml          # Font families, corner radius, lock screen dimensions
│   ├── Paths.qml          # All filesystem paths (scripts, cache, assets, icons)
│   ├── WidgetState.qml    # Shared UI state (sidebar open, popup positions)
│   ├── LyricsSyncEngine.qml  # Lyric binary-search sync engine (pragma Singleton)
│   ├── LyricsDaemon.qml   # Long-lived Python lyric fetcher process manager
│   └── functions/         # JS utility modules (.pragma library)
│
├── Services/              # System integration singletons (module: qs.Services)
│   ├── Volume.qml         # Pipewire/PulseAudio volume control
│   ├── Network.qml        # NetworkManager binding
│   ├── BluetoothService.qml
│   ├── Brightness.qml     # Backlight control
│   ├── MediaManager.qml   # MPRIS player tracking
│   ├── MediaPalette.qml   # Dominant color extraction from album art
│   ├── NotificationManager.qml
│   ├── AudioSpectrum.qml  # Real-time FFT audio visualization
│   ├── WallpaperService.qml
│   ├── Time.qml, Idle.qml, LaunchTracker.qml
│   └── qmldir             # module qs.Services (all singletons)
│
├── Modules/               # Major UI panels (module: qs.Modules)
│   ├── Bar/               # Top panel bar (workspaces, tray, quick settings, sysmon)
│   ├── DynamicIsland/     # Dynamic Island (clock, lyrics, media, notifications, audio, hub)
│   ├── Launcher/          # App/wallpaper/window launcher (Rofi-style)
│   ├── Lock/              # Lock screen with PAM auth
│   ├── Sidebars/Right/    # Right sidebar (quick settings, audio, network, notifications)
│   ├── Wallpaper/         # Wallpaper rendering with shader transitions
│   ├── ControlCenter/     # Wallpaper picker/color control
│   └── qmldir             # module qs.Modules
│
├── Widgets/               # Reusable UI components
│   ├── common/            # 27 widgets: sliders, buttons, tooltips, spectrum, lyric view, etc.
│   └── audio/             # Volume slider variant
│
├── scripts/               # Python/bash helper scripts
│   ├── media/lyrics_fetcher.py  # Multi-source lyric fetcher (TTML/YRC/QRC/LRC)
│   ├── schedule/parse_schedule.py
│   ├── system/overview.sh
│   └── weather/weather.py
│
├── assets/shaders/wallpaper/  # GLSL fragment shaders + pre-compiled .qsb
└── Components/            # MaterialSymbol + SvgIcon base components
```

## Module System (QML Directory Imports)

All modules use QML `qmldir` files for namespace isolation:

| Module | Prefix | Contents |
|--------|--------|----------|
| Root `qmldir` | (global) | Singletons: `Color`, `Appearance`, `Paths`, `Sizes`, `LyricsSyncEngine`, `LyricsDaemon`, etc. |
| `Services/qmldir` | `qs.Services` | System singletons: `Volume`, `Network`, `MediaManager`, etc. |
| `Modules/qmldir` | `qs.Modules` | UI modules: `Bar`, `DynamicIsland`, `Launcher`, `Lock`, `Wallpaper`, etc. |
| `Widgets/common/` | `qs.Widgets.common` | Reusable widgets (no `qmldir` — resolved by directory) |

**Access pattern**: Root singletons are available everywhere without import. Module components need explicit `import qs.Services` / `import qs.Modules.X`.

## Dependency Flow (Bottom-Up)

```
Common/  →  Services/  →  Widgets/common/  →  Modules/  →  AppShell.qml
(no deps)   (uses Common)  (uses Services)     (assembles all)
```

- `Common/` has zero external dependencies. Other layers depend on it.
- `Services/` may depend on `Common/` singletons only.
- `Widgets/common/` may import `qs.Services` and `qs.Common`.
- `Modules/` imports from all layers.

## Architecture Patterns

### Singletons Everywhere
All shared state uses `pragma Singleton`. No manual instantiation — singleton properties are reactive bindings.

```qml
// Defining (in Common/LyricsSyncEngine.qml)
pragma Singleton
QtObject {
    property double playbackSeconds: 0
    readonly property int activeLineIndex: _activeLineIndex
}

// Registering (in root qmldir)
singleton LyricsSyncEngine Common/LyricsSyncEngine.qml

// Using (anywhere — no import needed for root singletons)
LyricsSyncEngine.playbackSeconds = posSec
```

### QtObject for Singletons (Not Item)
Singletons MUST extend `QtObject`, NOT `Item`. `QtObject` has no default property — children like `Timer` must be declared as properties:
```qml
// ✅ Correct
property Timer syncTimer: Timer { interval: 100; onTriggered: { ... } }

// ❌ Wrong — won't load
Timer { id: syncTimer; ... }
```

### Multi-Screen via Variants
```qml
Variants {
    model: Quickshell.screens
    PanelWindow {
        required property var modelData
        screen: modelData
        // One instance per monitor
    }
}
```

### IPC Handlers
`IpcHandler` in `AppShell.qml` exposes shell features via `quickshell ipc call`:
```
quickshell ipc call lock toggle
quickshell ipc call launcher show
quickshell ipc call wallpaper cycle
```

### Process Management
QML spawns external processes via `Process { command: [...]; stdout: SplitParser { onRead: ... } }`. 

For long-lived processes, use a singleton (e.g., `LyricsDaemon.qml`) that owns the `Process` object:
```qml
// Defining
QtObject {
    property Process proc: Process { command: ["python3", Paths.scriptPath("media", "lyrics_fetcher.py"), "--daemon"]; ... }
    function request(title, artist) { ... }
}

// Using
LyricsDaemon.request("晴天", "周杰伦")
```

### Python Fetcher Protocol
`scripts/media/lyrics_fetcher.py` supports two modes:
1. **CLI**: `python3 lyrics_fetcher.py "title" "artist"` → prints JSON to stdout
2. **Daemon**: `python3 lyrics_fetcher.py --daemon` → stdin JSON lines → stdout JSON lines

Output format: `{"format":"word"|"line", "source":"ttml"|"netease-yrc"|"qq-qrc"|"qq-lrc"|"netease-lrc", "lines":[...], "_legacy":[...]}`

Priority chain: TTML (AMLL DB) → QQ QRC → NetEase YRC → QQ LRC → NetEase LRC

## Code Conventions

| Rule | Example |
|------|---------|
| **Comments in Chinese** | `// 歌词同步引擎` not `// Lyrics sync engine` |
| **Colors via Appearance** | `Appearance.colors.colPrimary` not `"#b4befe"` (except in SpringLyricView where init order prevents it) |
| **Animation via tokens** | `Appearance.animation.scroll.duration`, `Appearance.curves.emphasized` |
| **Paths via Paths singleton** | `Paths.scriptPath("media", "lyrics_fetcher.py")` |
| **Wayland layer namespace** | `WlrLayershell.namespace: "clavis-dynamic-island"` |
| **No raw hex colors** (exceptions: visual widgets with init-order issues) | Prefer `Color.lavender` or `Appearance.colors.colPrimary` |
| **Python: stdlib only** | No `pip install` dependencies |
| **Python: metadata filtering** | Use SPlayer's `META_TAG_REGEX` (`^\[[a-z]+:`) + `_CN_META_REGEX` |

## Key Files for Common Tasks

| Task | Files |
|------|-------|
| Add global state | `Common/` (new singleton) + root `qmldir` |
| Add system service | `Services/` (new singleton) + `Services/qmldir` |
| Add UI panel | `Modules/<Name>/` + `Modules/qmldir` |
| Add widget | `Widgets/common/` |
| Change lyric sources | `scripts/media/lyrics_fetcher.py` |
| Change lyric sync logic | `Common/LyricsSyncEngine.qml` |
| Change word-level rendering | `Widgets/common/SpringLyricView.qml` (expanded) or `Modules/DynamicIsland/LyricsContent/LyricsContent.qml` (compact) |
| Add root singleton | `Common/` + root `qmldir` line: `singleton Name Common/Name.qml` |

## Environment

The `start-quickshell.sh` wrapper sets:
```bash
QML2_IMPORT_PATH="/home/eunoia/.local/share/qt6/qml"
LD_LIBRARY_PATH=".../Clavis/Niri:.../Clavis/Sysmon:.../Clavis/Weather:.../Clavis/Media:.../Clavis/Keyboard:..."
```

These are required for the **Clavis** C++ plugins (Niri compositor bindings, system monitoring, weather, media, keyboard integration).

## Lyrics System (TL;DR for AI agents)

Three interacting components:

1. **Python fetcher** (`scripts/media/lyrics_fetcher.py`): Fetches from TTML DB, NetEase (YRC/LRC), QQ (QRC/LRC). Outputs unified `{format, source, lines, _legacy}`.

2. **Sync engine** (`Common/LyricsSyncEngine.qml`): Binary search + word progress calculation. Adaptive 50ms/100ms Timer.

3. **UI renderers**:
   - Compact bar: `LyricsContent.qml` — `Row` with context window truncation (±8 chars)
   - Expanded panel: `SpringLyricView.qml` — `Flow` with word-level color highlighting (`#b4befe`)

Metadata filtering follows SPlayer: `META_TAG_REGEX` (`^\[[a-z]+:`) at raw-line level + `_CN_META_REGEX` for Chinese production tags.

## Testing Strategy

**No automated test framework exists.** QA is manual:

- **Python**: Run `python3 scripts/media/lyrics_fetcher.py "title" "artist"` and inspect JSON
- **QML**: Launch `./start-quickshell.sh` in Wayland, observe behavior
- **Headless load test**: `QT_QPA_PLATFORM=offscreen ./start-quickshell.sh` (expects "No PanelWindow backend" — that's normal)
