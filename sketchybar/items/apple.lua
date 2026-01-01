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
        color = colors.surface0
    },
    -- padding_right = 10,
    padding_left = 10
})

apple:subscribe("mouse.clicked", function(env)
    -- Add popup logic here if needed, or just toggle
    -- For now, simple toggle or action
    -- sbar.exec("open -a 'System Settings'")
end)
