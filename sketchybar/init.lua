colors = require("colors")
settings = require("settings")

sbar = require("sketchybar")
sbar.begin_config()

-- Bar Appearance
sbar.bar({
    position = "top",
    height = 40,
    blur_radius = 30,
    color = colors.base,
    margin = 10,
    y_offset = 10,
    corner_radius = 12,
    padding_left = 10,
    padding_right = 10,
    notch_width = 200,
    display = "main",
    shadow = true
})

-- Default Item Settings
sbar.default({
    padding_left = 5,
    padding_right = 5,
    icon = {
        font = {
            family = settings.font.nerd,
            style = "Bold",
            size = 17.0
        },
        color = colors.text,
        padding_left = 10,
        padding_right = 5
    },
    label = {
        font = {
            family = settings.font.nerd,
            style = "Bold",
            size = 14.0
        },
        color = colors.text,
        padding_left = 5,
        padding_right = 10
    },
    background = {
        color = colors.surface0,
        corner_radius = 9,
        height = 28,
        border_width = 3,
        border_color = colors.lavender
    },
    y_offset = 0
})

require("items.init")

sbar.end_config()

sbar.event_loop()
