// qs: top-level app assembly
// mounts: WallpaperBackground, Bar, DynamicIsland, RightSidebar, LockWarmup, Lock, Launcher
// All module logic delegated to qs.Modules.* singletons.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Modules.Bar
import qs.Modules.DynamicIsland
import qs.Modules.Launcher
import qs.Modules.Lock
import qs.Modules.Sidebars.Right
import qs.Modules.Wallpaper
import qs.Services

Item {
    id: root

    Component.onCompleted: WallpaperService.primaryInstance = true

    // Wallpaper background (simplified, image only — no shader transitions)
    WallpaperBackground {}

    // Top Bar
    Bar {}

    // Dynamic Island (top center) — includes ClockContent (time), Hub (calendar), Media, Lyrics, Wallpaper
    DynamicIsland {}

    // Right Sidebar — QuickSettings / Audio / Network / Sliders / Settings
    RightSidebar {
        id: rightSidebar
    }

    // Lock screen warmup (pre-parse for faster lock activation)
    LockWarmup {}

    // Lock screen
    Lock {
        id: sessionLocker
    }

    // IPC handler for lock/unlock
    IpcHandler {
        target: "lock"

        function open() {
            return sessionLocker.open();
        }

        function isLocked() {
            return sessionLocker.isLocked();
        }
    }

    // Launcher (app/window/wallpaper pages)
    LauncherWindow {
        id: rofiLauncher
    }

    // IPC handler for launcher toggle
    IpcHandler {
        target: "launcher"

        function toggle() {
            rofiLauncher.toggleWindow();
            return "LAUNCHER_TOGGLED";
        }
    }

    // IPC handler for wallpaper control (set, clear, cycle, random)
    IpcHandler {
        target: "wallpaper"

        function set(path, screenName) {
            return WallpaperService.setWallpaper(path || "", screenName || "", true) ? "OK" : "PENDING";
        }

        function clear(screenName) {
            return WallpaperService.clearWallpaper(screenName || "", true) ? "OK" : "PENDING";
        }

        function previous() {
            return WallpaperService.cyclePrevious(true) ? "OK" : "PENDING";
        }

        function next() {
            return WallpaperService.cycleNext(true) ? "OK" : "PENDING";
        }

        function random() {
            return WallpaperService.cycleRandom(true) ? "OK" : "PENDING";
        }

        function setFolder(path) {
            return WallpaperService.setWallpaperFolder(path || "", true) ? "OK" : "PENDING";
        }
    }

    // IPC handler for clipboard history toggle
    IpcHandler {
        target: "clipboard"

        function toggle() {
            if (WidgetState.qsOpen && WidgetState.qsView === "clipboard") {
                WidgetState.qsOpen = false
            } else {
                WidgetState.qsView = "clipboard"
                WidgetState.qsOpen = true
            }
            return "CLIPBOARD_TOGGLED"
        }

        function show() {
            WidgetState.qsView = "clipboard"
            WidgetState.qsOpen = true
            return "CLIPBOARD_SHOWN"
        }

        function hide() {
            if (WidgetState.qsView === "clipboard")
                WidgetState.qsOpen = false
            return "CLIPBOARD_HIDDEN"
        }
    }
}
