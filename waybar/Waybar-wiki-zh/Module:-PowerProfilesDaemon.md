`power-profiles-daemon` 模块显示当前活动的 [power-profiles-daemon](https://gitlab.freedesktop.org/upower/power-profiles-daemon) 配置文件，并在点击时循环切换可用的配置文件。

# 配置

| option | typeof | default | description |
| ------ | ------ | ------- | ----------- |
| format | string | {icon} | 栏上显示的信息。`{icon}` 和 `{profile}` 分别替换为代表活动配置文件的图标及其完整名称。 |
| tooltip-format | string | Power profile: {profile}\\nDriver: {driver} | 模块工具提示中显示的信息。`{icon}` 和 `{profile}` 分别替换为代表活动配置文件的图标及其完整名称。 |
| tooltip | bool | true | 显示工具提示。 |
| format-icons | object | 参见下方示例中的默认值。 | 用于表示各种电源配置文件的图标。**注意**：默认配置使用 font-awesome 图标。如果您的系统未安装此字体，您可能需要覆盖它。 |

## 格式替换符

以下格式替换符可用于自定义栏上和工具提示中显示的信息。

| string | replacement |
| ------ | ----------- |
| profile | 活动配置文件的完整名称 |
| icon | 代表活动配置文件的 Fontawesome 图标 |

# 配置示例

紧凑显示（默认配置）：

```
"power-profiles-daemon": {
  "format": "{icon}",
  "tooltip-format": "Power profile: {profile}\nDriver: {driver}",
  "tooltip": true,
  "format-icons": {
    "default": "",
    "performance": "",
    "balanced": "",
    "power-saver": ""
  }
}
```

显示完整的配置文件名称：

```
"power-profiles-daemon": {
  "format": "{icon}   {profile}",
  "tooltip-format": "Power profile: {profile}\nDriver: {driver}",
  "tooltip": true,
  "format-icons": {
    "default": "",
    "performance": "",
    "balanced": "",
    "power-saver": ""
  }
}
```

### 样式

- `#power-profiles-daemon`
- `#power-profiles-daemon.performance`
- `#power-profiles-daemon.balanced`
- `#power-profiles-daemon.power-saver`
