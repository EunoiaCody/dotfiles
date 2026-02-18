`mpd` 模块显示正在运行的"Music Player Daemon"实例的信息。请注意，waybar 必须在编译时启用 mpd 支持才能使用此模块。

### 配置

通过 `mpd` 进行配置

| option                        | typeof  | default                        | description |
| ----------------------------- | ------- | ------------------------------ | ----------- |
| `server`                      | string  |                                | MPD 服务器的网络地址或 Unix 套接字路径。如果为空，则连接到默认主机（`MPD_HOST`）。 |
| `port`                        | integer |                                | MPD 监听的端口。如果为空，则使用默认端口（`MPD_PORT`）。 |
| `password`                    | string  |                                | 连接 MPD 服务器所需的密码。如果为空，则不需要密码或不向 MPD 发送密码。 |
| `interval`                    | integer | 10                             | 重试连接 MPD 服务器的时间间隔。 |
| `timeout`                     | integer | 30                             | 连接超时时间。如果您的 MPD 服务器 `connection_timeout` 设置较低，请更改此值。 |
| `unknown-tag`                 | string  | "N/A"                          | 当标签在当前歌曲中不存在但在 `format` 中使用时显示的文本。 |
| `format`                      | string  | "{album} - {artist} - {title}" | 歌曲正在播放或暂停时显示的信息。 |
| `format-stopped`              | string  | "stopped"                      | 播放器停止时显示的信息。 |
| `format-paused`               | string  |                                | 歌曲暂停时使用的格式。 |
| `format-disconnected`         | string  | "disconnected"                 | 无法连接 MPD 服务器时显示的信息。 |
| `tooltip`                     | bool    | true                           | 启用悬停时工具提示的选项。 |
| `tooltip-format`              | string  | "MPD (connected)"              | 连接到 MPD 时显示的工具提示信息。 |
| `tooltip-format-disconnected` | string  | "MPD (disconnected)"           | 无法连接 MPD 服务器时显示的工具提示信息。 |
| `artist-len` | integer |  | Artist 标签显示的最大长度。如果为空，则无限制。 |
| `album-len` | integer |  | Album 标签显示的最大长度。如果为空，则无限制。 |
| `album-artist-len` | integer |  | Album Artist 标签显示的最大长度。如果为空，则无限制。 |
| `title-len` | integer |  | Title 标签显示的最大长度。如果为空，则无限制。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `max-length`     | integer |         | 模块显示的最大字符长度。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `state-icons`                 | object  | {}                             | 根据播放器的播放/暂停状态显示的图标（`{ "playing": "...", "paused": "..." }`） |
| `consume-icons`               | object  | {}                             | 根据"consume"选项显示的图标（`{ "on": "...", "off": "..." }`） |
| `random-icons`                | object  | {}                             | 根据"random"选项显示的图标（`{ "on": "...", "off": "..." }`） |
| `repeat-icons`                | object  | {}                             | 根据"repeat"选项显示的图标（`{ "on": "...", "off": "..." }`） |
| `single-icons`                | object  | {}                             | 根据"single"选项显示的图标（`{ "on": "...", "off": "..." }`） |

### 格式替换符

#### 播放/暂停时：

| string             | replacement |
| ------------------ | ----------- |
| `{artist}`         | 当前歌曲的艺术家 |
| `{albumArtist}`    | 当前专辑的艺术家 |
| `{album}`          | 当前歌曲的专辑 |
| `{title}`          | 当前歌曲的标题 |
| `{filename}`       | 当前歌曲的文件名（含扩展名） |
| `{date}`           | 当前歌曲的日期 |
| `{volume}`         | 当前音量百分比 |
| `{elapsedTime}`    | 当前歌曲的播放位置。格式化为日期/时间（参见示例配置） |
| `{totalTime}`      | 当前歌曲的总时长。格式化为日期/时间（参见示例配置） |
| `{songPosition}`   | 歌曲在当前队列中的位置。 |
| `{queueLength}`    | 当前队列的长度。 |
| `{stateIcon}`      | 对应播放器播放或暂停状态的图标（参见 `state-icons` 选项） |
| `{consumeIcon}`    | 对应"consume"选项的图标（参见 `consume-icons` 选项） |
| `{randomIcon}`     | 对应"random"选项的图标（参见 `random-icons` 选项） |
| `{repeatIcon}`     | 对应"repeat"选项的图标（参见 `repeat-icons` 选项） |
| `{singleIcon}`     | 对应"single"选项的图标（参见 `single-icons` 选项） |

#### 停止时：

| string             | replacement |
| ------------------ | ----------- |
| `{consumeIcon}`    | 对应"consume"选项的图标（参见 `consume-icons` 选项） |
| `{randomIcon}`     | 对应"random"选项的图标（参见 `random-icons` 选项） |
| `{repeatIcon}`     | 对应"repeat"选项的图标（参见 `repeat-icons` 选项） |
| `{singleIcon}`     | 对应"single"选项的图标（参见 `single-icons` 选项） |


#### 断开连接时：

目前断开连接时没有格式替换符。

### 示例

```jsonc
"mpd": {
    "format": "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ",
    "format-disconnected": "Disconnected ",
    "format-stopped": "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ",
    "interval": 10,
    "consume-icons": {
        "on": " " // Icon shows only when "consume" is on
    },
    "random-icons": {
        "off": "<span color=\"#f53c3c\"></span> ", // Icon grayed out when "random" is off
        "on": " "
    },
    "repeat-icons": {
        "on": " "
    },
    "single-icons": {
        "on": "1 "
    },
    "state-icons": {
        "paused": "",
        "playing": ""
    },
    "tooltip-format": "MPD (connected)",
    "tooltip-format-disconnected": "MPD (disconnected)"
}
```

### 样式

- `#mpd`
- `#mpd.disconnected`
- `#mpd.stopped`
- `#mpd.playing`
- `#mpd.paused`
