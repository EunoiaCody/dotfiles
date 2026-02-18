`disk` 模块跟踪文件系统和分区的使用情况。

### 配置

通过 `disk` 寻址

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `interval`       | integer | 30      | 信息轮询的时间间隔。 |
| `format`         | string  | `{percentage_free}%` | 信息的显示格式。 |
| `max-length`     | integer |         | 模块应显示的最大字符长度。 |
| `states`         | array   |         | 一组在特定百分比阈值（percentage_used）时激活的磁盘使用状态。<br>参见 [States](https://github.com/Alexays/Waybar/wiki/States) |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |         | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `path` | string | `/` | 要监控的文件系统挂载点。 |
| `smooth-scrolling-threshold` | double  | | 滚动时使用的阈值。 |
| `tooltip`        | bool    | `true`  | 启用悬停提示的选项。 |
| `tooltip-format` | string  | `{used} used out of {total} on {path} ({percentage_used}%)` | 提示信息中显示的文本格式 |
| `unit`       | string  |    B     | 用于指定 specific_total、specific_used 和 specific_free 的单位。接受 B、kB、kiB、MB、MiB、GB、GiB、TB、TiB。默认为字节。 |

#### 格式替换：

| string         | replacement |
| -------------- | ----------- |
| `{percentage_free}` | 可用空间的百分比。 |
| `{percentage_used}` | 已使用磁盘空间的百分比。 |
| `{total}`      | 磁盘空间总量。将根据空间大小动态更改显示单位。 |
| `{used}`       | 已使用的磁盘空间量。将根据空间大小动态更改显示单位。|
| `{free}`       | 可用的磁盘空间量。将根据空间大小动态更改显示单位。|
| `{specific_total}`      | 始终以特定单位显示的磁盘空间总量。默认为字节。|
| `{specific_used}`       | 始终以特定单位显示的已使用磁盘空间量。默认为字节。 |
| `{specific_free}`       | 始终以特定单位显示的可用磁盘空间量。默认为字节。 |

#### 示例：
```jsonc
"disk": {
    "interval": 30,
    "format": "Only {percentage_free}% remaining on {path}",
    "path": "/"
}

"disk": {
	"interval": 30,
	"format": "{specific_free:0.2f} GB out of {specific_total:0.2f} GB available. Alternatively {free} out of {total} available",
	"unit": "GB"
	// 0.25 GB out of 2000.00 GB available. Alternatively 241.3MiB out of 1.9TiB available.
}
```

### 样式

- `#disk`
