这些模块需要 niri >= 0.1.9。

- [工作区](#workspaces)
- [窗口](#window)
- [语言](#language)

***

## 工作区

`workspaces` 模块显示 niri 中当前使用的工作区。

### 配置

通过 `niri/workspaces` 进行配置

| option             | typeof  | default | description |
| ------------------ | ------- | ------- | ----------- |
| `all-outputs`      | bool    | `false` | 如果设置为 false，工作区仅在其所在的输出上显示。如果设置为 true，所有工作区将在每个输出上显示。|
| `format`           | string  | `{value}`    | 信息的显示格式。|
| `format-icons`   | object   |          | 根据工作区名称和状态选择对应的图标。<br>参见 [`Icons`](#module-niri-configuration-icons)|
| `disable-click` | bool | `false` | 如果设置为 false，可以点击切换工作区。如果设置为 true，则禁用此行为。 |
| `disable-markup` | bool | `false` | 如果设置为 true，按钮标签将转义 pango 标记。 |
| `current-only` | bool | `false` | 如果设置为 true，仅显示活动或聚焦的工作区。 |
| `on-update` | string | | 模块更新时执行的命令。 |

#### 格式替换符：

| string | replacement |
|--------|-------------|
| `{value}` | 工作区的名称，对于未命名的工作区则为索引，由 niri 定义。 |
| `{name}` | 已命名工作区的名称。 |
| `{icon}` | 图标，在 *format-icons* 中定义。 |
| `{index}` | 工作区在其输出上的索引。 |
| `{output}` | 工作区所在的输出。 |

<a name="module-niri-configuration-icons"></a>

#### 图标：

除了工作区名称匹配外，还可以设置以下 `format-icons`。

| port name    | note |
| ------------ | ---- |
| `default`    | 当没有找到匹配的字符串时显示。 |
| `focused`    | 当工作区处于聚焦状态时显示。 |
| `active`     | 当工作区在其输出上处于活动状态时显示。 |

#### 示例：

```jsonc
"niri/workspaces": {
	"format": "{icon}",
	"format-icons": {
		// Named workspaces
		// (you need to configure them in niri)
		"browser": "",
		"discord": "",
		"chat": "<b></b>",

		// Icons by state
		"active": "",
		"default": ""
	}
}
```

### 样式

- `#workspaces`
- `#workspaces button`
- `#workspaces button.focused` 单个聚焦的工作区。
- `#workspaces button.active` 工作区在其输出上处于活动（可见）状态。
- `#workspaces button.empty` 工作区为空。
- `#workspaces button.current_output` 工作区与显示它的栏在同一输出上。
- `#workspaces button#niri-workspace-<name>` 以此命名的工作区，未命名工作区则为索引。

#### CSS 的评估方式要求您按重要性排序，最后出现的优先级最高。

***

## 窗口

`window` 模块显示 niri 中当前聚焦窗口的标题。

### 配置

通过 `niri/window` 进行配置

| option             | typeof  | default | description |
| ------------------ | ------- | ------- | ----------- |
| `format`           | string  | `{title}`    | 信息的显示格式。`{}` 会显示当前窗口标题。|
| `rewrite`          | object  | `{}`    | 重写模块格式输出的规则。规则与 [`sway/window` 的规则](https://github.com/Alexays/Waybar/wiki/Module:-Sway#rewrite-rules)相同。 |
| `separate-outputs` | bool    | `false`   | 显示栏所在显示器的活动窗口，而不是聚焦的窗口。 |
| `icon`             | bool    | `false`   | 禁用应用程序图标的选项。|
| `icon-size`        | integer | `24`      | 设置应用程序图标的大小。|

#### 格式替换符：

参见 `niri msg windows` 的输出获取示例。

| string           | replacement                              |
| ---------------- | ---------------------------------------- |
| `{title}`        | 当前聚焦窗口的标题。 |
| `{app_id}`       | 当前聚焦窗口的 app ID。|

#### 示例：

```json
"niri/window": {
	"format": "{}",
	"rewrite": {
		"(.*) - Mozilla Firefox": "🌎 $1",
		"(.*) - zsh": "> [$1]"
	}
}
```

### 样式

- `#window`

以下类可以为*整个 Waybar* 应用样式（更多信息参见 [Sway 模块页面](https://github.com/Alexays/Waybar/wiki/Module:-Sway#style-1)）：
- `window#waybar.empty` 当工作区中没有窗口时
- `window#waybar.solo` 当工作区中只有一个平铺窗口可见时（可能存在浮动窗口）
- `window#waybar.<app_id>` 其中 `<app_id>` 是工作区中唯一窗口的 app ID（例如 `neovide`）（使用 `niri msg windows` 查看 app ID）。

#### 示例：

当 Alacritty 或 Chromium 占据屏幕时，这将改变整个栏的颜色。
```css
#window {
    border-radius: 20px;
    padding-left: 10px;
    padding-right: 10px;
}

window#waybar.Alacritty {
    background-color: #111111;
    color: #ffffff;
}

window#waybar.chromium-browser {
    background-color: #eeeeee;
    color: #000000;
}

/* make window module transparent when no windows present */
window#waybar.empty #window {
    background-color: transparent;
}
```

*** 

## 语言

`language` 模块显示 niri 中当前选择的键盘语言（布局）。

### 配置

通过 `niri/language` 进行配置

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | 信息的显示格式。`{}` 会显示当前布局的完整名称。|
| `format-<lang>`  | string  |         | 为每种语言提供替代显示名称，其中 <lang> 是您选择的语言。可以多次传递多种语言，如下方示例所示。|


#### 示例：

```json
"niri/language": {
	"format": "Lang: {long}",
	"format-en": "AMERICA, HELL YEAH!",
	"format-tr": "As bayrakları"
}
```

### 样式

- *#language*

#### 示例：

```css
#language {
    border-radius: 20px;
    padding-left: 10px;
    padding-right: 10px;
}
```
