## 配置文件

配置使用 JSONC 文件格式，文件名为 `config` 或 `config.jsonc`。

该文件的有效目录为：
- `$XDG_CONFIG_HOME/waybar/`
- `~/.config/waybar/`
- `~/waybar/`
- `/etc/xdg/waybar/`
- `SYSCONFDIR/xdg/waybar`（如果构建时设置的 `SYSCONFDIR` 与 `/etc` 不同，例如 BSD 系统上的 `/usr/local/etc`）

[默认配置](https://github.com/Alexays/Waybar/blob/master/resources/config.jsonc)是一个很好的起点。

此外，可以在[本页底部](#minimal-config)找到一个最小示例配置。

所有模块的有效选项都列在[模块页面](https://github.com/Alexays/Waybar/wiki/Modules)上。

## 栏配置

| option           | typeof  | default      | description |
| ---------------- | ------- | -------------| ----------- |
| `layer`       | string | `bottom`            | 决定栏是显示在窗口前面（`top`）还是后面（`bottom`）。 |
| `output` | string\|array |               | 指定此栏将显示在哪个屏幕上。 |
| `position`         | string  | `top` | 栏的位置，可以是 `top`、`bottom`、`left`、`right`。 |
| `height`     | integer |              | 栏使用的高度（如果可能），留空则为动态值。 |
| `width`     | integer |              | 栏使用的宽度（如果可能），留空则为动态值。 |
| `modules-left`		   | array | 				| 将显示在左侧的模块。 |
| `modules-center`		   | array | 				| 将显示在中间的模块。 |
| `modules-right`		   | array | 				| 将显示在右侧的模块。 |
| `margin`         | string   |               | 使用 CSS 格式（不带单位）的边距值。 |
| `margin-<top\|left\|bottom\|right>`         | integer   |               | 不带单位的边距值。 |
| `spacing`         | integer    | `4` | 不同模块之间的间距大小。 |
| `name`         | string   |               | 作为 CSS 类添加的可选名称，用于为多个 waybar 设置样式。 |
| `mode`         | string   |               | 选择预配置的显示模式之一。这等同于 [`sway-bar(5)`](https://github.com/swaywm/sway/blob/master/sway/sway-bar.5.scd) 的 `mode` 命令，支持相同的值：`dock`、`hide`、`invisible`、`overlay`。<br />注意：`hide` 和 `invisible` 模式在没有 Sway IPC 的情况下可能不太有用。<br />注意：此选项会覆盖 `layer`、`exclusive` 和 `passthrough` 选项。 |
| `start_hidden`    | bool  | `false` | 启动时隐藏栏的选项。
| `modifier-reset`  | string  | `press` | 定义修饰键重置栏可见性的时机。要在按下修饰键时重置栏的可见性，请使用 `press`。使用 `release` 则在释放修饰键时重置可见性，且仅在按键期间没有执行其他操作时生效。这可以防止在使用修饰键切换工作区、更改绑定模式或启动快捷键绑定时隐藏栏。
| `exclusive`       | bool | `true` | 向合成器请求独占区域的选项。禁用此选项可允许在栏下方或上方绘制应用窗口。<br/>对于 `overlay` 层默认禁用。 |
| `fixed-center`    | bool | `true` | 优先为 `modules-center` 块使用固定的居中位置。只要可能，中间块将保持在栏的中央。如果其他块需要更多空间，它仍可能被推移。<br/>当设为 false 时，中间块居中于左块和右块之间的空间。 |
| `passthrough`     | bool | `false` | 将所有指针事件传递给栏下方窗口的选项。<br/>旨在与 `top` 或 `overlay` 层配合使用，且不使用独占区域。<br/>对于 `overlay` 层默认启用。 |
| `ipc`     |  bool | `false` | 订阅 Sway IPC 栏配置和可见性事件并使用 `swaymsg bar` 命令控制 waybar 的选项。<br />需要通过 `-b` 命令行参数传递或使用 `id` 选项指定 sway 配置中的 `bar_id` 值。<br />请参阅 [#1244](https://github.com/Alexays/Waybar/pull/1244) 获取文档和配置示例。 |
| `id`      | string|  | 用于 Sway IPC 的 `bar_id`。如果需要为特定栏实例覆盖通过 `-b bar_id` 命令行参数传递的值，请使用此选项。 |
| `include` | array |  | 附加配置文件的路径。<br/>每个文件可以包含一个具有任何栏配置选项的单一对象。如果选项重复，首先定义的值优先，即包含文件 -> 第一个被包含的文件 -> 等等。允许嵌套包含，但请确保避免循环导入。<br/>对于多栏配置，`include` 指令仅影响当前栏配置对象。 |
| `reload_style_on_change` | bool | `false` | 在样式表文件或任何导入的 CSS 文件检测到修改时重新加载 CSS 样式的选项。 |
| `on-sigusr1` | string | `toggle` | 接收到 SIGUSR1 kill 信号时执行的操作。可选值：`show`、`hide`、`toggle`、`reload`、`noop`。 |
| `on-sigusr2` | string | `reload` | 接收到 SIGUSR2 kill 信号时执行的操作。可选值：`show`、`hide`、`toggle`、`reload`、`noop`。 |

## 模块配置
建议不要为同一个鼠标按钮设置多个配置。
例如：定义了 `on-click`、`on-double-click`、`on-triple-click`。当触发三击时，模块将依次执行 `on-click`、`on-double-click`、`on-triple-click` 的命令，因为 Gdk 会提供这样的事件。

| option           | typeof  | default      | description |
| ---------------- | ------- | -------------| ----------- |
|`on-update` |string | | 模块更新时执行的命令|
|`on-click` |string | | 左键点击模块时执行的命令|
|`on-click-release` |string | | 在模块上释放左键时执行的命令|
|`on-double-click` |string | | 左键双击模块时执行的命令|
|`on-triple-click` |string | | 左键三击模块时执行的命令|
|`on-click-middle` |string | | 使用鼠标滚轮中键点击模块时执行的命令|
|`on-click-middle-release` |string | | 在模块上释放鼠标滚轮按钮时执行的命令|
|`on-double-click-middle` |string | | 使用鼠标滚轮中键双击模块时执行的命令|
|`on-triple-click-middle` |string | | 使用鼠标滚轮中键三击模块时执行的命令|
|`on-click-right` |string | | 右键点击模块时执行的命令|
|`on-click-right-release` |string | | 在模块上释放右键时执行的命令|
|`on-double-click-right` |string | | 右键双击模块时执行的命令|
|`on-triple-click-right` |string | | 右键三击模块时执行的命令|
|`on-click-backward` |string | | 使用鼠标后退按钮点击模块时执行的命令|
|`on-click-backward-release` |string | | 在模块上释放鼠标后退按钮时执行的命令|
|`on-double-click-backward` |string | | 使用鼠标后退按钮双击模块时执行的命令|
|`on-triple-click-backward` |string | | 使用鼠标后退按钮三击模块时执行的命令|
|`on-click-forward` |string | | 使用鼠标前进按钮点击模块时执行的命令|
|`on-click-forward-release` |string | | 在模块上释放鼠标前进按钮时执行的命令|
|`on-double-click-forward` |string | | 使用鼠标前进按钮双击模块时执行的命令|
|`on-triple-click-forward` |string | | 使用鼠标前进按钮三击模块时执行的命令|
|`on-scroll-up` |string | | 在模块上向上滚动鼠标滚轮时执行的命令|
|`on-scroll-down` |string | | 在模块上向下滚动鼠标滚轮时执行的命令|
|`on-scroll-left` |string | | 在模块上向左倾斜鼠标滚轮时执行的命令|
|`on-scroll-right` |string | | 在模块上向右倾斜鼠标滚轮时执行的命令|

## 模块操作配置
可以在 "actions" 块下指定模块操作（如果模块支持的话）。支持的操作在各模块定义页面中描述。
示例：
```json
"clock": {
    "actions": {"on-click-right": "mode",
                "on-scroll-up": "shift_up",
                "on-scroll-down": "shift_down"
               }
}
```

## 模块格式

你可以使用 [PangoMarkupFormat](https://docs.gtk.org/Pango/pango_markup.html#pango-markup)。
例如：
```jsonc
"format": "<span style=\"italic\">{}</span>"
```
如果你在模块格式中使用 Unicode，可能会遇到 Waybar 以错误方向显示信息的情况。这是 Unicode 规范导致的。某些连字可能具有"从右到左"的关联方向属性。请参阅 [Bidi 算法基础](https://www.w3.org/International/articles/inline-bidi-markup/uba-basics)。
```jsonc
"format": "{icon} {capacity}%",
"format-icons": ["ﱉ","ﱊ","ﱌ","ﱍ","ﱋ"]
```
可以通过使用特殊属性来处理。在示例中，{icon} 被从左到右属性包裹。
```jsonc
"format": "&#x202b;{icon}&#x202c; {capacity}%",
"format-icons": ["ﱉ","ﱊ","ﱌ","ﱍ","ﱋ"]
```


## 模块的多个实例

如果你想拥有同一模块的第二个实例，可以在其后添加 '#' 和自定义名称作为后缀。

例如，如果你想要第二个 battery 模块，可以将 `"battery#bat2"` 添加到你的模块中。

要配置新添加的模块，也需要添加同名的模块配置。

配置看起来可能像这样*（这是一个不完整的示例）*：
```jsonc
"modules-right": ["battery", "battery#bat2"],
"battery": {
    "bat": "BAT1"
},
"battery#bat2": {
    "bat": "BAT2"
}
```
在 ``style.css`` 中的样式设置：
```css
battery.bat2 {
    border-bottom: 2px solid #FFFFFF;
}
```

## 最小配置

一个最小的 `config` 文件可能如下所示：
```jsonc
{
    "layer": "top",
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["sway/window"],
    "modules-right": ["battery", "clock"],
    "sway/window": {
        "max-length": 50
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    "clock": {
        "format-alt": "{:%a, %d. %b  %H:%M}"
    }
}
```

## 多输出配置
### 将配置限制到某些输出
```jsonc
{
    "layer": "top",
    "output": "eDP-1",
    "modules-left": ["sway/workspaces", "sway/mode"],
    //...
}
```
```jsonc
{
    "layer": "top",
    "output": ["eDP-1", "VGA"],
    "modules-left": ["sway/workspaces", "sway/mode"],
    //...
}
```
### 多输出的配置
不指定输出即可在同一屏幕上创建多个栏
```jsonc
[{
    "layer": "top",
    "output": "eDP-1",
    "modules-left": ["sway/workspaces", "sway/mode"],
    //...
}, {
    "layer": "top",
    "output": "VGA",
    "modules-right": ["clock"],
    //...
}]
```
你也可以使用感叹号排除特定的输出，例如：
```jsonc
[{
    "layer": "top",
    "output": "eDP-1",
    "modules-left": ["sway/workspaces", "sway/mode"],
    //...
}, {
    "layer": "top",
    "output": "!eDP-1",
    "modules-right": ["clock"],
    //...
}]
```
这将在 eDP-1 上显示第一个栏，在除 eDP-1 之外的所有输出上显示第二个栏

### 旋转模块
当将 Waybar 放置在屏幕的左侧或右侧时，有时需要旋转模块内容使文本垂直显示。这可以通过模块的 "rotate" 属性来实现。示例：
```jsonc
{
    "clock": {
        "rotate": 90
    }
}
```
"rotate" 属性的有效值为：0、90、180 和 270。


### 在多个栏之间共享选项
你可能希望在多个栏中为重复的模块共享相同的格式和属性。将共享配置放在另一个文件中，例如 `default-modules.json`：
```jsonc
{
	"clock": {
		"tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
		"format": "{:%F %T}",
		"format-alt": "{:%F %T}",
		"interval": 1
	},

}
```
然后从 `config` 中导入它：
```jsonc
[{
	"layer": "top",
	"position": "bottom",
	"output": ["DP-1"],

	"include": [
		"~/.config/waybar/default-modules.json",
	],
	"modules-right": [
		"clock",
		"temperature",
	]
},
{
	"layer": "top",
	"position": "bottom",
	"output": ["HDMI-1"],

	"include": [
		"~/.config/waybar/default-modules.json",
	],
	"modules-right": [
		"clock",
	],

	"clock": {
		"on-click": "do_something",
	}
},
]
```

如你所见，你可以在默认值之上添加自定义属性。本地选项会追加到默认值中。如果已存在相同选项，则会覆盖默认值。

## 为多个栏设置样式
使用 "name" 字段，你可以在 style.css 文件中引用它，如下所示：
（config 文件）
```css
{
  "name": "bar1"
   // desired settings
} 
```
（config2 文件）
```css
{ 
 "name": "bar2"
 // desired settings
} 
``` 
在你的 style.css 中，可以这样引用：
```css
.bar1 { 
  font-family: Arimo Nerd Font;
  font-size: 16px;
} 
.bar2 {
  font-family: Roboto;
  font-size: 16px;
} 
```

如果你的栏共享相同的模块，可以这样指定：
```css
window.bar1#waybar { 
  background-color: rgba(10, 9, 10, 0.87);
} 

window.bar2#waybar {
  background-color: transparent;
} 
```
