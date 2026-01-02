local colors = require("colors")
local settings = require("settings")

local volume = sbar.add("item", "volume", {
    position = "right",
    icon = {
        string = "󰕾",
        color = colors.lavender
    },
    label = {
        color = colors.text
    },
    background = {
        color = colors.surface0
    }
})

local function update_volume(env)
    local vol = tonumber(env.INFO)
    local icon = "󰕾"
    if vol == 0 then
        icon = "󰖁"
    elseif vol < 30 then
        icon = "󰕿"
    elseif vol < 60 then
        icon = "󰖀"
    end

    sbar.animate("sin", 30, function()
        volume:set({
            icon = icon,
            label = vol .. "%"
        })
    end)
end

volume:subscribe("volume_change", update_volume)

volume:subscribe("mouse.scrolled", function(env)
    local delta = env.SCROLL_DELTA
    sbar.exec("osascript -e 'set volume output volume (output volume of (get volume settings) + " .. delta .. ")'")
end)
