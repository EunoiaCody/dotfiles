`sndio` 模块显示 sndio 报告的当前音量。

此外，你可以在光标悬停在模块上时通过向*上*或向*下*滚动来控制音量，点击模块可以切换静音。

### 配置

| option             | typeof  | default     | description |
| ------------------ | ------- | ----------- | ----------- |
| `format`           | string  | `{volume}%` | 信息的显示格式。 |
| `format-bluetooth` | string  |             | 使用蓝牙扬声器时使用此格式。 |
| `rotate` | integer | 0 | 正值用于旋转文本标签。 |
| `max-length`       | integer |             | 模块应显示的最大字符长度。 |
| `scroll-step`      | integer | 5 | 滚动时调整音量的步进值。 |
| `on-click`         | string  |             | 点击模块时执行的命令。<br>此选项将替代默认的静音切换行为。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`     | string  |             | 在模块上向上滚动时执行的命令。<br>此选项将替代默认的音量控制行为。 |
| `on-scroll-down`   | string  |             | 在模块上向下滚动时执行的命令。<br>此选项将替代默认的音量控制行为。 |
| `on-update`   | string  |             | 模块更新时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停时显示工具提示的选项。 |

#### 格式替换：

| string     | replacement |
| ---------- | ----------- |
| `{volume}` | 音量百分比。 |
| `{raw_volume}` | sndio 报告的原始音量。 |

#### 示例：

```jsonc
"sndio": {
    "format": "{raw_value} 🎜",
    "scroll-step": 3
}
```

### 样式

- `#sndio`
- `#sndio.muted`