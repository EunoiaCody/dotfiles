local colors = require("colors")
local settings = require("settings")

local whitelist = {
    ["com.apple.Music"] = true,
    ["com.spotify.client"] = true,
    ["Music"] = true,
    ["Spotify"] = true,
    ["com.google.Chrome"] = true,
    ["com.arc.arch"] = true,
    ["com.brave.Browser"] = true,
    ["com.apple.Safari"] = true
}

local function with_alpha(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then
        return color
    end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

local media = sbar.add("item", {
    position = "center",
    background = {
        color = colors.surface0,
        border_color = colors.surface1,
        border_width = 2,
        corner_radius = 9
    },
    icon = {
        string = "",
        font = {
            family = settings.font.nerd,
            style = "Bold",
            size = 14.0
        },
        color = colors.lavender,
        padding_left = 10,
        padding_right = 10
    },
    label = {
        drawing = false
    },
    updates = true,
    update_freq = 3,
    popup = {
        align = "center",
        horizontal = true,
        background = {
            color = colors.base,
            border_color = colors.lavender,
            border_width = 2,
            corner_radius = 9
        }
    }
})

-- Popup Content

-- 1. Cover Art
local media_cover = sbar.add("item", {
    position = "popup." .. media.name,
    background = {
        image = {
            string = "/tmp/cover.jpg",
            scale = 1.0
        },
        color = colors.transparent,
        padding_left = 10,
        padding_right = 10
    },
    align = "center",
    drawing = false
})

-- 2. Title (Stacked)
local media_title = sbar.add("item", {
    position = "popup." .. media.name,
    icon = {
        drawing = false
    },
    label = {
        font = {
            family = settings.font.cjk,
            style = "Bold",
            size = 15.0
        },
        color = colors.lavender,
        max_chars = 20,
        align = "left",
        y_offset = 22
    },
    background = {
        drawing = false
    },
    width = 0, -- Overlap
    align = "left",
    drawing = false
})

-- 3. Artist (Stacked)
local media_artist = sbar.add("item", {
    position = "popup." .. media.name,
    icon = {
        drawing = false
    },
    label = {
        font = {
            family = settings.font.cjk,
            style = "Regular",
            size = 12.0
        },
        color = colors.subtext1,
        max_chars = 25,
        align = "left",
        y_offset = 0
    },
    background = {
        drawing = false
    },
    width = 0, -- Overlap
    align = "left",
    drawing = false
})

-- 3.5 Album (Stacked)
local media_album = sbar.add("item", {
    position = "popup." .. media.name,
    icon = {
        drawing = false
    },
    label = {
        font = {
            family = settings.font.cjk,
            style = "Regular",
            size = 10.0
        },
        color = colors.subtext0,
        max_chars = 25,
        align = "left",
        y_offset = -20
    },
    background = {
        drawing = false
    },
    width = 0, -- Overlap
    align = "left",
    drawing = false
})

-- 4. Spacer for Text
local media_spacer = sbar.add("item", {
    position = "popup." .. media.name,
    width = 160,
    icon = {
        drawing = false
    },
    label = {
        drawing = false
    },
    background = {
        color = colors.transparent
    },
    drawing = true
})

-- 5. Controls
local media_prev = sbar.add("item", {
    position = "popup." .. media.name,
    icon = {
        string = "",
        font = {
            family = settings.font.nerd,
            size = 14.0
        },
        color = colors.lavender
    },
    label = {
        drawing = false
    },
    click_script = "media-control previous-track",
    width = 30,
    align = "center"
})

local media_play = sbar.add("item", {
    position = "popup." .. media.name,
    icon = {
        string = "⏯",
        font = {
            family = settings.font.nerd,
            size = 14.0
        },
        color = colors.lavender
    },
    label = {
        drawing = false
    },
    click_script = "media-control toggle-play-pause",
    width = 30,
    align = "center"
})

local media_next = sbar.add("item", {
    position = "popup." .. media.name,
    icon = {
        string = "",
        font = {
            family = settings.font.nerd,
            size = 14.0
        },
        color = colors.lavender
    },
    label = {
        drawing = false
    },
    click_script = "media-control next-track",
    width = 30,
    padding_right = 10,
    align = "center"
})

local function update_media_state()
    local base_hex = string.format("%06x", colors.base & 0xffffff)
    local cmd = [[
        media-control get > /tmp/media_raw.json
        if [ -s /tmp/media_raw.json ]; then
            cat /tmp/media_raw.json | jq -r .artworkData | base64 --decode > /tmp/cover.jpg
            sips -z 100 100 /tmp/cover.jpg >/dev/null 2>&1
            sips --padToHeightWidth 116 100 --padColor ]] .. base_hex .. [[ /tmp/cover.jpg >/dev/null 2>&1
            cat /tmp/media_raw.json | jq -r '"\(.title)@@@\(.artist)@@@\(.album)@@@\(.playing)@@@\(.bundleIdentifier)"'
        else
            echo ""
        fi
    ]]

    sbar.exec(cmd, function(result)
        if not result or result == "" then
            media:set({
                drawing = false
            })
            return
        end

        local lines = {}
        for match in (result .. "@@@"):gmatch("(.-)@@@") do
            table.insert(lines, match)
        end

        if #lines < 5 then
            media:set({
                drawing = false
            })
            return
        end

        local title = lines[1]
        local artist = lines[2]
        local album = lines[3]
        local playing = lines[4]
        local app = lines[5]:gsub("\n", "")

        if whitelist[app] then
            media:set({
                drawing = true
            })

            media_title:set({
                label = title,
                drawing = true
            })
            media_artist:set({
                label = artist,
                drawing = true
            })
            media_album:set({
                label = album,
                drawing = true
            })

            media_cover:set({
                background = {
                    image = "/tmp/cover.jpg"
                },
                drawing = true
            })

            -- Ensure spacer is drawn
            media_spacer:set({
                drawing = true
            })

            if playing == "true" then
                media_play:set({
                    icon = "⏸"
                })
            else
                media_play:set({
                    icon = ""
                })
            end
        else
            media:set({
                drawing = false
            })
        end
    end)
end

media:subscribe({"routine", "forced", "media_change"}, update_media_state)

media:subscribe("mouse.clicked", function(env)
    media:set({
        popup = {
            drawing = "toggle"
        }
    })
end)

media:subscribe("mouse.exited.global", function(env)
    media:set({
        popup = {
            drawing = false
        }
    })
end)
