- [Mode](#mode)
- [Window](#window)
- [Workspaces](#workspaces)
- [Scratchpad](#scratchpad)
- [Language](#language)

***

## Mode

`mode` 模块显示 [sway](https://swaywm.org/) 的当前绑定模式。

### 配置

通过 `sway/mode` 进行配置

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | 信息的显示格式。`{}` 处会插入数据。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `max-length`     | integer |         | 模块应显示的最大字符长度。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停时显示工具提示的选项。 |

#### 示例：
```jsonc
"sway/mode": {
    "format": " {}",
    "max-length": 50
}
```

### 样式

- `#mode`

## Window

`window` 模块显示 [sway](https://swaywm.org/) 中当前聚焦窗口的标题。

### 配置

通过 `sway/window` 进行配置

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{title}`    | 信息的显示格式。 |
| `rotate`         | integer | 	       | 正值用于旋转文本标签。 |
| `max-length`     | integer |         | 模块应显示的最大字符长度。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-right` | string  |         | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip`        | bool    | `true`  | 禁用悬停时显示工具提示的选项。 |
| `rewrite`        | object  | `{}`    | 重写模块格式输出的规则。参见**重写规则**。 |
| `all-outputs`    | bool    | `false` | 如果设置为 false，仅显示与栏相同输出上的窗口标题 |
| `offscreen-css`  | bool    | `false` | 仅在 all-outputs 为 true 时生效。根据未聚焦输出上的现有窗口添加样式，而不是显示聚焦窗口及其样式。 |
| `offscreen-css-text` | bool    |         | 仅在 all-outputs 和 offscreen-css 同时为 true 时生效。在当前未聚焦的屏幕上，显示给定的文本以及该工作区的样式。 |
| `icon`           | bool    | `false`  | 禁用应用程序图标的选项。 |
| `icon-size`           | integer    | `24`  | 设置应用程序图标的大小。 |

#### 格式替换：

| string     | replacement                       |
| ---------- | --------------------------------- |
| `{title}`  | 聚焦窗口的标题。  |
| `{app_id}` | 聚焦窗口的 app_id。 |
| `{shell}`  | 聚焦窗口的 shell。当窗口通过 xwayland 运行时为 'xwayland'，否则为 'xdg-shell'。 |

#### 重写规则：

`rewrite` 是一个对象，其中键为正则表达式，值为表达式匹配时的重写规则。规则中可以包含对表达式捕获组的引用。

正则表达式和替换遵循 [ECMAScript 规则](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Cheatsheet)（[正式定义](https://tc39.es/ecma262/#sec-regexp-regular-expression-objects)）。

表达式必须完全匹配才能触发替换；如果没有表达式匹配，格式输出将保持不变。

无效的表达式（例如，括号不匹配）将被忽略。

#### 示例 1：
```jsonc
"sway/window": {
    "format": "{title}",
    "max-length": 50,
    "rewrite": {
       "(.*) - Mozilla Firefox": "🌎 $1",
       "(.*) - vim": " $1",
       "(.*) - zsh": " [$1]"
    }
}
```
#### 示例 2：
```jsonc
"sway/window": {
    "format": "{}",
    "max-length": 50,
    "all-outputs" : true,
    "offscreen-css" : true,
    "offscreen-css-text": "(inactive)",
    "rewrite": {
        "(.*) - Mozilla Firefox": " $1",
        "(.*) - fish": "> [$1]"
    },
}
```

### 样式

- `#window`
- `window#waybar.empty` 当工作区中没有窗口，或屏幕未聚焦且未设置 `offscreen-css` 选项时
- `window#waybar.solo` 当工作区中只有一个平铺窗口时
- `window#waybar.floating` 当工作区中只有浮动窗口时
- `window#waybar.stacked` 当工作区中有多个窗口且工作区布局为堆叠模式时
- `window#waybar.tabbed` 当工作区中有多个窗口且工作区布局为标签页模式时
- `window#waybar.tiled` 当工作区中有多个窗口且工作区布局为 splith 或 splitv 时
- `window#waybar.<app_id>` 其中 `app_id` 是工作区中唯一窗口的 app_id 或 `instance` 名称（如 `chromium`）

请注意，window 模块将上面列出的额外 CSS 类应用于整个 waybar，而不是模块小部件。整个 waybar 是一个名为 "window"、id 为 "waybar" 的元素，而 window 模块本身是一个名为 "box"、id 为 "window" 的元素。因此在大多数情况下，你可能希望将格式应用于 `window#waybar.<stylename> #window`。要更好地了解 CSS 层级结构，请参考 [GTK_DEBUG](https://github.com/Alexays/Waybar/wiki/Styling#interactive-styling)。

此外，切换布局不会改变样式，除非焦点发生变化。目前 sway 不提供布局切换的事件，模块也不进行轮询。

#### 示例
```css
window#waybar {
  background-color: #990000;
}

window#waybar.empty {
  background-color: transparent;
}

window#waybar.empty #window {
  padding: 0px;
  margin: 0px;
  border: 0px;
/*  background-color: rgba(66,66,66,0.5); */ /* transparent */
  background-color: transparent;
}

window#waybar.solo #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background-color: #073642; /*base02*/
}

window#waybar.floating #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background-color: #b58900; /*yellow*/
}

window#waybar.tiled #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background-color: #cb4b16; /* orange */

}
window#waybar.stacked #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background: #2aa196; /*cyan*/
}
window#waybar.tabbed #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background: #859900; /*green*/
}

window#waybar.code {
    background-color: #007ACC;
}
```

## Workspaces

`workspaces` 模块显示 [sway](https://swaywm.org/) 中当前使用的工作区。

### 配置

通过 `sway/workspaces` 进行配置

| option           | typeof  | default  | description |
| ---------------- | ------- | -------- | ----------- |
| `all-outputs`    | bool    | `false`  | 如果设置为 `false`，工作区仅显示在其所在的输出上。<br>如果设置为 `true`，所有工作区将显示在每个输出上。 |
| `format`         | string  | `{name}` | 信息的显示格式。 |
| `format-icons`   | array   |          | 根据工作区名称和状态，选择对应的图标。<br>参见 [`Icons`](#module-workspaces-config-icons) |
| `disable-scroll` | bool    | `false`  | 如果设置为 `false`，你可以滚动来切换工作区。<br>如果设置为 `true`，此行为将被禁用。 |
| `disable-click` | bool    | `false`  | 如果设置为 `false`，你可以点击来切换工作区。<br>如果设置为 `true`，此行为将被禁用。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `disable-scroll-wraparound` | bool | `false` | 如果设置为 `false`，在工作区指示器上滚动到末尾时会循环到第一个工作区，反之亦然。<br>如果设置为 `true`，此行为将被禁用。 |
| `enable-bar-scroll` | bool | `false` | 如果设置为 `false`，你不能从整个栏通过滚动来切换工作区。<br>如果设置为 `true`，此行为将被启用。 |
| `disable-markup` | bool    | `false`  | 如果设置为 `true`，按钮标签将转义 pango 标记。 |
| `current-only` | bool | `false` | 如果设置为 `true`，仅显示聚焦的工作区。 |
| `persistent-workspaces` | json (see below) | empty | 列出应始终显示的工作区，即使它们不存在 |
| `numeric-first` | bool | `false` | 如果设置为 `true`，名称以数字开头的工作区将显示在不以数字开头的工作区前面。 |
| `disable-auto-back-and-forth` | bool | `false` | 是否在点击工作区时禁用 `workspace_auto_back_and_forth`。如果设置为 `true`，即使在 Sway 配置中启用了 `workspace_auto_back_and_forth`，点击你已在的工作区也不会执行任何操作。 |
| `warp-on-scroll` | bool | `true` | 如果设置为 `false`，waybar 将在使用滚轮切换工作区时临时禁用 mouse_warping（参见 `man 5 sway`） |
| `window-rewrite` | object | `{}` | 将窗口类映射到图标或工作区窗口首选表示方式的正则规则。 |
| `window-rewrite-default` | `string` | `?` | 工作区窗口的默认表示方式。对于类名不匹配 `window-rewrite` 中任何规则的窗口，将使用此值 |
| `format-window-separator` | `string` | ` ` | 工作区中窗口之间使用的分隔符。 |

#### 格式替换：

| string    | replacement |
| --------- | ----------- |
| `{value}`  | 工作区的名称，由 sway 定义 |
| `{name}`  | 从工作区值中以冒号分隔去除数字后的名称，例如 "13:NAME" |
| `{icon}`  | 图标，在 `format-icons` 中定义。 |
| `{index}` | 工作区的索引 |
| `{output}` | 工作区所在的输出。 |
| `{windows}` | window-rewrite 的结果 |

<a name="module-workspaces-config-icons"></a>

#### 图标：

除了工作区名称匹配外，还可以设置以下 `format-icons`。

| port name            | note |
| -------------------- | ---- |
| `default`            | 当没有找到字符串匹配时显示。 |
| `urgent`             | 当工作区被标记为紧急时显示 |
| `focused`            | 当工作区被聚焦时显示 |
| `persistent`         | 当工作区为持久工作区时显示。 |

如果你不希望这些额外图标覆盖某些工作区的已匹配图标，你可以将这些工作区列在 `high-priority-named` 列表中（如 `"high-priority-named": ["1", "2", "3"]`）

#### 持久工作区：
`persistent_workspace` 的每个条目命名一个应始终显示的工作区。与该值关联的是一个输出列表，指示工作区应在*哪里*显示，空列表表示所有输出
```jsonc
"sway/workspaces": {
    "persistent-workspaces": {
        "3": [], // Always show a workspace with name '3', on all outputs if it does not exists
        "4": ["eDP-1"], // Always show a workspace with name '4', on output 'eDP-1' if it does not exists
        "5": ["eDP-1", "DP-2"] // Always show a workspace with name '5', on outputs 'eDP-1' and 'DP-2' if it does not exists
    }
}
```
注：输出列表可以通过命令行使用 `swaymsg -t get_outputs` 获取


#### 示例：

```jsonc
"sway/workspaces": {
    "disable-scroll": true,
    "all-outputs": true,
    "format": "{name}: {icon}",
    "format-icons": {
        "1": "",
        "2": "",
        "3": "",
        "4": "",
        "5": "",
        "urgent": "",
        "focused": "",
        "default": "",
        "high-priority-named": ["1", "2"]
    }
}
```

```jsonc
"sway/workspaces": {
  "format": "<span size='larger'>{name}</span> {windows}",
  "format-window-separator": " | ",
  "window-rewrite-default": "{name}",
  "window-format": "<span color='#e0e0e0'>{name}</span>",
  "window-rewrite": {
    "class<firefox> title<.*chat.gig.tech.*>": "",
    "class<kitty>": "",
  }
}
```

### 样式

- `#workspaces button`
- `#workspaces button.visible`
- `#workspaces button.focused`
- `#workspaces button.urgent`
- `#workspaces button.persistent`
- `#workspaces button.empty`
- `#workspaces button.current_output`
- `#workspaces button#sway-workspace-${name}`  


## Scratchpad

`scratchpad` 模块显示 Sway 中的暂存区状态。

### 配置

通过 `sway/scratchpad` 进行配置

| option           | typeof | default | description |
| ---------------- | ------ | ------- | ----------- |
| `format`         | string | `{icon} {count}` | 信息的显示格式。 |
| `show-empty`     | bool   | `false`| 暂存区为空时显示模块的选项。 |
| `format-icons`   | array/object |  | 根据当前暂存区窗口数量，选择对应的图标。 |
| `tooltip`        | bool   | `true` | 禁用悬停时显示工具提示的选项。 |
| `tooltip-format` | string | `{app}: {title}` | 工具提示中信息的显示格式。 |
| `menu`           | string |        | 弹出菜单的操作。 |
| `menu-file`      | string |        | 菜单描述文件的位置。需要一个 id 为 `menu` 的 GtkMenu 类型元素 |
| `menu-actions`   | array  |        | 与菜单按钮对应的操作。 |

#### 格式替换

| string    | replacement |
| --------- | ----------- |
| `{icon}`  | 图标，在 `format-icons` 中定义。         |
| `{count}` | 暂存区中的窗口数量。        |
| `{app}`   | 暂存区中应用程序的名称。  |
| `{title}` | 暂存区中应用程序的标题。 |

#### 示例

```json
"sway/scratchpad": {
    "format": "{icon} {count}",
    "show-empty": false,
    "format-icons": ["", ""],
    "tooltip": true,
    "tooltip-format": "{app}: {title}"
}
```

### 样式

- `#scratchpad`
- `#scratchpad.empty`

## Language
[sway/language](https://github.com/Alexays/Waybar/wiki/Module:-Language)