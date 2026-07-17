local colors = require("colors")
local settings = require("settings")
local icon_map = require("helpers.icon_map")
local sbar = require("sketchybar")

-- Add event
sbar.add("event", "aerospace_workspace_change")

local current_icons = {}

local function update_windows(spaces)
    sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}'", function(windows_result)
        if not windows_result then
            return
        end

        local workspace_apps = {}
        for line in windows_result:gmatch("[^\r\n]+") do
            local workspace, app = line:match("^(.-)|(.*)$")
            if workspace and app then
                if not workspace_apps[workspace] then
                    workspace_apps[workspace] = {}
                end
                table.insert(workspace_apps[workspace], app)
            end
        end

        for _, name in ipairs(spaces) do
            local apps = workspace_apps[name]
            local icon_line = ""
            if apps then
                for _, app_name in ipairs(apps) do
                    local icon = icon_map[app_name] or ":default:"
                    if icon_line == "" then
                        icon_line = icon
                    else
                        icon_line = icon_line .. " " .. icon
                    end
                end
            end

            if icon_line ~= (current_icons[name] or "") then
                current_icons[name] = icon_line
                sbar.animate("sin", 30, function()
                    sbar.set("space." .. name, {
                        label = {
                            string = icon_line,
                            drawing = (icon_line ~= "")
                        }
                    })
                end)
            end
        end
    end)
end

local function update_visibility(spaces, focused_workspace)
    sbar.exec("aerospace list-workspaces --monitor all --empty no", function(empty_result)
        local visible = {}
        for s in empty_result:gmatch("[^\r\n]+") do
            visible[s] = true
        end
        if focused_workspace then
            visible[focused_workspace] = true
        end

        for _, name in ipairs(spaces) do
            local is_selected = focused_workspace == name
            local is_visible = visible[name] or is_selected

            sbar.animate("sin", 30, function()
                sbar.set("space." .. name, {
                    icon = {
                        color = is_selected and colors.lavender or colors.subtext0
                    },
                    background = {
                        color = is_selected and colors.surface1 or colors.transparent
                    },
                    drawing = is_visible
                })
            end)
        end
    end)
end

-- Initial setup
sbar.exec("aerospace list-workspaces --all", function(result)
    local spaces = {}
    for s in result:gmatch("[^\r\n]+") do
        table.insert(spaces, s)
    end

    for i, name in ipairs(spaces) do
        sbar.add("item", "space." .. name, {
            icon = {
                font = {
                    family = settings.font.nerd
                },
                string = name,
                padding_left = 12,
                padding_right = 12
            },
            label = {
                drawing = false,
                font = {
                    family = "sketchybar-app-font",
                    style = "Regular",
                    size = 16.0
                },
                color = colors.text,
                y_offset = -1,
                padding_right = 12
            },
            padding_left = 2,
            padding_right = 2,
            background = {
                color = colors.transparent,
                height = 26,
                drawing = true
            },
            click_script = "aerospace workspace " .. name,
            drawing = false -- Default to hidden until update_visibility runs
        })
    end

    local spaces_bracket = sbar.add("bracket", "spaces_bracket", {"/space\\..*/"}, {
        background = {
            color = colors.surface0,
            border_color = colors.surface1,
            border_width = 2,
            corner_radius = 9
        }
    })

    local space_listener = sbar.add("item", "space_listener", {
        drawing = false
    })

    space_listener:subscribe("aerospace_workspace_change", function(env)
        local focused_workspace = env.FOCUSED_WORKSPACE
        update_visibility(spaces, focused_workspace)
        update_windows(spaces)
    end)

    space_listener:subscribe("front_app_switched", function(env)
        update_windows(spaces)
    end)

    -- Initial update
    sbar.exec("aerospace list-workspaces --focused", function(focused)
        local focused_name = focused:gsub("%s+", "")
        update_visibility(spaces, focused_name)
        update_windows(spaces)
    end)
end)
