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
    associated_display = "active"
})

front_app:subscribe("front_app_switched", function(env)
    local icon = icon_map[env.INFO] or ":default:"
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
