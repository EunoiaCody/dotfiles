`cpu` 模块用于显示当前 CPU 使用率。

### 配置

通过 `cpu` 进行配置

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `interval`       | integer | 10      | CPU 信息的轮询间隔（秒）。 |
| `format`         | string  | `{usage}%`    | 信息的显示格式。`{}` 中的数据会被替换（见下文）。 |
| `max-length`     | integer |         | 模块应显示的最大字符长度。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `states`         | array   |               | 一组在特定使用率级别时激活的 CPU 使用状态。<br>参见 [States](https://github.com/Alexays/Waybar/wiki/States) |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停时工具提示的选项。 |

#### 格式替换符：

| string             | replacement |
| ------------------ | ----------- |
| `{load}`         | 1 分钟 CPU 平均负载。 |
| `{usage}`         | 当前 CPU 使用率（百分比视图）。 |
| `{usageN}`         | 第 _N_ 个 CPU 核心的使用率（百分比视图）。 |
| `{icon}`         | 当前 CPU 使用率（图标视图）。 |
| `{iconN}`         | 第 _N_ 个 CPU 核心的使用率（图标视图）。 |
| `{avg_frequency}`         | 当前 CPU 平均频率（基于所有核心），单位为 GHz。 |
| `{max_frequency}`         | 当前 CPU 最大频率（基于频率最高的核心），单位为 GHz。 |
| `{min_frequency}`         | 当前 CPU 最小频率（基于频率最低的核心），单位为 GHz。 |

#### 示例：
```jsonc
"cpu": {
    "interval": 10,
    "format": "{}% ",
    "max-length": 10
}
```

```jsonc
"cpu": {
     "format": "{icon0} {icon1} {icon2} {icon3} {icon4} {icon5} {icon6} {icon7}",
     "format-icons": ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"],
},
```

使用 [PangoMarkupFormat](https://github.com/Alexays/Waybar/wiki/Configuration#module-format)：

```jsonc
"cpu": {
     "interval": 1,
     "format": "{icon0}{icon1}{icon2}{icon3}{icon4}{icon5}{icon6}{icon7}",
     "format-icons": [
          "<span color='#69ff94'>▁</span>", // green
          "<span color='#2aa9ff'>▂</span>", // blue
          "<span color='#f8f8f2'>▃</span>", // white
          "<span color='#f8f8f2'>▄</span>", // white
          "<span color='#ffffa5'>▅</span>", // yellow
          "<span color='#ffffa5'>▆</span>", // yellow
          "<span color='#ff9977'>▇</span>", // orange
          "<span color='#dd532e'>█</span>"  // red
     ]
}
```

```jsonc
"cpu": {
     "format": "{icon0}{icon1}{icon2}{icon3}{icon4}{icon5}{icon6}{icon7}",
     "format-icons": [
       "🁣", "🁤", "🁥", "🁦", "🁧", "🁨", "🁩", 
       "🁪", "🁫", "🁬", "🁭", "🁮", "🁯", "🁰", 
       "🁱", "🁲", "🁳", "🁴", "🁵", "🁶", "🁷", 
       "🁸", "🁹", "🁺", "🁻", "🁼", "🁽", "🁾", 
       "🁿", "🂀", "🂁", "🂂", "🂃", "🂄", "🂅", 
       "🂆", "🂇", "🂈", "🂉", "🂊", "🂋", "🂌", 
       "🂍", "🂎", "🂏", "🂐", "🂑", "🂒", "🂓", "🁢"
     ],
},
```
### 样式

- `#cpu`
