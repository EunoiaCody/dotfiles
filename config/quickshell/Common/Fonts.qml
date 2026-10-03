pragma Singleton

// 字体角色单例。
// - ui/mono/numeric：用户可配置（默认 Nerd Font）
// - expressive/systemClock：使用捆绑的 Google Sans Flex 变量字体（供时钟/展示用）
import QtQuick
import Quickshell
import ".."

Singleton {
    id: root

    readonly property string defaultUi: Sizes.fontFamily
    readonly property string defaultMono: Sizes.fontFamilyMono
    readonly property string defaultNumeric: root.defaultMono
    readonly property string bundledFamilyName: bundledFont.name || "Google Sans Flex"

    property string configuredUi: ""
    property string configuredMono: ""
    property string configuredNumeric: ""
    property string configuredExpressive: ""

    readonly property string ui: root.resolveFamily(root.configuredUi, root.defaultUi, "")
    readonly property string mono: root.resolveFamily(root.configuredMono, root.defaultMono, "monospace")
    readonly property string numeric: root.resolveFamily(root.configuredNumeric, root.defaultNumeric, "monospace")
    readonly property string expressive: root.resolveFamily(root.configuredExpressive, root.bundledFamilyName,
                                                            root.ui)
    // 时钟必须始终使用捆绑字体（其变量轴 wght/ROND/opsz/slnt/wdth 才能正确生效）
    readonly property string systemClock: root.bundledFamilyName
    readonly property string materialSymbolsRounded: "Material Symbols Rounded"
    readonly property string materialSymbolsOutlined: "Material Symbols Outlined"

    function familyAvailable(family) {
        const value = String(family || "").trim();
        if (value === "")
            return false;
        if (value === root.bundledFamilyName)
            return bundledFont.status === FontLoader.Ready;
        return Qt.fontFamilies().indexOf(value) !== -1;
    }

    function resolveFamily(preferred, fallback, genericFallback) {
        const selected = String(preferred || "").trim();
        if (root.familyAvailable(selected))
            return selected;
        const defaultValue = String(fallback || "").trim();
        if (root.familyAvailable(defaultValue))
            return defaultValue;
        return genericFallback || "";
    }

    function setConfiguredFamily(role, family) {
        const value = String(family || "").trim();
        if (role === "ui")
            root.configuredUi = value;
        else if (role === "mono")
            root.configuredMono = value;
        else if (role === "numeric")
            root.configuredNumeric = value;
        else if (role === "expressive")
            root.configuredExpressive = value;
        else
            return false;
        return true;
    }

    function setConfiguredFamilies(ui, mono, numeric, expressive) {
        root.configuredUi = String(ui || "").trim();
        root.configuredMono = String(mono || "").trim();
        root.configuredNumeric = String(numeric || "").trim();
        root.configuredExpressive = String(expressive || "").trim();
    }

    function cssFamily(family) {
        return "\"" + String(family || "").replace(/\\/g, "\\\\").replace(/\"/g, "\\\"") + "\"";
    }

    FontLoader {
        id: bundledFont

        source: Paths.fileUrl(Paths.fontsDir + "/google-sans-flex/" + "GoogleSansFlex-VariableFont_"
                              + "GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }
}
