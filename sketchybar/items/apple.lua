local colors = require("colors")
local settings = require("settings")

local apple = sbar.add("item", "apple", {
    position = "left",
    icon = {
        string = "",
        font = {
            family = settings.font.nerd,
            style = "Bold",
            size = 18.0
        },
        color = colors.lavender,
        padding_left = 10,
        padding_right = 10
    },
    label = {
        drawing = false
    },
    background = {
        color = colors.surface0,
        border_color = colors.lavender,
        border_width = 2,
        corner_radius = 9
    },
    padding_left = 10,
    popup = {
        align = "left",
        background = {
            color = colors.base,
            border_color = colors.lavender,
            border_width = 2,
            corner_radius = 9
        }
    }
})

local popup_items = {}

local function create_popup_item(icon, label, script)
    local item = sbar.add("item", {
        position = "popup." .. apple.name,
        icon = {
            string = icon,
            font = {
                family = settings.font.nerd,
                size = 14.0
            },
            color = colors.lavender,
            padding_left = 10
        },
        label = {
            string = label,
            font = {
                family = settings.font.cjk,
                style = "Bold",
                size = 12.0
            },
            color = colors.text,
            padding_right = 10
        },
        click_script = script .. "; sketchybar --trigger apple_close",
        background = {
            color = colors.transparent,
            corner_radius = 5,
            drawing = true,
            height = 30,
            border_width = 0
        }
    })

    item:subscribe("mouse.entered", function(env)
        sbar.animate("sin", 10, function()
            item:set({
                background = {
                    color = colors.surface1
                },
                icon = {
                    color = colors.text
                }
            })
        end)
    end)

    item:subscribe("mouse.exited", function(env)
        sbar.animate("sin", 10, function()
            item:set({
                background = {
                    color = colors.transparent
                },
                icon = {
                    color = colors.lavender
                }
            })
        end)
    end)

    table.insert(popup_items, item)
    return item
end

sbar.add("event", "apple_close")
sbar.add("event", "apple_close_complete")

create_popup_item("", "系统设置", "open -a 'System Settings'")
create_popup_item("󰗼", "强制退出",
    "open /System/Library/CoreServices/Applications/Force\\ Quit\\ Applications.app")
create_popup_item("", "重新启动", "osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'")
create_popup_item("", "关机", "osascript -e 'tell app \"loginwindow\" to «event aevtshut»'")

local is_open = false

local function animate_open()
    is_open = true
    apple:set({
        popup = {
            drawing = true,
            background = {
                color = colors.transparent,
                border_color = colors.transparent,
                border_width = 0,
                corner_radius = 0
            }
        }
    })
    for _, item in ipairs(popup_items) do
        item:set({
            icon = {
                color = colors.transparent
            },
            label = {
                color = colors.transparent
            }
        })
    end

    sbar.animate("sin", 30, function()
        apple:set({
            popup = {
                background = {
                    color = colors.base,
                    border_color = colors.lavender,
                    border_width = 2,
                    corner_radius = 9
                }
            }
        })
        for _, item in ipairs(popup_items) do
            item:set({
                icon = {
                    color = colors.lavender
                },
                label = {
                    color = colors.text
                }
            })
        end
    end)
end

local function animate_close()
    is_open = false
    sbar.animate("sin", 30, function()
        apple:set({
            popup = {
                background = {
                    color = colors.transparent,
                    border_color = colors.transparent,
                    border_width = 0,
                    corner_radius = 0
                }
            }
        })
        for _, item in ipairs(popup_items) do
            item:set({
                icon = {
                    color = colors.transparent
                },
                label = {
                    color = colors.transparent
                }
            })
        end
    end)

    sbar.exec("sleep 0.5; sketchybar --trigger apple_close_complete")
end

apple:subscribe("apple_close", animate_close)
apple:subscribe("apple_close_complete", function()
    if not is_open then
        apple:set({
            popup = {
                drawing = false
            }
        })
    end
end)

apple:subscribe("mouse.clicked", function(env)
    if is_open then
        animate_close()
    else
        animate_open()
    end
end)

apple:subscribe("mouse.exited.global", function(env)
    if is_open then
        animate_close()
    end
end)
