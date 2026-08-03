.pragma library

function fuzzyMatch(input, text) {
    let lowerInput = input.toLowerCase();
    let lowerText = text.toLowerCase();
    let inputIndex = 0;

    for (let i = 0; i < lowerText.length; i++) {
        if (lowerText[i] === lowerInput[inputIndex]) {
            inputIndex++;
        }
        if (inputIndex === lowerInput.length) {
            return true;
        }
    }
    return false;
}

function searchableText(app) {
    let parts = [app.name, app.genericName, app.comment];
    if (app.execString) parts.push(app.execString);
    if (app.command) {
        if (typeof app.command === "string") parts.push(app.command);
        else if (Array.isArray(app.command)) parts.push(app.command.join(" "));
    }
    if (app.id) parts.push(app.id);
    if (app.startupClass) parts.push(app.startupClass);
    return parts.filter(p => p).join(" ");
}

function updateFilter(inputText, DesktopEntries) {
    let lowerInput = (inputText || "").toLowerCase();
    const apps = DesktopEntries.applications.values;
    let filterApps = [];

    if (lowerInput === "") {
        filterApps = apps;
    } else {
        filterApps = apps.filter((app) => fuzzyMatch(lowerInput, searchableText(app)));
    }

    // 过滤掉不可见的后台挂件
    filterApps = filterApps.filter(app => !app.noDisplay);

    // 强制按首字母 A-Z 排序
    filterApps.sort((a, b) => {
        let nameA = a.name ? a.name.toLowerCase() : "";
        let nameB = b.name ? b.name.toLowerCase() : "";
        if (nameA < nameB) return -1;
        if (nameA > nameB) return 1;
        return 0;
    });

    let result = [];
    for (let i = 0; i < filterApps.length; i++) {
        let app = filterApps[i];

        result.push({
            name: app.name,
            icon: app.icon || "",
            appObj: app
        });
    }

    return result;
}
