local colors = require("colors")
local settings = require("settings")
local icon_map = require("helpers.icon_map")

local front_app = sbar.add("item", "front_app", {
    position = "left",
    icon = {
        drawing = true,
        font = {
            family = "sketchybar-app-font",
            style = "Regular",
            size = 16.0
        },
        color = colors.lavender
    },
    label = {
        font = {
            family = settings.font.text,
            style = "Black",
            size = 12.0
        },
        color = colors.text
    },
    background = {
        drawing = true
    },
    associated_display = "active",
    popup = {
        align = "left",
        background = {
            color = colors.base,
            border_color = colors.lavender,
            border_width = 3,
            corner_radius = 9
        }
    }
})

local popup_items = {}

local function create_popup_item(icon, label, script)
    local item = sbar.add("item", {
        position = "popup." .. front_app.name,
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
        click_script = script .. "; sketchybar --trigger front_app_close",
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

sbar.add("event", "front_app_close")
sbar.add("event", "front_app_close_complete")

local quit_item = create_popup_item("", "退出应用", "")

local is_open = false

local function animate_open()
    is_open = true
    front_app:set({
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
        front_app:set({
            popup = {
                background = {
                    color = colors.base,
                    border_color = colors.lavender,
                    border_width = 3,
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
        front_app:set({
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

    sbar.exec("sleep 0.5; sketchybar --trigger front_app_close_complete")
end

front_app:subscribe("front_app_close", animate_close)
front_app:subscribe("front_app_close_complete", function()
    if not is_open then
        front_app:set({
            popup = {
                drawing = false
            }
        })
    end
end)

front_app:subscribe("mouse.clicked", function(env)
    if is_open then
        animate_close()
    else
        animate_open()
    end
end)

front_app:subscribe("mouse.exited.global", function(env)
    if is_open then
        animate_close()
    end
end)

front_app:subscribe("front_app_switched", function(env)
    local icon = icon_map[env.INFO] or ":default:"

    quit_item:set({
        click_script = "osascript -e 'quit app \"" .. env.INFO .. "\"' ; sketchybar --trigger front_app_close"
    })

    sbar.animate("sin", 30, function()
        front_app:set({
            icon = {
                string = icon
            },
            label = {
                string = env.INFO
            }
        })
    end)
end)
