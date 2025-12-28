function fish_greeting
    # 根据时间确定问候语
    set -l hour (date +%H)
    set -l greeting "Good morning"

    if test $hour -ge 12 -a $hour -lt 18
        set greeting "Good afternoon"
    else if test $hour -ge 18
        set greeting "Good evening"
    end

    # 双色渐变显示
    set_color cba6f7 # Catppuccin Mocha Mauve
    echo -n "$greeting, "
    set_color b4befe # Catppuccin Mocha Lavender
    echo -n "welcome back, "
    set_color cba6f7 # 回到 Mauve
    echo -n "⟡ "
    set_color b4befe # Lavender
    echo eunoia
    set_color normal
end
