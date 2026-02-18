`pulseaudio` 模块显示 PulseAudio 报告的当前音量。

此外，你可以在光标悬停在模块上时通过向*上*或向*下*滚动来控制音量。

### 配置

| option             | typeof  | default     | description |
| ------------------ | ------- | ----------- | ----------- |
| `format`           | string  | `{volume}%` | 信息的显示格式。<br>当未指定其他格式时使用此格式。 |
| `format-bluetooth` | string  |             | 使用蓝牙扬声器时使用此格式。 |
| `format-muted`     | string  |             | 静音时使用此格式。 |
| `format-source`     | string  |   `{volume}%`          | 音频输入源使用的格式。 |
| `format-source-muted`     | string  |             | 音频输入源静音时使用此格式。 |
| `format-icons`     | array   |             | 根据当前端口名称和音量，选择对应的图标。<br>顺序为从*低*到*高*。参见 [`Icons`](#module-pulseaudio-config-icons) |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `states`         | array   |               | 在特定音量级别时激活的一系列音量状态。<br>参见 [States](https://github.com/Alexays/Waybar/wiki/States) |
| `max-length`       | integer |             | 模块应显示的最大字符长度。 |
| `scroll-step`      | float | 1.0           | 滚动时调整音量的步进值。 |
| `on-click`         | string  |             | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`     | string  |             | 在模块上向上滚动时执行的命令。<br>此选项将替代默认的音量控制行为。 |
| `on-scroll-down`   | string  |             | 在模块上向下滚动时执行的命令。<br>此选项将替代默认的音量控制行为。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停时显示工具提示的选项。 |
| `tooltip-format`| string | `{desc}` | 悬停时的工具提示。 |
| `max-volume` | integer | 100 | 可设置的最大音量百分比。 |
| `ignored-sinks` | array |       | 按描述忽略的音频输出列表。<br>使用 `pactl list sinks` 查找正确的描述。 |
| `reverse-scrolling` | bool | false | 反转非鼠标设备（触摸板、轨迹板等）的滚动方向的选项 |
| `reverse-mouse-scrolling` | bool | false | 反转鼠标滚动方向的选项 |

#### 格式替换：

| string     | replacement |
| ---------- | ----------- |
| `{volume}` | 音量百分比 |
| `{icon}`   | 图标，在 `format-icons` 中定义。 |
| `{format_source}` | 音频输入源格式，`format-source`、`format-source-muted`。 |
| `{desc}` | PulseAudio 端口的描述，对于蓝牙设备将显示设备名称。 |

<a name="module-pulseaudio-config-icons"></a>

#### 图标：

以下字符串支持用于 *format-icons*。

| string              | note  |
| ------------------- | ----- |
| `[the device name]` | 类似 `alsa_output.pci-0000_00_1f.3.3.analog-stereo` 的形式。<br>你可以使用 PulseAudio 前端查找，例如 `pacmd list-sinks` 或 `pamixer --list-sinks` |

如果在当前 PulseAudio 端口名称中找到匹配，则会选择对应的图标。

| string       | note |
| ------------ | ---- |
| `default`    | 当未找到其他端口时显示。 |
| `headphone`  | 0.9.0 之前为 `headphones` |
| `speaker`    |      |
| `hdmi`       |      |
| `headset`    |      |
| `hands-free` | 0.9.0 之前为 `handsfree` |
| `portable`   |      |
| `car`        |      |
| `hifi`       |      |
| `phone`      |      |

此外，在设备名称或端口后添加 `-muted` 后缀，将在相应音频设备静音时选择该图标。这也适用于 `default`。


#### 示例：

```jsonc
"pulseaudio": {
    "format": "{volume}% {icon}",
    "format-bluetooth": "{volume}% {icon}",
    "format-muted": "",
    "format-icons": {
        "alsa_output.pci-0000_00_1f.3.analog-stereo": "",
        "alsa_output.pci-0000_00_1f.3.analog-stereo-muted": "",
        "headphone": "",
        "hands-free": "",
        "headset": "",
        "phone": "",
        "phone-muted": "",
        "portable": "",
        "car": "",
        "default": ["", ""]
    },
    "scroll-step": 1,
    "on-click": "pavucontrol",
    "ignored-sinks": ["Easy Effects Sink"]
}
```

### 样式

- `#pulseaudio`
- `#pulseaudio.bluetooth`
- `#pulseaudio.muted`
- `#pulseaudio.source-muted`
