// filepath: Common/Paths.qml
// Centralized path resolution for the quickshell config.
pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property string shellDir: Quickshell.shellDir
    readonly property string assetsDir: shellDir + "/assets"
    readonly property string iconsDir: assetsDir + "/icons"
    readonly property string appIconsDir: iconsDir + "/apps"
    readonly property string weatherIconsDir: iconsDir + "/weather"
    readonly property string meteoconsDir: weatherIconsDir + "/meteocons"
    readonly property string imagesDir: assetsDir + "/images"

    readonly property string scriptsDir: shellDir + "/scripts"
    readonly property string audioScriptsDir: scriptsDir + "/audio"
    readonly property string captureScriptsDir: scriptsDir + "/capture"
    readonly property string mediaScriptsDir: scriptsDir + "/media"
    readonly property string scheduleScriptsDir: scriptsDir + "/schedule"
    readonly property string systemScriptsDir: scriptsDir + "/system"
    readonly property string themeScriptsDir: scriptsDir + "/theme"
    readonly property string weatherScriptsDir: scriptsDir + "/weather"

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string currentWallpaper: homeDir + "/.cache/wallpaper_rofi/current"
    readonly property string scheduleCache: homeDir + "/.cache/quickshell/schedule.json"
    readonly property string defaultAvatar: homeDir + "/Pictures/avatar/shelby.jpg"
    readonly property string configDir: homeDir + "/.config"
    readonly property string cacheDir: homeDir + "/.cache"
    readonly property string picturesDir: homeDir + "/Pictures"
    readonly property string tmpDir: "/tmp"

    readonly property string wallpaperCacheDir: cacheDir + "/quickshell-wallpaper"
    readonly property string currentWallpaperFile: cacheDir + "/quickshell-wallpaper/current"

    // 截图 / 录屏 / OCR 落盘路径
    readonly property string screenshotsDir: picturesDir + "/Screenshots"
    readonly property string recordingsDir: homeDir + "/Videos/Recordings"
    readonly property string ocrDir: picturesDir + "/OCR"
    // 临时文件目录（用于 GIF 转码中间产物等）
    readonly property string captureTmpDir: tmpDir + "/niri-capture"

    function fileUrl(path) {
        const v = String(path);
        return v.startsWith("file://") ? v : "file://" + v;
    }

    function scriptPath(group, name) {
        return scriptsDir + "/" + group + "/" + name;
    }

    function icon(name) {
        return fileUrl(iconsDir + "/" + name);
    }

    function appIcon(name) {
        return fileUrl(appIconsDir + "/" + name);
    }

    function meteoconSvg(style, slug) {
        return fileUrl(meteoconsDir + "/svg/" + style + "/" + slug + ".svg");
    }

    function meteoconLottie(slug) {
        return fileUrl(meteoconsDir + "/lottie/fill/" + slug + ".json");
    }
}
