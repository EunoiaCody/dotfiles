`battery` 模块用于显示电池的当前电量和状态（例如充电中）。

### 配置

通过 `battery` 进行配置

| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `bat`            | string  |               | 要监控的电池，对应 `/sys/class/power_supply/` 中的名称，而非自动检测。 |
| `adapter`        | string  |               | 要监控的适配器，对应 `/sys/class/power_supply/` 中的名称，而非自动检测。 |
| `design-capacity` | bool   | `false`       | 启用使用设计容量而非实际最大容量的选项。因此，即使充满电，电池也可能低于 100%。 |
| `full-at`        | integer |               | 定义电池的最大百分比，适用于老旧电池，例如 96。 |
| `interval`       | integer | 60            | 电池状态的轮询间隔（秒）。 |
| `states`         | array/object |          | 一组在特定电量级别时激活的电池状态。<br>参见 [States](https://github.com/Alexays/Waybar/wiki/States) |
| `format`         | string  | `{capacity}%` | 信息的显示格式。 |
| `format-time`    | string  | `{H} h {M} min` | 预计充满或耗尽时间的格式。使用 `{m}` 表示补零的分钟数。 |
| `format-icons`   | array/object |          | 根据当前电量选择相应的图标。<br>顺序为从*低*到*高*。<br>如果是对象，则按状态选择。 |
| `max-length`     | integer |               | 模块应显示的最大字符长度。 |
| `rotate`         | integer | 	             | 正值用于旋转文本标签。 |
| `on-click`       | string  |               | 点击模块时执行的命令。 |
| `on-click-middle` | string |               | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |               | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |               | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold`| double |     | 滚动时使用的阈值。 |
| `tooltip`        | bool    | `true`        | 启用悬停时工具提示的选项。 |
| `tooltip-format` | string  | `{timeTo}`    | 工具提示格式。 |
| `weighted-average` | bool  | `true`       | 对于多电池设备，可选择按电池容量大小加权计算百分比，而不是简单地取各电池百分比的平均值。 |
| `bat-compatibility` | bool | `false`       | 未检测到电池时启用电池兼容模式的选项。 |

#### 格式替换符：

| string       | replacement |
| ------------ | ----------- |
| `{capacity}` | 电量百分比 |
| `{power}`    | 功耗（瓦特） |
| `{icon}`     | 图标，如 `format-icons` 中所定义。 |
| `{time}`     | 预计充满或耗尽时间。注意，此值基于上次刷新时的功耗，而非平均值。 |
| `{cycles}`   | 最大容量电池的充电循环次数 *（仅限 Linux）* |

<!--
| `{health}`   | A percentage representing the highest-capacity battery's current maximum charge relative to it's design capacity *(Linux only)* |
-->

<a name="module-battery-config-format-custom"></a>

#### 自定义格式：

`battery` 模块允许基于最多两个因素定义自定义格式。将选择最匹配的格式。

| format                    | description |
| ------------------------- | ----------- |
| `format-<state>`          | 使用 [states](#module-battery-config-states)，可以根据电池电量设置自定义格式。 |
| `format-<status>`         | 根据 `/sys/class/power_supply/<bat>/status` 中的状态（小写）设置自定义格式。 |
| `format-<status>-<state>` | 也可以根据两个值同时设置自定义格式。 |

<a name="module-battery-config-tooltip-format-custom"></a>

#### 自定义工具提示格式：

工具提示格式可以像标签格式一样进行更改。将从 `tooltip-format`、`tooltip-format-<state>`、`tooltip-format-<status>` 和 `tooltip-format-<status>-<state>` 中选择最匹配的格式（使用与 `format-*` 相同的逻辑）。有效的工具提示格式替换符如下：

| string       | replacement |
| ------------ | ----------- |
| `{capacity}` | 电量百分比 |
| `{power}`    | 功耗（瓦特） |
| `{time}`     | 预计充满或耗尽时间。注意，此值基于上次刷新时的功耗，而非平均值。 |
| `{timeTo}`   | 预计充满或耗尽时间，或根据当前电池状态显示"Full"、"Plugged"或"Empty"。 |
| `{cycles}`   | 最大容量电池的充电循环次数 *（仅限 Linux）* |
| `{health}`   | 表示最大容量电池当前最大充电量相对于其设计容量的百分比 *（仅限 Linux）* |

<a name="module-battery-config-states"></a>

#### 状态：

- 每个条目（*状态*）由一个 `<name>`（类型：`string`）和一个 `<value>`（类型：`integer`）组成。
  - 该状态可以在 `style.css` 中作为 CSS 类来引用。CSS 类的名称就是状态的 `<name>`。
    当当前电量等于或低于配置的 `<value>` 时，对应的类将被激活。
  - 此外，每个状态都可以有自己的 `format`。
    可以通过 `format-<name>` 进行配置。
    或者如果需要更细致的区分，可以使用 `format-<status>-<state>`。更多信息请参见[自定义格式](#module-battery-config-format-custom)。

#### 示例：
```jsonc
"battery": {
    "bat": "BAT2",
    "interval": 60,
    "states": {
        "warning": 30,
        "critical": 15
    },
    "format": "{capacity}% {icon}",
    "format-icons": ["", "", "", "", ""],
    "max-length": 25
}
```

根据 `<state>` 自定义图标集：

```jsonc
"battery": {
    "bat": "BAT2",
    "interval": 60,
    "format": "{capacity}% {icon}",
    "format-icons": {
        "default": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
        "charging": ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    },
}
```

### 样式

- `#battery`
- `#battery.<status>`
  - `<status>` 是 `/sys/class/power_supply/<bat>/status` 的小写值。
- `#battery.<state>`
  - `<state>` 可以在 `config` 中定义。更多信息请参见 [`states`](#module-battery-config-states)。
- `#battery.<status>.<state>`
  - `<status>` 和 `<state>` 的组合。

以下类可以将样式应用于_整个 Waybar_：

- `window#waybar.battery-<state>`
  - `<state>` 可以在 `config` 中定义，如前所述。
