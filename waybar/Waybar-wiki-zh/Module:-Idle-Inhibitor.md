`idle_inhibitor` 模块可以抑制空闲行为，如屏幕熄灭、锁屏和屏幕保护，也称为"演示模式"。

### 配置

通过 `idle_inhibitor` 引用

| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `format`         | string  | `{status}`    | 状态的显示格式。 |
| `format-icons`   | array   |               | 根据当前状态，选择对应的图标。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `max-length`     | integer |               | 模块应显示的最大字符长度。 |
| `on-click`       | string  |               | 点击模块时执行的命令。点击同时也会切换状态。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |               | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |               | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停提示的选项。 |
| `tooltip-format-activated` | string | `{status}` | 抑制激活时使用的格式。 |
| `tooltip-format-deactivated` | string | `{status}` | 抑制停用时使用的格式。 |
| `start-activated` | bool   | `false`       | 启动 waybar 时是否激活抑制。 |  
| `timeout` | double  | `0`              | 自动停用的时间，单位为分钟。 |

#### 格式替换：

| string       | replacement |
| ------------ | ----------- |
| `{status}` | 状态（`activated` 或 `deactivated`） |
| `{icon}`     | 图标，在 `format-icons` 中定义。 |

#### 示例：
```jsonc
"idle_inhibitor": {
    "format": "{icon}",
    "format-icons": {
        "activated": "",
        "deactivated": ""
    }
}
```

### 样式

- `#idle_inhibitor`
- `#idle_inhibitor.<status>`
  - `<status>` 是 `{status}` 格式替换之一。更多信息请参见[格式替换](#format-replacements)
