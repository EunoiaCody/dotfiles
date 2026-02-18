`wireplumber` 模块显示 WirePlumber 报告的当前音量。

此外，当光标悬停在模块上时，您可以通过*上*或*下*滚动来控制音量。

### 配置

| option | typeof | default | description |
| ------------------ | ------- | ----------- | ----------- |
| `format`           | string  | `{volume}%` | 信息的显示格式。<br>当未指定其他格式时使用此格式。 |
| `format-muted`     | string  |             | 静音时使用的格式。 |
| `format-source`    | string  | `{volume}%` | 用于音频源的格式。 |
| `format-source-muted` | string |           | 音频源静音时使用的格式。 |
| `format-icons`     | array   |             | 根据当前音量选择相应的图标。<br>顺序为*低*到*高*。 |
| `rotate`		   | integer | 				| 旋转文本标签的正值。 |
| `states`         | array   |               | 在特定音量级别激活的多个音量状态。<br>参见 [States](https://github.com/Alexays/Waybar/wiki/States) |
| `max-length`       | integer |             | 模块应显示的最大字符长度。 |
| `scroll-step`      | float | 1.0           | 滚动时更改音量的速度。 |
| `on-click`         | string  |             | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`     | string  |             | 在模块上向上滚动时执行的命令。<br>这将替换默认的音量控制行为。 |
| `on-scroll-down`   | string  |             | 在模块上向下滚动时执行的命令。<br>这将替换默认的音量控制行为。 |
| `tooltip` | bool  | `true`              | 启用悬停时工具提示的选项。 |
| `tooltip-format`| string | `{node_name}` | 悬停时的工具提示。 |
| `max-volume` | float | 100.0 | 可设置的最大音量，以百分比表示。 |
| `reverse-scrolling`          | bool    | false        | 反转非鼠标设备（触摸板、轨迹板等）滚动方向的选项  |
| `reverse-mouse-scrolling`    | bool    | false        | 反转鼠标滚动方向的选项 |
| `node-type`| string | `Audio/Sink` | 节点类型。可以是 `Audio/Sink` 或 `Audio/Source`。 |
| `only-physical`| bool | false | 如果默认输出是虚拟的（没有 device.id），则跟踪链接到第一个物理输出节点的选项。 |

#### 格式替换：

| string | replacement |
| ---------- | ----------- |
| `{volume}` | 音量百分比 |
| `{icon}`   | 图标，如 `format-icons` 中定义的。 |
| `{node_name}` | 节点的昵称（WirePlumber 的 `node.nick` 属性） |
| `{format_source}` | 音频源格式，`format-source`、`format-source-muted`。 |
| `{source_volume}` | 音频源音量百分比 |
| `{source_desc}` | 音频源描述（node.nick 或 node.description） |


#### 示例：

```jsonc
"wireplumber": {
    "format": "{volume}%",
    "format-muted": "",
    "on-click": "helvum",
    "max-volume": 150,
    "scroll-step": 0.2
}
```

带图标支持：

```jsonc
"wireplumber": {
    "format": "{volume}% {icon}",
    "format-muted": "",
    "on-click": "helvum",
    "format-icons": ["", "", ""]
}
```

用于音频源（麦克风等）节点：

```jsonc
"wireplumber#source": {
    "node-type": "Audio/Source",
    "format": "{volume}% 󰍬",
    "format-muted": "󰍭",
    "on-click-right": "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
    "scroll-step": 5,
},
```

带有合并的输出和输入信息：

```jsonc
"wireplumber": {
    "format": "{volume}% {icon} {format_source}",
    "format-muted": " {format_source}",
    "format-source": "{source_volume}% ",
    "format-source-muted": " ",
    "format-icons": {
        "default": ["", ""]
    },
    "on-click": "helvum"
}
```

### 样式

- `#wireplumber`
- `#wireplumber.muted`
- `#wireplumber.sink-muted`
- `#wireplumber.source-muted`
