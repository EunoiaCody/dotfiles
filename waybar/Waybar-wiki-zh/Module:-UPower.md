### 配置

通过 `upower` 进行配置

| option | typeof | default | description |
| ----------------- | ------- | ------------------- | ----------- |
| `native-path`     | string  |                     | 要监控的电池。请参阅 [Upower native-path](https://upower.freedesktop.org/docs/UpDevice.html#UpDevice--native-path)。可以使用 `upower --dump` 获取。|
| `icon-size`       | integer | 20                  | 定义图标的大小。 |
| `format`          | string  | {percentage}        | 文本格式。 |
| `format-alt`      | string  | {percentage} {time} | 切换后的文本格式。 |
| `hide-if-empty`   | bool    | true                | 定义在找不到设备时模块是否可见。 |
| `on-click`        | string  |                     | 点击模块时执行的命令。 |
| `tooltip`         | bool    | true                | 禁用悬停时工具提示的选项。 |
| `tooltip-spacing` | integer | 4                   | 定义工具提示中设备名称和设备电池状态之间的间距。 |
| `tooltip-padding` | integer | 4                   | 定义工具提示窗口边缘和工具提示内容之间的间距。 |
| `show-icon`       | bool    | true                | 禁用电池图标的选项。 |

#### 格式替换：

| string | replacement |
| ----------------------| ----------- |
| `{percentage}`        | 电池容量百分比。 |
| `{time}`              | 根据充电状态，估计的耗尽时间或充满时间。 |

#### 示例：

```jsonc
"upower": {
     "icon-size": 20,
     "hide-if-empty": true,
     "tooltip": true,
     "tooltip-spacing": 20
}

"upower": {
     "native-path": "/org/bluez/hci0/dev_D4_AE_41_38_D0_EF",
     "icon-size": 20,
     "hide-if-empty": true,
     "tooltip": true,
     "tooltip-spacing": 20
}

"upower": {
     "native-path": "battery_sony_controller_battery_d0o27o88o32ofcoee",
     "icon-size": 20,
     "hide-if-empty": true,
     "tooltip": true,
     "tooltip-spacing": 20
}

"upower": {
     "show-icon": false,
     "hide-if-empty": true,
     "tooltip": true,
     "tooltip-spacing": 20
}
```

### 样式

- `#upower`
- `#upower.charging`
- `#upower.discharging`
- `#upower.unknown-status`
