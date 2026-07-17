# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A custom Quickshell desktop shell configuration for Wayland (Niri compositor). Implements a Dynamic Island, system bar, lock screen, launcher, right sidebar, and wallpaper management — all in QML/JS with Python helper scripts and GLSL shader transitions.

## Running

```bash
./start-quickshell.sh       # Sets Clavis plugin env vars, then execs quickshell
quickshell                   # Direct launch (requires env vars already set)
```

There is no build step — QML is interpreted at runtime. Shader `.qsb` files are pre-compiled from `.frag` sources in `assets/shaders/wallpaper/frag/`.

## Architecture

**Entry point:** `shell.qml` → `AppShell.qml` → mounts all major UI modules.

**Module system** uses QML directory imports declared in `qmldir` files:
- Root `qmldir` — global singletons (Color, Appearance, Animations, Sizes, Paths, WidgetState, PanelStack, BarLayout, DynamicIslandMotion)
- `Services/qmldir` (module `qs.Services`) — 18 system service singletons (Network, Volume, Brightness, WallpaperService, MediaManager, etc.)
- `Modules/qmldir` (module `qs.Modules`) — UI modules (Bar, DynamicIsland, Launcher, Lock, Sidebars.Right, Wallpaper, ControlCenter)

**Dependency flow** (bottom-up):
1. `Common/` — Path constants, Catppuccin Mocha + Material 3 color tokens, M3 motion/animation tokens, Sizes, WidgetState
2. `Services/` — System integration singletons (audio, network, bluetooth, brightness, media, notifications, etc.)
3. `Widgets/common/` — 27 reusable UI components (sliders, buttons, tooltips, spectrum, lyric view, etc.)
4. `Modules/` — Major UI panels assembled from widgets + services
5. `AppShell.qml` — Top-level composition and IPC handler registration

## Key Patterns

- **Singletons everywhere.** All services and shared resources use `pragma Singleton`. Access via `qs.Services.Volume`, `qs.Common.Appearance`, etc.
- **Variants for multi-screen.** `Variants { model: Quickshell.screens }` renders one panel per monitor; each instance uses `required property var modelData`.
- **IPC handlers.** `IpcHandler` in AppShell exposes `quickshell ipc call <name> <method>` for external control (lock, launcher, wallpaper set/clear/cycle/random).
- **Path centralization.** All filesystem paths go through `Paths` singleton — never hardcode paths in QML/JS.
- **Appearance as the single import.** `Appearance.qml` re-exports everything from `ColorMap` (colors, rounding, spacing, utility functions) and `Animations` (curves, durations) so modules import only `Appearance`.
- **Clavis C++ plugins.** Custom Qt plugins at `~/.local/share/qt6/qml/Clavis/` provide Niri compositor bindings, system monitoring, weather, media, and keyboard integration. The launch wrapper sets `QML2_IMPORT_PATH` and `LD_LIBRARY_PATH` for these.

## Conventions

- QML files use Chinese comments — maintain this style in edits.
- Color references use `Appearance.colors.*` or `Appearance.m3colors.*`, not raw hex.
- Animation tokens use `Appearance.animation.*` (duration) and `Appearance.curves.*` (easing), following M3 motion specs.
- Wayland layer shell: each panel uses `WlrLayershell.layer` and `WlrLayershell.namespace` (e.g., `"clavis-dynamic-island"`, `"qs-unified-sidebar"`).
- Desktop files for apps in wallpaper/launcher are discovered via `LaunchTracker` and standard XDG paths.