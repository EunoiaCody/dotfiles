模块分组允许在与栏方向正交的方向上堆叠模块。当栏位于屏幕顶部或底部时，分组中的模块垂直堆叠。同样，当栏位于左侧或右侧时，分组中的模块水平堆叠。

### 配置
通过 `group/<name>` 引用

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `orientation`    | string  |`"orthogonal"`| 设置分组的方向。有效选项为：`"horizontal"`、`"vertical"`、`"inherit"` 和 `"orthogonal"`。 |
|`modules`|array||分组中包含的模块列表。|
|`drawer`|object||如果留空，则禁用抽屉。否则，启用抽屉并提供一些额外的配置选项。详见[抽屉](#drawer)。

<a name="drawer"></a>

### 抽屉

抽屉配置使分组默认仅显示第一个模块，其余模块在鼠标悬停于分组上时才显示。查看 GIF 以了解其交互效果示例。

<img src="https://github.com/Alexays/Waybar/assets/25804378/66139544-b075-4b49-85fb-ebba6dcf0556" height="200">

<details>

<summary>GIF 中使用的配置</summary>

```jsonc
"group/group-power": {
    "orientation": "inherit",
    "drawer": {
        "transition-duration": 500,
        "children-class": "not-power",
        "transition-left-to-right": false,
    },
    "modules": [
        "custom/power", // First element is the "group leader" and won't ever be hidden
        "custom/quit",
        "custom/lock",
        "custom/reboot",
    ]
},
"custom/quit": {
    "format": "󰗼",
    "tooltip": false,
    "on-click": "hyprctl dispatch exit"
},
"custom/lock": {
    "format": "󰍁",
    "tooltip": false,
    "on-click": "swaylock"
},
"custom/reboot": {
    "format": "󰜉",
    "tooltip": false,
    "on-click": "reboot"
},
"custom/power": {
    "format": "",
    "tooltip": false,
    "on-click": "shutdown now"
}
```

</details>

当抽屉启用时，分组的第一个模块被选为"分组领导者"，其余元素为"抽屉子项"。"分组领导者"始终显示，悬停时会展开显示"抽屉子项"。

#### 抽屉配置

| option | typeof | default | description |
| --- | --- | --- | --- |
| `transition-duration` | int | 500 | 过渡动画的持续时间，单位为毫秒。 |
| `transition-left-to-right` | bool | `true` | 过渡方向是从左到右还是从右到左。如果分组是垂直的，则此配置解读为"从上到下"。 |
| `children-class` | string | `"drawer-child"` | 添加到抽屉子项（不包括"分组领导者"）的 CSS 类。其目的仅是辅助样式设置。 |
|`click-to-reveal`|bool|false|允许通过点击而非鼠标悬停来展开隐藏的模块。|

### 样式

要为分组设置样式，请使用分组的 ID。

### 示例
```
{
	"modules-right": ["group/hardware", "clock"],

	"group/hardware": {
		"orientation": "vertical",
		"modules": [
			"cpu",
			"memory",
			"battery"
		]
	},

	...
}
```
```
#hardware {
    background-color: #333333;
}
```
