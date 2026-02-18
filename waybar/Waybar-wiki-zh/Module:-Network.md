`network` 模块显示当前网络连接的信息。

### 配置

通过 `network` 进行配置

| option                | typeof  | default    | description |
| --------------------- | ------- | ---------- | ----------- |
| `interface`           | string  |            | 使用指定的接口代替自动检测。<br>支持通配符。 |
| `interval`			| integer | 60		   | 网络信息（如信号强度）的轮询间隔。 |
| `family`              | string  | `ipv4`     | 用于格式替换符 {ipaddr} 以及判断网络连接是否存在的地址族。设置为 ipv4_6 可同时显示两者。 |
| `format`              | string  | `{ifname}` | 信息的显示格式。<br>当未指定其他格式时使用此格式。 |
| `format-ethernet`     | string  |            | 显示以太网接口时使用的格式。 |
| `format-wifi`         | string  |            | 显示无线接口时使用的格式。 |
| `format-linked`       | string  |            | 显示已连接但没有 IP 地址的接口时使用的格式。 |
| `format-disconnected` | string  |            | 显示的接口已断开连接时使用的格式。 |
| `format-disabled`     | string  |            | 显示的接口已禁用时使用的格式。 |
| `format-alt` | string  |            | 点击时切换到替代格式。 |
| `format-icons`        | array/object |       | 根据当前容量选择对应的图标。<br>顺序为从*低*到*高*。<br>如果是对象则根据状态选择。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `max-length`          | integer |            | 模块显示的最大字符长度。 |
| `on-click`            | string  |            | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`        | string  |            | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down`      | string  |            | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停时工具提示的选项。 |
| `tooltip-format`      | string  |            | 工具提示中信息的显示格式。<br>当未指定其他格式时使用此格式。 |
| `tooltip-format-ethernet`     | string  |            | 显示以太网接口时使用的格式。 |
| `tooltip-format-wifi`         | string  |            | 显示无线接口时使用的格式。 |
| `tooltip-format-disconnected` | string  |            | 显示的接口已断开连接时使用的格式。 |
| `tooltip-format-disabled`     | string  |            | 显示的接口已禁用时使用的格式。 |


#### 格式替换符：

| string                | replacement |
| ----------------------| ----------- |
| `{ifname}`            | 网络接口的名称。 |
| `{ipaddr}`            | 接口的第一个 IP 地址。 |
| `{gwaddr}`            | 接口的默认网关。 |
| `{netmask}`           | 对应 IP(V4) 的子网掩码。 |
| `{netmask6}`          | 对应 IP(V6) 的子网掩码。 |
| `{cidr}`              | 对应 IP(V4) 的 CIDR 表示法子网掩码。 |
| `{cidr6}`              | 对应 IP(V6) 的 CIDR 表示法子网掩码。 |
| `{essid}`             | 无线网络的名称（SSID）。 |
| `{signalStrength}`    | 无线网络的信号强度。 |
| `{signaldBm}`         | 无线网络的信号强度（dBm）。 |
| `{frequency}`         | 无线网络的频率（GHz）。 |
| `{bandwidthUpBits}`     | 即时上行速度（bits/秒）。 |
| `{bandwidthDownBits}`   | 即时下行速度（bits/秒）。 |
| `{bandwidthTotalBits}`  | 即时总速度（bits/秒）。 |
| `{bandwidthUpOctets}`   | 即时上行速度（octets/秒）。 |
| `{bandwidthDownOctets}` | 即时下行速度（octets/秒）。 |
| `{bandwidthTotalOctets}` | 即时总速度（octets/秒）。 |
| `{bandwidthUpBytes}`  | 即时上行速度（bytes/秒）。 |
| `{bandwidthDownBytes}`| 即时下行速度（bytes/秒）。 |
| `{bandwidthTotalBytes}`| 即时总速度（bytes/秒）。 |
| `{icon}`              | 图标，在 `format-icons` 中定义。 |

#### 示例：
```jsonc
"network": {
    "interface": "wlp2s0",
    "format": "{ifname}",
    "format-wifi": "{essid} ({signalStrength}%) ",
    "format-ethernet": "{ipaddr}/{cidr} 󰊗",
    "format-disconnected": "", //An empty format will hide the module.
    "tooltip-format": "{ifname} via {gwaddr} 󰊗",
    "tooltip-format-wifi": "{essid} ({signalStrength}%) ",
    "tooltip-format-ethernet": "{ifname} ",
    "tooltip-format-disconnected": "Disconnected",
    "max-length": 50
}
```

### 样式

- `#network`
- `#network.disabled`
- `#network.disconnected`
- `#network.linked`
- `#network.ethernet`
- `#network.wifi`
