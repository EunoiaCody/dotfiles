local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons") -- Optional, if we want app icons later

local spaces = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}

for i, name in ipairs(spaces) do
    local space = sbar.add("space", "space." .. i, {
        space = i,
        icon = {
            font = {
                family = settings.font.nerd
            },
            string = name,
            padding_left = 12,
            padding_right = 12,
            color = colors.subtext0,
            highlight_color = colors.lavender
        },
        label = {
            drawing = false
        },
        padding_left = 2,
        padding_right = 2,
        background = {
            color = colors.surface1,
            height = 26,
            drawing = false
        }
    })

    space:subscribe("space_change", function(env)
        local selected = env.SELECTED == "true"
        space:set({
            icon = {
                highlight = selected
            },
            background = {
                drawing = selected
            }
        })
    end)

    space:subscribe("mouse.clicked", function(env)
        sbar.exec("aerospace workspace " .. env.SID)
    end)
end

local spaces_bracket = sbar.add("bracket", "spaces_bracket", {"/space\\..*/"}, {
    background = {
        color = colors.surface0,
        border_color = colors.surface1,
        border_width = 2,
        corner_radius = 9
    }
    -- padding_right = 10
})
