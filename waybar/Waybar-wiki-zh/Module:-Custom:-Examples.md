本页包含自定义模块的简要示例，代码直接在此提供：
#### CPU 历史记录：
显示如下 CPU 图表：
<img width="227" height="17" alt="2025-07-23-172546_hyprshot" src="https://github.com/user-attachments/assets/e6b6cd88-5f83-45d7-b559-a285155bd291" />

完整使用示例在我的 dotfiles 中：https://github.com/cargodog/dot-config/tree/master/waybar
`~/.config/waybar/config`
```jsonc
"custom/cpuhistory": {
  "exec": "~/.config/waybar/scripts/cpu_history.py -d 60",
  "format": "<span color='#FFA500'>  </span>{}",
  "interval": 1,
  "return-type": "json",
  "on-click": "~/.config/waybar/scripts/cpu_history.py toggle"
},
```
* 需要 python 3 和 python psutil 包
* 设置 `-d` 来指定图表中的柱状条数
  * 例如，设置 `"interval": 1` 和 `-d 60` 意味着图表将显示最近 60 秒的 CPU 使用率
* `on-click` 操作在图表视图和单次测量之间切换

`~/.config/waybar/config/scripts/cpu_history.py`
```python
#!/usr/bin/env python3
"""CPU Usage Graph Monitor - Displays a unicode graph of CPU usage history using Braille characters."""
import json
import os
import sys
import psutil
import argparse
from pathlib import Path

# Configuration
CACHE_DIR = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache'))
HISTORY_FILE = CACHE_DIR / 'cpu_usage_history.json'
DEFAULT_HISTORY_DEPTH = 40

# Braille patterns for vertical bar graphs
BRAILLE_PATTERNS = {
    (0, 0): '⠀', (1, 0): '⡀', (2, 0): '⡄', (3, 0): '⡆', (4, 0): '⡇',
    (0, 1): '⢀', (1, 1): '⣀', (2, 1): '⣄', (3, 1): '⣆', (4, 1): '⣇',
    (0, 2): '⢠', (1, 2): '⣠', (2, 2): '⣤', (3, 2): '⣦', (4, 2): '⣧',
    (0, 3): '⢰', (1, 3): '⣰', (2, 3): '⣴', (3, 3): '⣶', (4, 3): '⣷',
    (0, 4): '⢸', (1, 4): '⣸', (2, 4): '⣼', (3, 4): '⣾', (4, 4): '⣿',
}

def get_braille_char(left_val, right_val):
    """Convert two percentage values (0-100) to a single Braille character."""
    # Convert percentages to levels (1-4), minimum 1 to always show at least one dot
    left_level = max(1, min(int(left_val * 4 / 100), 4))
    right_level = max(1, min(int(right_val * 4 / 100), 4))
    return BRAILLE_PATTERNS.get((left_level, right_level), '⣀')

def load_data():
    """Load data from cache file."""
    try:
        with open(HISTORY_FILE, 'r') as f:
            data = json.load(f)
            # Handle legacy format
            if isinstance(data, list):
                return {"history": data, "show_graph": True}
            return data
    except (FileNotFoundError, json.JSONDecodeError):
        return {"history": [], "show_graph": True}

def save_data(data):
    """Save data to cache file."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(HISTORY_FILE, 'w') as f:
        json.dump(data, f)

def main():
    parser = argparse.ArgumentParser(description='CPU Usage Graph Monitor with Braille display')
    parser.add_argument('command', nargs='?', help='Command: toggle')
    parser.add_argument('-d', '--depth', type=int, default=DEFAULT_HISTORY_DEPTH,
                        help=f'History depth (default: {DEFAULT_HISTORY_DEPTH})')
    args = parser.parse_args()
    
    # Ensure even depth for Braille pairs
    history_depth = args.depth + (args.depth % 2)
    
    data = load_data()
    
    # Handle toggle command
    if args.command == "toggle":
        data["show_graph"] = not data.get("show_graph", True)
        save_data(data)
        return
    
    # Get CPU usage
    per_core = psutil.cpu_percent(interval=0.1, percpu=True)
    current_usage = sum(per_core) / len(per_core)
    
    # Update history
    history = data["history"]
    history.append(current_usage)
    
    # Keep only needed history
    if len(history) > history_depth:
        history = history[-history_depth:]
    
    # Generate output
    if data.get("show_graph", True):
        # Pad with zeros if needed
        padded = [0.0] * (history_depth - len(history)) + history
        
        # Build graph
        graph = ''.join(
            get_braille_char(
                padded[i],
                padded[i + 1] if i + 1 < history_depth else 0.0
            )
            for i in range(0, history_depth, 2)
        )
        text = f"[{graph}]"
    else:
        text = f"{current_usage:.1f}%"
    
    # Save and output
    data["history"] = history
    save_data(data)
    
    # Build color-coded tooltip
    tooltip_lines = []
    for i, usage in enumerate(per_core):
        if usage >= 80:
            color = "#ff6b6b"  # Red for high load
        elif usage >= 60:
            color = "#feca57"  # Yellow for medium-high load
        elif usage >= 40:
            color = "#48dbfb"  # Cyan for medium load
        else:
            color = "#1dd1a1"  # Green for low load
        
        tooltip_lines.append(f'<span color="{color}">Core {i}: {usage:5.1f}%</span>')
    
    # Output for waybar
    print(json.dumps({
        "text": text,
        "tooltip": '\n'.join(tooltip_lines),
        "class": "cpu-history"
    }))

if __name__ == "__main__":
    main()
```

#### dunst：
`~/.config/waybar/config`
```jsonc
"custom/dunst": {
    "exec": "~/.config/waybar/scripts/dunst.sh",
    "on-click": "dunstctl set-paused toggle",
    "restart-interval": 1,
}
```
`~/.config/waybar/scripts/dunst.sh`
```bash
#!/usr/bin/env bash

COUNT=$(dunstctl count waiting)
ENABLED=
DISABLED=
if [ $COUNT != 0 ]; then DISABLED=" $COUNT"; fi
if dunstctl is-paused | grep -q "false" ; then echo $ENABLED; else echo $DISABLED; fi
```

或者如果您想要一个响应 dbus 事件的版本：

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly ENABLED=' '
readonly DISABLED=' '
dbus-monitor path='/org/freedesktop/Notifications',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged' --profile |
  while read -r _; do
    PAUSED="$(dunstctl is-paused)"
    if [ "$PAUSED" == 'false' ]; then
      CLASS="enabled"
      TEXT="$ENABLED"
    else
      CLASS="disabled"
      TEXT="$DISABLED"
      COUNT="$(dunstctl count waiting)"
      if [ "$COUNT" != '0' ]; then
        TEXT="$DISABLED ($COUNT)"
      fi
    fi
    printf '{"text": "%s", "class": "%s"}\n' "$TEXT" "$CLASS"
  done
```

#### NVIDIA GPU（使用 nvidia-smi）
```jsonc
"custom/nvidia": {
    "exec": "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,nounits,noheader | sed 's/\\([0-9]\\+\\), \\([0-9]\\+\\)/\\1% 🌡️\\2°C/g'",
    "format": "{} 🖥️",
    "interval": 2
}

```

#### 通用媒体播放器：
支持 vlc、mpv、RhythmBox、网页浏览器、cmus、mpd、spotify 等。
```jsonc
"custom/media": {
    "format": "{icon} {}",
    "escape": true,
    "return-type": "json",
    "max-length": 40,
    "on-click": "playerctl play-pause",
    "on-click-right": "playerctl stop",
    "smooth-scrolling-threshold": 10, // This value was tested using a trackpad, it should be lowered if using a mouse.
    "on-scroll-up": "playerctl next",
    "on-scroll-down": "playerctl previous",
    "exec": "$HOME/.config/waybar/mediaplayer.py 2> /dev/null", // Script in resources/custom_modules folder
}
```

#### Spotify：
```jsonc
"custom/spotify": {
    "format": "{icon} {}",
    "escape": true,
    "return-type": "json",
    "max-length": 40,
    "interval": 30, // Remove this if your script is endless and write in loop
    "on-click": "playerctl -p spotify play-pause",
    "on-click-right": "killall spotify",
    "smooth-scrolling-threshold": 10, // This value was tested using a trackpad, it should be lowered if using a mouse.
    "on-scroll-up" : "playerctl -p spotify next",
    "on-scroll-down" : "playerctl -p spotify previous",
    "exec": "$HOME/.config/waybar/mediaplayer.py 2> /dev/null", // Script in resources/custom_modules folder
    "exec-if": "pgrep spotify"
}
```
#### mpd：

```jsonc
"custom/mpd": {
    "format": "♪ {}",
    //"max-length": 15,
    "interval": 10, 
    "exec": "mpc current", 
    "exec-if": "pgrep mpd",
    "on-click": "mpc toggle",
    "on-click-right": "sonata"
}   
```
#### cmus：
```jsonc
"custom/cmus": {
    "format": "♪ {}",
    //"max-length": 15,
    "interval": 10,
    "exec": "cmus-remote -C \"format_print '%a - %t'\"", // artist - title
    "exec-if": "pgrep cmus",
    "on-click": "cmus-remote -u",                        //toggle pause
    "escape": true                                       //handle markup entities
}
```
#### MPRIS 控制器
```jsonc
"custom/media": {
    "format": "{icon}{}",
    "return-type": "json",
    "format-icons": {
        "Playing": " ",
        "Paused": " ",
    },
    "max-length":70,
    "exec": "playerctl -a metadata --format '{\"text\": \"{{playerName}}: {{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F",
    "on-click": "playerctl play-pause",
}
```

#### Pipewire：
使用 Wireplumber

`~/.config/waybar/config`
```jsonc
"custom/pipewire": {
    "tooltip": false,
    "max-length": 6,
    "exec": "$HOME/.config/waybar/scripts/pipewire.sh",
    "on-click": "pavucontrol",
    "on-click-right": "qpwgraph"
}
```

`~/.config/waybar/scripts/pipewire.sh`

```bash

#!/bin/bash

set -e

# https://blog.dhampir.no/content/sleeping-without-a-subprocess-in-bash-and-how-to-sleep-forever
snore() {
    local IFS
    [[ -n "${_snore_fd:-}" ]] || exec {_snore_fd}<> <(:)
    read -r ${1:+-t "$1"} -u $_snore_fd || :
}

DELAY=0.2

while snore $DELAY; do
    WP_OUTPUT=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)

    if [[ $WP_OUTPUT =~ ^Volume:[[:blank:]]([0-9]+)\.([0-9]{2})([[:blank:]].MUTED.)?$ ]]; then
        if [[ -n ${BASH_REMATCH[3]} ]]; then
            printf "MUTE\n"
        else
            VOLUME=$((10#${BASH_REMATCH[1]}${BASH_REMATCH[2]}))
            ICON=(
                ""
                ""
                ""
            )

            if [[ $VOLUME -gt 50 ]]; then
                printf "%s" "${ICON[0]} "
            elif [[ $VOLUME -gt 25 ]]; then
                printf "%s" "${ICON[1]} "
            elif [[ $VOLUME -ge 0 ]]; then
                printf "%s" "${ICON[2]} "
            fi

            printf "$VOLUME%%\n"
        fi
    fi
done

exit 0
```

#### Pacman
```jsonc
"custom/pacman": {
    "format": "{}  ",
    "interval": "once",
    "exec": "pacman_packages",
    "on-click": "update-system",
    "signal": 8
}
//alternate
"custom/pacman": {
    "format": "{}  ",
    "interval": 3600,                     // every hour
    "exec": "checkupdates | wc -l",       // # of updates
    "exec-if": "exit 0",                  // always run; consider advanced run conditions
    "on-click": "termite -e 'sudo pacman -Syu'; pkill -SIGRTMIN+8 waybar", // update system
    "signal": 8
}
```
您可以使用信号并通过 `pkill -RTMIN+8 waybar` 更新可用软件包数量。

#### XBPS

显示 Void Linux 的可用更新。

`~/.config/waybar/config`

```jsonc
  "custom/xbps": {
    "format": "{}  ",
    "return-type": "json",
    "tooltip": true,
    "interval": "3600",
    "exec": "~/.config/waybar/custom/xbps-updates.sh"
  },
```

`~/.config/waybar/custom/xbps-updates.sh`

```bash
#!/bin/bash

pkgs=$(xbps-install -nuM | awk '{print $1}')
pkg_count=$(echo $pkgs | wc -w)
pkg_list=$(echo $pkgs | sed 's/ /\\r/g')

echo "{\"text\":\"$pkg_count\", \"tooltip\":\"$pkg_list\"}"
```


#### DeaDBeeF

```jsonc
"custom/deadbeef": {
    "format": " {}",
    "max-length": 50,    
    "interval": 10,
    "exec": "deadbeef --nowplaying-tf '{\"text\": \"%title%\", \"tooltip\":\"%artist% - %title%\",\"class\":\"$if(%isplaying%,playing,not-playing)\"}'",
    "return-type": "json",
    "exec-if": "pgrep deadbeef",
    "on-click": "deadbeef --toggle-pause"
}
```


#### VPN 指示器

（这个指示器比较简单，只检查隧道是否存在）

```jsonc
"custom/vpn": {
    "format": "VPN ",
    "exec": "echo '{\"class\": \"connected\"}'",
    "exec-if": "test -d /proc/sys/net/ipv4/conf/tun0",
    "return-type": "json",
    "interval": 5
}
```

#### Github 通知

```jsonc
"custom/github": {
    "format": "{} ",
    "return-type": "json",
    "interval": 60,
    "exec": "$HOME/.config/waybar/github.sh",
    "on-click": "xdg-open https://github.com/notifications"
}
```
1. 确保已安装 [`jq`](https://stedolan.github.io/jq/)。
2. 在 https://github.com/settings/tokens 创建 `notifications.token` 个人访问令牌，范围需包含 `notifications`。
3. 使用以下内容创建 `github.sh`，将 `username` 替换为您自己的用户名。

```bash
#!/bin/bash

token=`cat ${HOME}/.config/github/notifications.token`
count=`curl -u username:${token} https://api.github.com/notifications | jq '. | length'`

if [[ "$count" != "0" ]]; then
    echo '{"text":'$count',"tooltip":"$tooltip","class":"$class"}'
fi
```

#### 天气

将 `Berlin+Germany` 替换为您自己的城市。

`~/.config/waybar/config`

```jsonc
"custom/weather": {
    "exec": "${HOME}/.config/waybar/scripts/get_weather.sh Berlin+Germany",
    "return-type": "json",
    "format": "{}",
    "tooltip": true,
    "interval": 3600
}
```

`~/.config/waybar/scripts/get_weather.sh`

```bash
#!/usr/bin/env bash
for i in {1..5}
do
    text=$(curl -s "https://wttr.in/$1?format=1")
    if [[ $? == 0 ]]
    then
        text=$(echo "$text" | sed -E "s/\s+/ /g")
        tooltip=$(curl -s "https://wttr.in/$1?format=4")
        if [[ $? == 0 ]]
        then
            tooltip=$(echo "$tooltip" | sed -E "s/\s+/ /g")
            echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
            exit
        fi
    fi
    sleep 2
done
echo "{\"text\":\"error\", \"tooltip\":\"error\"}"
```

#### Sway 暂存区指示器：

需要 [`jq`](https://stedolan.github.io/jq/)

获取所有暂存区节点。将计数显示为模块文本，悬停时显示窗口 class/app_id、id 和名称，如果暂存区中没有节点则不显示任何内容。

```jsonc
"custom/scratchpad-indicator": {
    "interval": 3,
    "return-type": "json",
    "exec": "swaymsg -t get_tree | jq --unbuffered --compact-output '(recurse(.nodes[]) | select(.name == \"__i3_scratch\") | .focus) as $scratch_ids | [..  | (.nodes? + .floating_nodes?) // empty | .[] | select(.id |IN($scratch_ids[]))] as $scratch_nodes | if ($scratch_nodes|length) > 0 then { text: \"\\($scratch_nodes | length)\", tooltip: $scratch_nodes | map(\"\\(.app_id // .window_properties.class) (\\(.id)): \\(.name)\") | join(\"\\n\") } else empty end'",
    "format": "{} 🗗",
    "on-click": "exec swaymsg 'scratchpad show'",
    "on-click-right": "exec swaymsg 'move scratchpad'"
}
```
更简单的版本，仅在至少有一个窗口时显示窗口数量（0 个时隐藏）。悬停时不显示额外信息。
```jsonc
"custom/scratchpad_indicator": {
   "interval": 3,
   "exec": "swaymsg -t get_tree | jq 'recurse(.nodes[]) | first(select(.name==\"__i3_scratch\")) | .floating_nodes | length | select(. >= 1)'",
   "format": "{} ",
   "on-click": "swaymsg 'scratchpad show'",
   "on-click-right": "swaymsg 'move scratchpad'"
}
```

#### Sway 输出缩放切换

```jsonc
"custom/output-scale": {
    "format": "{icon} {}",
    "return-type": "json",
    "format-icons": { // These are FontAwesome 4 icons. Update them as needed.
        "scale": " \uf0b2",
        "noscale": "\uf066"
    },
    "exec-on-event": true,
    "interval": "once",
    "exec": "( swaymsg -r -t get_outputs | jq '.[0].scale' | xargs test 1 == ) && echo '{\"alt\": \"noscale\"}' || echo '{\"alt\":\"scale\"}'",
    "exec-if": "sleep 0.1", // Give enough time for `sway output` command changes to propagate so we can read them in the next `exec`
    "on-click": "( swaymsg -r -t get_outputs | jq '.[0].scale' | xargs test 1 = ) && swaymsg output DP-1 scale 1.4 || swaymsg output DP-1 scale 1"
}
```

1. 在 `on-click` 配置中更改所需的缩放参数。
2. 将 `DP-1` 更新为您的实际输出。
3. 如果您有多个输出，且需要调整非零输出，请更改 `exec` 和 `on-click` 中的索引 `[0]`。

#### 显示当前 Pulseaudio 输出设备并点击切换设备

```jsonc
"custom/pulseaudio-cycle": {
    "return-type": "json",
    "exec-on-event": true,
    "interval": "5s",
    "exec" "pactl --format=json list sinks | jq -cM --unbuffered \"map(select(.name == \\\"$(pactl get-default-sink)\\\"))[0].properties | [.\\\"media.name\\\",.\\\"alsa.name\\\",.\\\"node.nick\\\",.\\\"alsa.long_card_name\\\"] | map(select(length>0))[0] | {text:.}\"",
    "exec-if": "sleep 0.1", // Give enough time for `pactl get-default-sink` to update
    "on-click": "pactl --format=json list sinks short | jq -cM --unbuffered \"[.[].name] | .[((index(\\\"$(pactl get-default-sink)\\\")+1)%length)]\" | xargs pactl set-default-sink"
}
```

#### 集成 CalDAV 的日历

需要 [plann](https://github.com/tobixen/plann)

```
#!/usr/bin/env bash

PLANN=$HOME/.pyenv/versions/plann/bin/plann

printf '{"text":"'
printf "󰸘 $(date +'%m-%d (%a)') "
printf "󰅐 $(date +'%H:%M')"
printf '",'
printf '"tooltip":"%s"' "$($PLANN --caldav-url CALDAV_URL --caldav-username CALDAV_USER --caldav-password CALDAV_PASSWORD --calendar-name 'CALDAV_CALENDAR_NAME' agenda | head --lines -1 | sed 's/$/\\n/' | tr -d '\n' | head --bytes -2)"
printf '}'
```

移除 `--calendar-name` 选项可显示所有日历中的最近事件。


#### 通过 Zigbee2MQTT 在 Tuya 智能电源插座上测量功耗（例如电脑的功耗）

需要 [mosquitto](https://github.com/eclipse/mosquitto) 和 [jq](https://github.com/jqlang/jq)
```
"custom/tuya": {
    "format": "{}w",
    "exec": "mosquitto_sub -h YOUR_HOST -t 'zigbee2mqtt/YOUR_SMART_DEV' | jq '.power' --unbuffered",
    "exec-if": "exit 0",
    "restart-interval": 60,
    "escape": true,
}
```
#### 适用于 sway 的简单 VRR/自适应同步切换
```
"custom/adaptive-sync" : {
  "format": "  VRR{} ",
  "exec-on-event": true,
  "interval": "once",
  "exec": "swaymsg -r -t get_outputs | jq '.[0].adaptive_sync_status'",
  "on-click": "swaymsg output DP-2 adaptive_sync on",
  "on-click-right": "swaymsg output DP-2 adaptive_sync off"
}
```
