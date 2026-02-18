`jack` 模块显示 [JACK](https://jackaudio.org/) 服务器的当前状态。支持 JACK API 的 [JACK2](https://github.com/jackaudio/jack2) 和 [PipeWire](https://pipewire.org/) 实现。

注意：建议 PipeWire 用户至少升级到 v0.3.57；没有[此错误修复](https://gitlab.freedesktop.org/pipewire/pipewire/-/commit/d7da581b9c9f1783a599cd95edd0bd5a5a5b4f05)的早期版本会导致 Waybar 客户端在服务器关闭且 Waybar 模块正在运行时无限期挂起。

### 配置

通过 `jack` 引用

| option           | typeof  | default      | description |
| ---------------- | ------- | -------------| ----------- |
| `format`         | string  | `{load}%`    | 信息的显示格式。当未指定其他格式时使用此格式。 |
| `format-connected` | string |             | 模块连接到 JACK 服务器时使用的格式。 |
| `format-disconnected` | string |          | 模块未连接到 JACK 服务器时使用的格式。 |
| `format-xrun`    | string  |              | 当 JACK 服务器报告 xrun 时，在一个轮询间隔内使用的格式。 |
| `realtime`       | bool    | `true`       | 为 Waybar 打开的 JACK 客户端放弃实时权限的选项。 |
| `tooltip`        | bool    | `true`       | 禁用悬停提示的选项。 |
| `tooltip-format` | string  | `{bufsize}/{samplerate} {latency}ms` | 提示中显示信息的格式。 |
| `interval`       | integer | `1`          | 信息轮询的间隔时间。 |
| `rotate`         | integer |              | 正值用于旋转文本标签。 |
| `max-length`     | integer |              | 模块应显示的最大字符长度。 |
| `min-length`     | integer |              | 模块应占用的最小字符长度。 |
| `align`          | float   |              | 文本的对齐方式，0 为左对齐，1 为右对齐。如果模块被旋转，将跟随文本的流向。 |
| `on-click`       | string  |              | 点击模块时执行的命令。 |
| `on-click-middle` | string |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |              | 右键点击模块时执行的命令。 |
| `on-update`      | string  |              | 模块更新时执行的命令。 |

#### 格式替换：

| string                | replacement |
| ---------------| ----------- |
| `{load}`       | JACK 估算的当前 CPU 负载。 |
| `{bufsize}`    | JACK 缓冲区的大小。 |
| `{samplerate}` | JACK 服务器运行的采样率。 |
| `{latency}`    | 当前缓冲区大小的持续时间，单位为毫秒。 |
| `{xruns}`      | 自启动 Waybar 以来 JACK 服务器报告的 xrun 次数。 |

#### 示例：

```jsonc
"jack": {
    "format": "DSP {}%",
    "format-xrun": "{xruns} xruns",
    "format-disconnected": "DSP off",
    "realtime": true
}
```

### 样式

- `#jack`
- `#jack.connected`
- `#jack.disconnected`
- `#jack.xrun`
