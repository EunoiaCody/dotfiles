`memory` 模块显示当前 **RAM** 和 **swap** 的使用情况。

### 配置

通过 `memory` 进行配置

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `interval`       | integer | 30      | 信息轮询的时间间隔。 |
| `format`         | string  | `{percentage}%`   | 信息的显示格式。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `states`         | array   |               | 在特定百分比阈值时激活的多个内存使用状态。<br>参见 [States](https://github.com/Alexays/Waybar/wiki/States) |
| `max-length`     | integer |         | 模块显示的最大字符长度。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停时工具提示的选项。 |
| `tooltip-format` | string  | `{used:0.1f}GiB used` | 工具提示中显示的文本格式。 |

#### 格式替换符：

| string         | replacement |
| -------------- | ----------- |
| `{percentage}` | 正在使用的内存百分比。 |
| `{swapPercentage}` | 正在使用的交换空间百分比。 |
| `{total}`      | 总内存量，单位为 GiB。 |
| `{swapTotal}`      | 总交换空间量，单位为 GiB。 |
| `{used}`       | 已使用的内存量，单位为 GiB。 |
| `{swapUsed}`       | 已使用的交换空间量，单位为 GiB。 |
| `{avail}`      | 可用内存量，单位为 GiB。 |
| `{swapAvail}`      | 可用交换空间量，单位为 GiB。 |

#### 示例：
```jsonc
"memory": {
    "interval": 30,
    "format": "{}% ",
    "max-length": 10
}
```

格式化的内存值：
```jsonc
"memory": {
    "interval": 30,
    "format": "{used:0.1f}G/{total:0.1f}G "
}
```

### 样式

- `#memory`
