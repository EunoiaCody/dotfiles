`bluetooth` 模块用于显示蓝牙控制器及其连接的相关信息。

### 配置

通过 `bluetooth` 进行配置

| option            | typeof  | default             | description |
| ----------------- | ------- | ------------------- | ----------- |
| `controller` | string |    | 使用指定别名的控制器。否则将随机使用一个控制器。当系统有多个可用控制器时，建议进行定义。 |
| `format-device-preference` | array |    | 蓝牙设备的优先级排名，通过别名指定。顺序为从`首先显示`到`最后显示`。如果未定义此配置选项或列表中的设备均未连接，将回退到显示最后连接的设备。 |
| `format` | string | ` {status}` | 信息的显示格式。当未指定其他格式时使用此格式。
| `format-disabled` | string |    | 当显示的控制器被禁用时使用此格式。 |
| `format-off` | string |    | 当显示的控制器被关闭时使用此格式。 |
| `format-on` | string |    | 当显示的控制器已开启但没有设备连接时使用此格式。 |
| `format-connected` | string |    | 当显示的控制器至少连接了 1 个设备时使用此格式。 |
| `format-no-controller` | string |    | 当没有可用的蓝牙控制器时使用此格式。 |
| `rotate` | integer |    | 正值用于旋转文本标签。 |
| `max-length` | integer |    | 模块应显示的最大字符长度。 |
| `min-length` | integer |    | 模块应占用的最小字符长度。 |
| `align` | float |    | 文本对齐方式，其中 0 为左对齐，1 为右对齐。如果模块被旋转，将跟随文本流方向。 |
| `on-click` | string |    | 点击模块时执行的命令。 |
| `on-click-middle` | string |    | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string |    | 右键点击模块时执行的命令。 |
| `on-scroll-up` | string |    | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string |    | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double |    | 滚动时使用的阈值。 |
| `tooltip` | bool | `true` | 禁用悬停时工具提示的选项。 |
| `tooltip-format` | string |    | 工具提示中信息的显示格式。当未指定其他格式时使用此格式。 |
| `tooltip-format-disabled` | string |    | 当显示的控制器被禁用时使用此格式。 |
| `tooltip-format-off` | string |    | 当显示的控制器被关闭时使用此格式。 |
| `tooltip-format-on` | string |    | 当显示的控制器已开启但没有设备连接时使用此格式。 |
| `tooltip-format-connected` | string |    | 当显示的控制器至少连接了 1 个设备时使用此格式。 |
| `tooltip-format-enumerate-connected` | string |    | 此格式用于定义工具提示菜单中 `device_enumerate` 格式替换符内每个已连接设备的显示方式。 |


#### 格式替换符：

| string                | replacement |
| ----------------------| ----------- |
| `{status}` | 蓝牙设备的状态。 |
| `{num_connections}` | 显示的控制器的连接数量。 |
| `{controller_address}` | 显示的控制器的地址。 |
| `{controller_address_type}` | 显示的控制器的地址类型。 |
| `{controller_alias}` | 显示的控制器的别名。 |
| `{device_address}` | 显示的设备的地址。 |
| `{device_address_type}` | 显示的设备的地址类型。 |
| `{device_alias}` | 显示的设备的别名。 |
| `{device_enumerate}` | 显示所有已连接设备的列表，每个设备单独一行。使用 `tooltip-format-enumerate-connected` 和/或 `tooltip-format-enumerate-connected-battery` 配置选项来定义每个设备的格式。只能在工具提示相关的格式选项中使用。 |

#### 实验性电池百分比功能：
在撰写本文时，需要开启 BlueZ 的实验性功能，以下列出的电池百分比选项才能正常工作。

##### 实验性格式替换符
| string                | replacement |
| ----------------------| ----------- |
| `{device_battery_percentage}` | 显示设备的电池百分比（如果可用）。仅在以下定义的配置选项中使用。 |

##### 实验性配置

| option            | typeof  | default             | description |
| ----------------- | ------- | ------------------- | ----------- |
| `format-connected-battery` | string |    | 当显示的设备提供电池百分比时使用此格式。 |
| `tooltip-format-connected-battery` | string |    | 当显示的设备提供电池百分比时使用此格式。 |
| `tooltip-format-enumerate-connected-battery` | string |    | 此格式用于定义 `device_enumerate` 格式替换符中每个带电池的已连接设备的显示方式。未定义此配置选项时，将回退到 `tooltip-format-enumerate-connected` 配置选项。 |


#### 示例：

```jsonc
"bluetooth": {
	// "controller": "controller1", // specify the alias of the controller if there are more than 1 on the system
	"format": " {status}",
	"format-disabled": "", // an empty format will hide the module
	"format-connected": " {num_connections} connected",
	"tooltip-format": "{controller_alias}\t{controller_address}",
	"tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{device_enumerate}",
	"tooltip-format-enumerate-connected": "{device_alias}\t{device_address}"
}
```

```jsonc
"bluetooth": {
	"format": " {status}",
	"format-connected": " {device_alias}",
	"format-connected-battery": " {device_alias} {device_battery_percentage}%",
	// "format-device-preference": [ "device1", "device2" ], // preference list deciding the displayed device
	"tooltip-format": "{controller_alias}\t{controller_address}\n\n{num_connections} connected",
	"tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}",
	"tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
	"tooltip-format-enumerate-connected-battery": "{device_alias}\t{device_address}\t{device_battery_percentage}%"
}
```

### 样式

- `#bluetooth`
- `#bluetooth.disabled`
- `#bluetooth.off`
- `#bluetooth.on`
- `#bluetooth.connected`
- `#bluetooth.discoverable`
- `#bluetooth.discovering`
- `#bluetooth.pairable`
- `#bluetooth.no-controller`
