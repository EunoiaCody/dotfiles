`clock` 模块显示当前日期和时间。

**注意：** 有两种 `clock` 实现：
1. `clock`：完全符合以下所述内容。当满足以下任一编译时条件时启用：
> 1. C++20 且 __cpp_concepts >= 201907 (gcc >=13)
> 2. 已安装 [date.h](https://github.com/HowardHinnant/date)
2. `simpleclock`：仅提供日期时间功能。仅此而已。使用条件：不满足第一点。

### 配置

通过 `clock` 寻址

| option           | typeof  | default    | description |
| ---------------- | ------- | ---------- | ----------- |
| `interval`       | integer | 60         | 信息轮询的时间间隔。 |
| `format`         | string  | `{:%H:%M}` | 日期和时间的显示格式；格式选项参见[此处](https://fmt.dev/latest/syntax/#chrono-format-specifications)。可拆分花括号，如 `{0:%H}text{0:%M}`。 |
| `format-alt`     | string  |            | 点击时切换到此替代格式（如果已指定）。 |
| `timezone`       | string  |            | 显示时间的时区，例如 America/New_York。参见 [Wikipedia 的非官方时区列表](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)。 |
| `timezones`      | list of strings  |   | 用于时间显示的时区列表（同 `timezone`），通过滚轮切换。指定 `timezones` 时请勿指定 `timezone` 选项。 |
| `locale`         | string  |            | 用于显示时间的区域设置。用于在自定义时区中以正确的语言和格式呈现时间。 |
| `max-length`     | integer |            | 模块应显示的最大字符长度。 |
| `rotate`         | integer | 		  | 正值用于旋转文本标签。 |
| `on-click`       | string  |            | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |            | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |            | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip`        | bool    | true       | 启用悬停提示的选项。 |
| `tooltip-format` | string  | same as format | 悬停时的提示信息。也可以显示其他时区的时钟列表。参见下面使用 `tz_list` 属性的示例。 |

通过 `clock: calendar` 寻址
| option           | typeof  | default    | description |
| ---------------- | ------- | ---------- | ----------- |
| `mode`           | string  | month      | 日历视图模式。可选值：year\|month|
| `mode-mon-col`   | integer | 3          | 与 `mode=year` 相关。每行显示的月份数|
| `weeks-pos`      | string  |            | 周数显示的位置。为空时禁用。可选值：left\|right|
| `on-scroll`      | integer | 1          | 向前/向后滚动月份/年份的值。可以为负数。在 `on-scroll` 选项下配置|

通过 `clock: calendar: format` 寻址
| option           | typeof  | default    | description |
| ---------------- | ------- | ---------- | ----------- |
| `months`         | string  |            | 应用于月份标题的格式（January、February 等） |
| `days`           | string  |            | 应用于日期的格式 |
| `weeks`          | string  | `{:%U}`    | 应用于周数的格式。未提供星期格式时使用默认格式：星期从周一开始时为 '{:%W}'，否则为 '{:%U}' |
| `weekdays`       | string  |            | 应用于星期标题的格式（Su、Mo 等） |
| `today`          | string  | `<b><u>{}</u></b>` | 应用于今天的格式 |

### 操作
| string           | action  |
| ---------------- | ------- |
| `mode`           | 在年/月之间切换日历模式     |
| `tz_up`          | 切换到下一个提供的时区       |
| `tz_down`        | 切换到上一个提供的时区   |
| `shift_up`       | 切换到下一个日历月份/年份      |
| `shift_down`     | 切换到上一个日历月份/年份  |
| `shift_reset`     | 切换到当前日历月份/年份  |

#### 示例：
1. 通用
```jsonc
"clock": {
    "interval": 60,
    "format": "{:%H:%M}",
    "max-length": 25
}
```
2. 日历
```jsonc
    "clock": {
        "format": "{:%H:%M}  ",
        "format-alt": "{:%A, %B %d, %Y (%R)}  ",
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "calendar": {
                    "mode"          : "year",
                    "mode-mon-col"  : 3,
                    "weeks-pos"     : "right",
                    "on-scroll"     : 1,
                    "format": {
                              "months":     "<span color='#ffead3'><b>{}</b></span>",
                              "days":       "<span color='#ecc6d9'><b>{}</b></span>",
                              "weeks":      "<span color='#99ffdd'><b>W{}</b></span>",
                              "weekdays":   "<span color='#ffcc66'><b>{}</b></span>",
                              "today":      "<span color='#ff6699'><b><u>{}</u></b></span>"
                              }
                    },
        "actions":  {
                    "on-click-right": "mode",
                    "on-scroll-up": "tz_up",
                    "on-scroll-down": "tz_down",
                    "on-scroll-up": "shift_up",
                    "on-scroll-down": "shift_down"
                    }
    },
```
![calendar](https://github.com/Alexays/Waybar/assets/6098822/e5c38984-6b3c-43ef-8cac-05122a078d58)

3. 悬停时显示完整日期
```jsonc
"clock": {
    "interval": 60,
    "tooltip": true,
    "format": "{:%H.%M}",
    "tooltip-format": "{:%Y-%m-%d}",
}
```
4. 在时钟提示中显示其他时区的时钟列表
```json
"clock": {
    "format": "{:%H:%M:%S (%Z)}",
    "tooltip-format": "{tz_list}",
    "timezones": [
        "Etc/UTC",
        "America/New_York",
        "America/Montevideo",
        "America/Los_Angeles",
        "Asia/Tokyo"
    ]
}
```

### 样式

- `#clock`


#### 显示秒数导致其他模块左右偏移/抖动

这是比例字体的常见问题；数字字形的宽度差异很大。如果您的字体支持，可以在 `#clock` 样式中添加 `font-feature-settings: "tnum";`，或在为整个栏设置字体样式的位置添加。支持的字体将使用等宽数字。

### 故障排除

如果时钟模块在启动时因 `locale::facet::_S_create_c_locale name not valid` 错误信息而被禁用，请尝试以下方法之一：
* 检查 `LC_TIME` 是否设置正确（glibc）
* 在配置文件中将区域设置为 `C`（musl）

如果使用 `clock` 而非 `simpleclock`，无论区域设置如何，区域默认为 `C`。要覆盖此行为，需在格式字符串前添加 `L`。例如，`{:%a %m %d}` 变为 `{:L%a %m %d}`。

必须设置 `locale` 选项才能使 {calendar} 使用正确的一周起始日，无论系统区域设置如何。

#### 中文日历。对齐
为了使中文日历对齐，以下是一些有用的建议：
1. 使用"WenQuanYi Zen Hei Mono"字体，大多数 Linux 发行版都提供此字体
2. 尝试不同的字体大小并找到最适合您的。size = 9pt 应该合适
3. 使用"WenQuanYi Zen Hei Mono"字体时，禁用 monospace 字体的 pango 标签

可用配置示例
```json
"clock": {
        "format": "{:%H:%M}  ",
        "format-alt": "{:L%A, %B %d, %Y (%R)}  ",
        "tooltip-format": "\n<span size='9pt' font='WenQuanYi Zen Hei Mono'>{calendar}</span>",
        "calendar": {
                    "mode"          : "year",
                    "mode-mon-col"  : 3,
                    "weeks-pos"     : "right",
                    "on-scroll"     : 1,
                    "format": {
                              "months":     "<span color='#ffead3'><b>{}</b></span>",
                              "days":       "<span color='#ecc6d9'><b>{}</b></span>",
                              "weeks":      "<span color='#99ffdd'><b>W{}</b></span>",
                              "weekdays":   "<span color='#ffcc66'><b>{}</b></span>",
                              "today":      "<span color='#ff6699'><b><u>{}</u></b></span>"
                              }
                    },
        "actions":  {
                    "on-click-right": "mode",
                    "on-click-forward": "tz_up",
                    "on-click-backward": "tz_down",
                    "on-scroll-up": "shift_up",
                    "on-scroll-down": "shift_down"
                    }
    },
```
![calendar-chinese](https://github.com/Alexays/Waybar/assets/6098822/aa537991-3ea2-4c45-9bc6-12c1adf9663e)
