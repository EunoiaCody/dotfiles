local colors = require("colors")
local settings = require("settings")

local clock = sbar.add("item", "clock", {
    position = "right",
    icon = {
        string = "",
        color = colors.lavender
    },
    label = {
        color = colors.text
    },
    background = {
        color = colors.surface0
    },
    update_freq = 10
})

clock:subscribe("routine", function(env)
    clock:set({
        label = os.date("%H:%M")
    })
end)
