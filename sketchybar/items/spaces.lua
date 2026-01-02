local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local icon_map = require("helpers.icon_map")

-- Add event
sbar.add("event", "aerospace_workspace_change")

-- Get all workspaces from AeroSpace
local handle = io.popen("aerospace list-workspaces --all")
local result = handle:read("*a")
handle:close()

local spaces = {}
for s in result:gmatch("[^\r\n]+") do
    table.insert(spaces, s)
end

-- Function to get visible workspaces (non-empty + focused)
local function get_visible_workspaces()
    local visible = {}

    -- Get non-empty workspaces
    local handle = io.popen("aerospace list-workspaces --monitor all --empty no")
    if handle then
        for s in handle:read("*a"):gmatch("[^\r\n]+") do
            visible[s] = true
        end
        handle:close()
    end

    -- Get focused workspace
    local handle_focused = io.popen("aerospace list-workspaces --focused")
    if handle_focused then
        local focused = handle_focused:read("*a"):gsub("%s+", "")
        visible[focused] = true
        handle_focused:close()
    end

    return visible
end

-- Function to update icons for a space
local function update_space_icons(space_name)
    local handle = io.popen("aerospace list-windows --workspace " .. space_name .. " --format %{app-name}")
    local result = handle:read("*a")
    handle:close()

    local icon_line = ""
    if result ~= "" then
        for app_name in result:gmatch("[^\r\n]+") do
            local icon = icon_map[app_name] or ":default:"
            if icon_line == "" then
                icon_line = icon
            else
                icon_line = icon_line .. " " .. icon
            end
        end
    end

    if icon_line ~= "" then
        sbar.animate("tanh", 10, function()
            sbar.set("space." .. space_name, {
                label = {
                    string = icon_line,
                    drawing = true
                }
            })
        end)
    else
        sbar.set("space." .. space_name, {
            label = {
                drawing = false
            }
        })
    end
end

-- Initial visible workspaces
local visible_workspaces = get_visible_workspaces()

for i, name in ipairs(spaces) do
    local is_visible = visible_workspaces[name]

    local space = sbar.add("item", "space." .. name, {
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
            color = colors.surface1,
            height = 26,
            drawing = false
        },
        click_script = "aerospace workspace " .. name,
        drawing = is_visible
    })

    -- Initial update
    update_space_icons(name)
end

-- Central listener for workspace changes
local space_listener = sbar.add("item", "space_listener", {
    drawing = false
})

space_listener:subscribe("aerospace_workspace_change", function(env)
    local focused_workspace = env.FOCUSED_WORKSPACE
    local visible = get_visible_workspaces()

    for _, name in ipairs(spaces) do
        local is_selected = focused_workspace == name
        local is_visible = visible[name] or is_selected

        sbar.set("space." .. name, {
            icon = {
                highlight = is_selected
            },
            background = {
                drawing = is_selected
            },
            drawing = is_visible
        })

        update_space_icons(name)
    end
end)

space_listener:subscribe("front_app_switched", function(env)
    for _, name in ipairs(spaces) do
        update_space_icons(name)
    end
end)

local spaces_bracket = sbar.add("bracket", "spaces_bracket", {"/space\\..*/"}, {
    background = {
        color = colors.surface0,
        border_color = colors.surface1,
        border_width = 2,
        corner_radius = 9
    }
})
