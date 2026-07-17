local colors = require("colors")
local settings = require("settings")

local clock = sbar.add("item", "clock", {
    position = "center",
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
    sbar.animate("sin", 30, function()
        clock:set({
            label = os.date("%Y.%m.%d %H:%M")
        })
    end)
end)
