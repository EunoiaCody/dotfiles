### 配置

privacy 模块显示是否有应用程序正在捕获音频、共享屏幕或播放音频。

通过 `privacy` 进行配置

| option                | typeof           | default                                           | description |
| --------------------- | ---------------- | ------------------------------------------------- | ----------- |
| `icon-spacing`        | integer          | `4`                                               | 每个隐私图标之间的间距。 |
| `icon-size`           | integer          | `20`                                              | 每个隐私图标的大小。 |
| `transition-duration` | integer          | `250`                                             | 显示和隐藏的过渡动画持续时间。 |
| `modules`             | array of objects | `[{"type": "screenshare"}, {"type": "audio-in"}]` | 要监控的隐私模块。更多信息参见*模块配置*。 |
| `expand`              | bool             | `false`                                           | 启用此模块动态占用所有剩余空间。 |
| `ignore-monitor`      | bool             | `true`                                            | 忽略带有 *stream.monitor* 属性的流。 |
| `ignore`              | array of objects | `[]`                                              | 要忽略的额外流。更多信息参见*忽略配置*。|

#### 模块配置：

| option              | typeof  | default                                          | description |
| ------------------- | ------- | ------------------------------------------------ | ----------- |
| `type`              | string  | 可以是 `screenshare`、`audio-in` 或 `audio-out` | 指定要使用和配置的模块。 |
| `tooltip`           | bool    | `true`                                           | 禁用悬停时工具提示的选项。 |
| `tooltip-icon-size` | integer | `24`                                             | 工具提示中每个图标的大小。 |

#### 忽略配置

| option              | typeof  |
| ------------------- | ------- |
| `type`              | string  |
| `name`              | string  |

#### 示例：

```jsonc
"privacy": {
	"icon-spacing": 4,
	"icon-size": 18,
	"transition-duration": 250,
	"modules": [
		{
			"type": "screenshare",
			"tooltip": true,
			"tooltip-icon-size": 24
		},
		{
			"type": "audio-out",
			"tooltip": true,
			"tooltip-icon-size": 24
		},
		{
			"type": "audio-in",
			"tooltip": true,
			"tooltip-icon-size": 24
		}
	],
	"ignore-monitor": true,
	"ignore": [
		{
			"type": "audio-in",
			"name": "cava"
		},
		{
			"type": "screenshare",
			"name": "obs"
		}
	]
},
```

### 样式

- *#privacy*
- *#privacy-item*
- *#privacy-item.screenshare*
- *#privacy-item.audio-in*
- *#privacy-item.audio-out*
