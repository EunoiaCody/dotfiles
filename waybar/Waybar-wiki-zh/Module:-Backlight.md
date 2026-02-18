`backlight` 模块用于显示当前背光亮度级别。

### 配置

通过 `backlight` 进行配置

| option                       | typeof  | default      | description |
| ---------------------------- | ------- | ------------ | ----------- |
| `interval`                   | integer | 2            | 背光亮度的轮询间隔（秒）。 |
| `format`                     | string  | `{percent}%` | 信息的显示格式。数据会插入到 `{}` 中。 |
| `format-icons`   | array |              | 根据当前屏幕亮度选择相应的图标。<br>顺序为从*低*到*高*。<br> |
| `max-length`                 | integer |              | 模块应显示的最大字符长度。 |
| `rotate`	               | integer | 		| 正值用于旋转文本标签。 |
| `states`                     | array   |              | 一组在特定亮度级别时激活的背光状态。<br>参见 [States](https://github.com/Alexays/Waybar/wiki/States) |
| `on-click`                   | string  |              | 点击模块时执行的命令。 |
| `on-click-middle`            | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right`             | string  |              | 右键点击模块时执行的命令。 |
| `on-scroll-up`               | string  |              | 在模块上向上滚动时执行的命令。这将替代默认的亮度控制行为。 |
| `on-scroll-down`             | string  |              | 在模块上向下滚动时执行的命令。这将替代默认的亮度控制行为。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `reverse-scrolling`          | bool    | false        | 反转非鼠标设备（触控板、轨迹板等）的滚动方向的选项。 |
| `reverse-mouse-scrolling`    | bool    | false        | 反转鼠标滚动方向的选项。 |
| `scroll-step`                | float   | 1.0          | 滚动时改变亮度的速度。 |
| `tooltip`                    | bool    | `true`       | 禁用悬停时工具提示的选项。 |
| `tooltip-format`             | string  |              | 工具提示中显示的文本。 |

#### 格式替换符：

| string       | replacement |
| ------------ | ----------- |
| `{percent}` | 屏幕亮度百分比 |
| `{icon}`     | 图标，如 `format-icons` 中所定义。 |

#### 示例：
```jsonc
"backlight": {
    "device": "intel_backlight",
    "format": "{percent}% {icon}",
    "format-icons": ["", ""]
}
```

### 样式

- `#backlight`

### 另请参阅
* [External screen brightness](https://gist.github.com/nicodebo/297c1e134256ea24abf02a485ce41420)（使用 [ddcutil](https://github.com/rockowitz/ddcutil)）
* [Another external screen brightness](https://gist.github.com/Ar7eniyan/42567870ad2ce47143ffeb41754b4484)（同样使用 ddcutil）
* [Screen brightness without external scripts](https://gist.github.com/MyrikLD/4467d4dae3f0911cd5094b8440cbf418)（仍然使用 ddcutil）注意：可以在每个设置间隔关闭显示器的屏幕显示菜单（例如：AOC 27G2G8）
* [Screen brightness with simple bash script](https://gist.github.com/negoro26/c59167fb4c08da46c4e08e1fdcd7aeb1)（同样使用 ddcutil）
