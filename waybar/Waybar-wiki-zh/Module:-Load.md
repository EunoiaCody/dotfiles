`load` 模块显示当前 CPU 负载。

### 配置

通过 `load` 进行配置

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `interval`       | integer | 10      | 信息轮询的时间间隔。 |
| `format`         | string  | `{}`    | 信息的显示格式。 |
| `max-length`     | integer |         | 模块显示的最大字符长度。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
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
| `{}`               | 等同于 `load1` |
| `{load1}`          | 过去 1 分钟的平均 CPU 负载 |
| `{load5}`          | 过去 5 分钟的平均 CPU 负载 |
| `{load15}`         | 过去 15 分钟的平均 CPU 负载 |

#### 示例：
```jsonc
"load": {
    "interval": 10,
    "format": "load: {load1}",
    "max-length": 10
}
```

```jsonc
"load": {
    "interval": 1,
    "format": "load: {load1} {load5} {load15}"
}
```

### 样式

- `#load`
