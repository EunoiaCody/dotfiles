local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local front_app = sbar.add("item", "front_app", {
    position = "left",
    icon = {
        drawing = true,
        font = {
            family = settings.font.nerd,
            style = "Bold",
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
    local icon = app_icons[env.INFO] or app_icons["Default"]
    front_app:set({
        icon = {
            string = icon
        },
        label = {
            string = env.INFO
        }
    })
end)
