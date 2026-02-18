`temperature` 模块显示热区的当前温度。

### 配置

通过 `temperature` 进行配置

| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `thermal-zone`   | integer  |               | 热区，如 `/sys/class/thermal/` 中所示。 |
| `hwmon-path`     | string/array  |          | 要使用的温度路径，例如 `/sys/class/hwmon/hwmon2/temp1_input`，替代 `/sys/class/thermal/` 中的路径。 |
| `hwmon-path-abs` | string/array  |          | 设备 hwmon 目录的路径，例如 `/sys/devices/pci0000:00/0000:00:18.3/hwmon`。（注意子目录 `hwmon/hwmon#`（其中 `#` 为数字）不属于路径的一部分！）必须与 `input-filename` 一起使用。 |
| `input-filename` | string  |               | `hwmon-path-abs` 的温度文件名，例如 `temp1_input` |
| `warning-threshold` | integer |			 | 被视为警告的阈值（摄氏度）。 |
| `critical-threshold` | integer |			 | 被视为临界的阈值（摄氏度）。 |
| `interval`       | integer | 10            | 信息轮询的时间间隔。 |
| `format-critical` | string  |      | 温度被视为临界时使用的格式 |
| `format`         | string  | `{temperatureC}°C` | 温度的显示格式（摄氏度/华氏度）。 |
| `format-icons`   | array   |               | 根据当前温度（摄氏度）以及 `critical-threshold`（如果可用），选择对应的图标。<br>顺序为从*低*到*高*。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `max-length`     | integer |               | 模块应显示的最大字符长度。 |
| `on-click`       | string  |               | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |               | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |               | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停时显示工具提示的选项。 |
| `tooltip-format` | string | `{temperatureC}°C` | 工具提示的格式
#### 格式替换：

| string       | replacement |
| ------------ | ----------- |
| `{temperatureC}` | 摄氏温度。 |
| `{temperatureF}`     | 华氏温度。 |
| `{temperatureK}` | 开尔文温度。 |
| `{icon}` | 图标，在 `format-icons` 中定义。 |

#### 示例：
```jsonc
 "temperature": {
    // "thermal-zone": 2,
    // "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
    // "critical-threshold": 80,
    // "format-critical": "{temperatureC}°C ",
    "format": "{temperatureC}°C "
}
```

### 样式

- `#temperature`
- `#temperature.warning`
- `#temperature.critical`

### 调试

#### 查找你的热区

要列出所有热区类型，运行

```bash
 for i in /sys/class/thermal/thermal_zone*; do echo "$i: $(<$i/type)"; done
```

#### 查找 hwmon 路径
如果你没有热区，另一个选择是使用 `sensors` 查找首选的温度源，然后运行

```bash
for i in /sys/class/hwmon/hwmon*/temp*_input; do echo "$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null || echo $(basename ${i%_*})) $(readlink -f $i)"; done
```

以查找所需文件的路径。然后将其包含在 `hwmon-path` 变量中。
