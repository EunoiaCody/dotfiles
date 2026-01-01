local colors = require("colors")
local settings = require("settings")

local ram = sbar.add("item", "ram", {
    position = "right",
    icon = {
        string = "󰍛",
        color = colors.lavender
    },
    label = {
        string = "0M (0%)",
        color = colors.text
    },
    background = {
        color = colors.surface0
    },
    update_freq = 5
})

ram:subscribe("routine", function(env)
    sbar.exec("vm_stat", function(vm_stat)
        local pages_active = tonumber(vm_stat:match("Pages active:%s+(%d+)"))
        local pages_wired = tonumber(vm_stat:match("Pages wired down:%s+(%d+)"))
        local pages_compressed = tonumber(vm_stat:match("Pages occupied by compressor:%s+(%d+)"))

        if pages_active and pages_wired and pages_compressed then
            local page_size = 4096
            local used_mem = (pages_active + pages_wired + pages_compressed) * page_size

            sbar.exec("sysctl -n hw.memsize", function(total_mem)
                total_mem = tonumber(total_mem)
                local percentage = math.floor(used_mem / total_mem * 100)

                local function format(bytes)
                    local gb = bytes / (1024 * 1024 * 1024)
                    return string.format("%.1fG", gb)
                end

                ram:set({
                    label = format(used_mem) .. " (" .. percentage .. "%)"
                })
            end)
        end
    end)
end)
