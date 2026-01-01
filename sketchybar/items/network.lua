local colors = require("colors")
local settings = require("settings")

local network = sbar.add("item", "network", {
    position = "right",
    icon = {
        string = "󰛳",
        color = colors.lavender
    },
    label = {
        string = "↓0K ↑0K",
        color = colors.text
    },
    background = {
        color = colors.surface0
    },
    update_freq = 2
})

local last_down = 0
local last_up = 0

network:subscribe("routine", function(env)
    sbar.exec("route get default | grep interface | awk '{print $2}'", function(iface)
        if not iface or iface == "" then
            iface = "en0"
        end
        iface = iface:gsub("%s+", "") -- trim whitespace

        sbar.exec("netstat -ibn | grep -e '^" .. iface .. "' -m 1 | awk '{print $7\" \"$10}'", function(output)
            local down, up = output:match("(%d+)%s+(%d+)")
            down = tonumber(down)
            up = tonumber(up)

            if down and up then
                local down_diff = down - last_down
                local up_diff = up - last_up

                if last_down == 0 then
                    down_diff = 0
                end
                if last_up == 0 then
                    up_diff = 0
                end

                -- Calculate speed per second (since update_freq is 2)
                local down_speed = down_diff / 2
                local up_speed = up_diff / 2

                local function format(bytes)
                    local kb = bytes / 1024
                    if kb > 1024 then
                        return string.format("%.1fM", kb / 1024)
                    else
                        return string.format("%.0fK", kb)
                    end
                end

                network:set({
                    label = "↓" .. format(down_speed) .. " ↑" .. format(up_speed)
                })

                last_down = down
                last_up = up
            end
        end)
    end)
end)
