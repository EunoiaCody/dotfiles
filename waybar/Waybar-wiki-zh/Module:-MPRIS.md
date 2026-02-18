`mpris` 模块通过 `libplayerctl` 显示当前正在播放的媒体。

### 配置

| option                        | typeof  | default                        | description |
| ----------------------------- | ------- | ------------------------------ | ----------- |
| `player` | string | playerctld | 要连接的 MPRIS 播放器名称。使用默认值时始终跟随当前活动的播放器。 |
| `ignored-players` | array[string] | | 使用 playerctld 时，忽略列出的播放器的更新。 |
| `interval` | integer | | 定时刷新 MPRIS 信息。
| `format` | string | `{player} ({status}) {dynamic}` | 文本格式。
| `format-[status]` | string | | 特定状态的文本格式。
| `tooltip-format` | string | | 默认工具提示的格式。
| `tooltip-format-[status]` | string | | 当 `[status]` 为 `playing`、`paused` 或 `stopped` 之一时的工具提示格式。
| `enable-tooltip-len-limits` | bool | `false` | 需要设置为 true 才能使 {dynamic} 和小时截断在工具提示中生效。 |
| `on-click` | string | play-pause | 覆盖默认的操作切换。
| `on-click-middle` | string | previous track | 覆盖默认的操作切换。
| `on-click-right` | string | next track | 覆盖默认的操作切换。
| `player-icons` | map[string]string | | 允许根据 player-name 属性设置 `{player-icon}`。
| `status-icons` | map[string]string | | 允许根据播放器状态（`playing`、`paused`、`stopped`）设置 `{status-icon}`。
| `dynamic-order` | list[string] | `["title", "artist", "album", "position", "length"]` | 选择 `{dynamic}` 中项目的顺序，以 `{dynamic-separator}` 分隔。如果 `position` 和 `length` 同时存在且相邻（按顺序），它们将以 `<small>[{position}/{length}]</small>` 的格式显示。
| `[format]-len` | integer | `-1` | 其中 `[format]` 是格式段的名称，这是该替换允许的最大长度。如果替换的长度大于此值，将被截断并在末尾添加 `ellipsis` 字符/字符串。
| `ellipsis` | string/char | `…` | 追加到截断格式替换末尾的字符。
| `dynamic-len` | integer | `-1` | 如果 `{dynamic}` 的总长度大于此值，将根据 `dynamic-importance-order` 开始移除段，以使字符串适合此定义的限制。
| `dynamic-separator` | string | `  -  ` | `dynamic-order` 各段之间使用的分隔符。
| `dynamic-importance-order` | list[string] | `["title", "artist", "album", "position", "length"]` | 选择当字符串超过 `dynamic-len` 时要省略的格式替换符。排在前面的格式替换符名称优先级更高，排在后面的最有可能被移除。
| `rotate` | integer | | 正值用于旋转文本标签。 |

### 格式替换符

#### 播放/暂停时：

| string             | replacement |
| ------------------ | ----------- |
| `{player}` | 当前媒体播放器的名称 |
| `{status}` | 当前状态（`playing`、`paused`、`stopped`） |
| `{artist}` | 当前曲目的艺术家 |
| `{album}` | 当前曲目的专辑标题 |
| `{title}` | 当前曲目的标题 |
| `{length}` | 曲目长度，格式为 HH:MM:SS |
| `{position}` | 曲目中的当前播放位置，格式为 HH:MM:SS |
| `{dynamic}` | 使用 `{artist}`、`{album}`、`{title}` 和 `{length}`，自动省略空值 |
| `{player_icon}` | 根据 `{player}` 从 `player-icons` 中选择图标 |
| `{status_icon}` | 根据 `{status}` 从 `status-icons` 中选择图标 |

### 示例

```jsonc
"mpris": {
	"format": "DEFAULT: {player_icon} {dynamic}",
	"format-paused": "DEFAULT: {status_icon} <i>{dynamic}</i>",
	"player-icons": {
		"default": "▶",
		"mpv": "🎵"
	},
	"status-icons": {
		"paused": "⏸"
	},
	// "ignored-players": ["firefox"]
}
```

### 样式

- `#mpris`
- `#mpris.${status}`
- `#mpris.${player}`
