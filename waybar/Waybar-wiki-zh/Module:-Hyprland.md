- [工作区](#workspaces)
- [窗口](#window)
- [窗口计数](#window-count)
- [语言](#language)
- [子映射](#submap)

***

## 工作区

`workspaces` 模块显示 hyprland 合成器中当前使用的工作区。

### 配置

通过 `hyprland/workspaces` 引用

| option             | typeof  | default | description |
| ------------------ | ------- | ------- | ----------- |
| `active-only`      | bool    | `false` | 如果设置为 true，则仅在栏上显示活动工作区。除非工作区是持久的、可见的或特殊的。否则显示所有工作区组。|
| `hide-active`      | bool    | `false` | 如果设置为 true，则隐藏活动工作区。除非工作区是持久的或特殊的。 |
| `all-outputs`      | bool    | `false` | 如果设置为 false，工作区组仅在分配的输出上显示。否则显示所有工作区组。|
| `format`           | string  | `{id}`    | 信息的显示格式。|
| `format-icons`   | object   |          | 根据工作区名称和状态，选择对应的图标。<br>参见 [`Icons`](#module-hyprland-configuration-icons)|
| `persistent-workspaces` | object |    | 列出应始终显示的工作区，即使它们不存在。<br>参见 [`持久工作区`](#persistent-workspaces) |
| `workspace-taskbar` | object |    | 显示带有应用图标的按工作区分组的任务栏（类似于 `wlr/taskbar`），而非文本表示。<br>参见 [`工作区任务栏`](#workspace-taskbars) |
| `persistent-only` | bool | `false` | 如果设置为 true，则仅在栏上显示持久工作区。 |
| `show-special`     | bool    | `false` | 如果设置为 true，将在常规工作区旁边显示特殊工作区。|
| `special-visible-only`     | bool    | `false` | 如果此选项和 show-special 都设置为 true，则特殊工作区仅在可见时才显示。|
| `sort-by` | string | `DEFAULT` | 工作区的排序方式。 |
| `window-rewrite` | object (see [example](#module-hyprland-window-rewrite-example)) | empty | 用于匹配窗口类（和/或标题，[见下文](#module-hyprland-window-rewrite)）并映射到新表示的正则表达式对象。例如，将 `firefox` 映射为 ` `。
| `window-rewrite-default` | string | `?` | 当窗口不匹配 `window-rewrite` 中配置的任何规则时使用的默认表示。
| `format-window-separator` | string | `<space>` | 用于分隔窗口表示的字符串。
| `move-to-monitor` | bool | `false` | 如果设置为 true，点击工作区按钮时将在当前显示器上打开工作区。否则，工作区将在之前分配的显示器上打开。类似于在 Hyprland 中使用 `focusworkspaceoncurrentmonitor` 调度器替代 `workspace`。
| `ignore-workspaces` | array | empty | 用于匹配工作区名称的正则表达式数组。如果匹配，该工作区将被忽略且不会显示在栏上。
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |

#### 格式替换：
| string | replacement |
|--------|-------------|
| `{icon}` | 图标，在 *format-icons* 中定义。 |
| `{name}` | 合成器分配的工作区名称。 |
| `{windows}` | 所有窗口表示（如窗口图标），按用户配置的分隔符分隔。 |

<a name="module-hyprland-window-rewrite"></a>

#### 窗口重写规则

这些规则是正则表达式，可以匹配类、标题或两者，以便精细调整窗口表示。为了理解它们，让我们将可能的规则分为 4 类：

| How it appears in config | Category |
| --- | --- |
| `something` | 模糊匹配 |
| `class<something>` | 仅匹配类 |
| `title<something>` | 仅匹配标题 |
| `class<something1> title<something2>` | 混合匹配 |

当用户配置中仅包含"模糊"规则时，它们将用于匹配窗口的**类**。这是出于向后兼容性和性能的考虑：此功能最初仅支持类，因为它们*通常*在程序的生命周期内不会改变。当引入标题配置后，将先前存在的规则同时匹配类和标题会导致大量"错误"匹配，因此默认情况下是禁用的。此外，匹配标题需要通过 Hyprland 的 IPC 监听窗口标题变化，在不使用时这是不必要的。

当配置中包含**至少一个**"仅匹配标题"或"混合匹配"重写规则时，所有"模糊"规则将同时匹配**类和标题**。虽然初看之下可能令人困惑，但这样做是为了允许用户定义模糊规则，无论匹配的是类还是标题都无所谓。

使用所有 4 种类别的示例请见[下方](#module-hyprland-window-rewrite-example)。

<a name="module-hyprland-configuration-icons"></a>

#### 图标：

除了工作区名称匹配外，还可以设置以下 `format-icons`。

| port name    | note |
| ------------ | ---- |
| `active`     | 当工作区处于活动状态时显示 |
| `default`    | 当没有找到匹配的字符串时显示。 |
| `empty` | 在活动的空工作区上显示 |
| `persistent` | 在非活动的持久工作区上显示 |
| `special`    | 在非活动的特殊工作区上显示 |
| `urgent`    | 在非活动的紧急工作区上显示 |

#### 排序：

工作区的排序方式。

| name    | note |
| ------------ | ---- |
| `default`    | 默认的 hyprland/workspaces 排序算法，带有自定义优先级 |
| `id` | 按 id 排序工作区 |
| `name` | 按名称排序工作区 |
| `number`     | 按编号排序工作区 |
| `special-centered` | 默认排序，特殊工作区居中 |

<a name="module-hyprland-window-rewrite-example"></a>

#### 窗口重写示例

```jsonc
"hyprland/workspaces": {
  "format": "<sub>{icon}</sub>\n{windows}",
  "format-window-separator": "\n",
  "window-rewrite-default": "",
  "window-rewrite": {
    "title<.*youtube.*>": "", // Windows whose titles contain "youtube"
    "class<firefox>": "", // Windows whose classes are "firefox"
    "class<firefox> title<.*github.*>": "", // Windows whose class is "firefox" and title contains "github". Note that "class" always comes first.
    "foot": "", // Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
    "code": "󰨞",
	},
  ...
}
```

<details>

<summary>截图</summary>

![](https://user-images.githubusercontent.com/25804378/270065881-acef7b73-e528-4648-82c1-ba70ea9f7804.png)


</details>

#### 持久工作区：
`persistent-workspace` 的每个条目命名一个应始终显示的工作区。与该值关联的是一个输出列表，表示工作区应在*哪里*显示，空列表表示所有输出。

> [!WARNING]
> 你必须在 Hyprland 配置中明确设置 `workspace = <num>, monitor:<monitor>, persistent:true` 才能实际生效<br>
> 以下是设置示例
> ```py
> # ... parts of config
>   workspace = 1, monitor:eDP-1, persistent:true
>   workspace = 2, monitor:eDP-1, persistent:true
>   workspace = 3, monitor:eDP-1, persistent:true
>   workspace = 4, monitor:eDP-1, persistent:true
> # ... another parts of config
> ```
```jsonc
"hyprland/workspaces": {
    "persistent-workspaces": {
             "*": 5, // 5 workspaces by default on every monitor
             "HDMI-A-1": 3 // but only three on HDMI-A-1
       }
}
```

```jsonc
"hyprland/workspaces": {
    "persistent-workspaces": {
      "1": [
        "DP-3" // workspace 1 shown on DP-3
      ],
      "2": [
        "DP-1" // workspace 2 shown on DP-1
      ],
      "3": [
        "DP-1" // workspace 3 shown on DP-1
      ],
    }
}
```

```jsonc
"hyprland/workspaces": {
   "persistent-workspaces": {
      "DP-3": [ 1 ], // workspace 1 shown on DP-3
      "DP-1": [ 2, 3 ], // workspaces 2 and 3 shown on DP-1
    }
}
```

#### 持久工作区示例

```jsonc
"hyprland/workspaces": {
	"format": "{name}: {icon}",
	"format-icons": {
		"1": "",
		"2": "",
		"3": "",
		"4": "",
		"5": "",
		"active": "",
		"default": ""
	},
       "persistent-workspaces": {
             "*": 5, // 5 workspaces by default on every monitor
             "HDMI-A-1": 3 // but only three on HDMI-A-1
       }
}
```

#### 工作区任务栏：

从 Waybar 0.14 开始，你可以使 `hyprland/workspaces` 的行为类似于 `wlr/taskbar`，其中窗口图标按工作区分组。

```jsonc
"hyprland/workspaces": {
    "workspace-taskbar": {
        // Enable the workspace taskbar. Default: false
        "enable": true,

        // If true, the active/focused window will have an 'active' class. Could cause higher CPU usage due to more frequent redraws. Default: false
        "update-active-window": true,

        // Format of the windows in the taskbar. Default: "{icon}". Allowed variables: {icon}, {title}
        "format": "{icon} {title:.20}",

        // Icon size in pixels. Default: 16
        "icon-size": 16,

        // Either the name of an installed icon theme or an array of themes (ordered by priority). If not set, the default icon theme is used.
        "icon-theme": "some_icon_theme",

        // Orientation of the taskbar ("horizontal" or "vertical"). Default: "horizontal".
        "orientation": "horizontal",

        // List of regexes. A window will NOT be shown if its window class or title match one or more items. Default: []
        "ignore-list": [ "code", "Firefox - .*" ],

        // Command to run when a window is clicked. Default: "" (switch to the workspace as usual). Allowed variables: {address}, {button}
        "on-click-window": "/some/arbitrary/script {address} {button}"
    }
}
```

如果 `workspace-taskbar.enable` 设置为 `false`（或未定义），则 `workspace-taskbar` 对象中的其他字段将被忽略。如果设置为 `true`，则以下字段将被忽略：`window-rewrite`、`window-rewrite-default`。

你可以使用 `on-click-window` 配置来设置点击特定窗口时执行的命令。例如：`hyprctl dispatch focuswindow address:{address}`。
- `{address}` 模式将被替换为被点击窗口的 Hyprland 地址。
- `{button}` 模式将被替换为按下的按钮编号。参见 [GdkEventButton.button](https://api.gtkd.org/gdk.c.types.GdkEventButton.button.html)。

#### 工作区任务栏示例：

![Workspace taskbars example](https://github.com/user-attachments/assets/c5387d8b-6612-442a-83af-2a0d881fa6db)

```jsonc
"hyprland/workspaces": {
    "format": "{icon}: {windows}",
    "format-window-separator": "",
    "workspace-taskbar": {
        "enable": true,
        "update-active-window": true,
        "format": "{icon} {title:.22}",
        "icon-size": 18,
        "on-click-window": "${SCRIPTS}/focus-window.sh {address} {button}"
    }
},
```

<details>

<summary>查看 CSS</summary>

```css
#workspaces button {
    font-family: "Cantarell";
    font-weight: bold;
    background-color: transparent;
    color: #ffffff;
    box-shadow: none;
    text-shadow: none;
    padding: 0px;
    border-radius: 0;
    padding-left: 5px;
    padding-right: 2px;
}

#workspaces .workspace-label {
    padding-left: 3px;
    border-top: 1px solid transparent;
}

#workspaces .taskbar-window {
    border-top: 1px solid transparent;
    font-weight: normal;
    padding-left: 5px;
    padding-right: 5px;
}

#workspaces button.visible .taskbar-window,
#workspaces button.visible .workspace-label {
    border-color: white;
}

#workspaces .taskbar-window.active {
    background-color: rgba(255, 255, 255, 0.15);
}

#workspaces .taskbar-window image {
    margin-top: 1px;
}

#workspaces button.urgent {
    background-color: @urgent-color;
}
```

</details>

<details>

<summary>查看 focus-window.sh</summary>

```sh
#!/bin/sh

address=$1

# https://api.gtkd.org/gdk.c.types.GdkEventButton.button.html
button=$2

if [ $button -eq 1 ]; then
    # Left click: focus window
    hyprctl keyword cursor:no_warps true
    hyprctl dispatch focuswindow address:$address
    hyprctl keyword cursor:no_warps false
elif [ $button -eq 2 ]; then
    # Middle click: close window
    hyprctl dispatch closewindow address:$address
fi
```

</details>

### 样式

- *#workspaces*
- *#workspaces button*
- *#workspaces button.active*
- *#workspaces button.empty*
- *#workspaces button.persistent*
- *#workspaces button.special*
- *#workspaces button.visible*
- *#workspaces button.urgent*
- *#workspaces button.hosting-monitor*
  - 当 workspace-monitor == waybar-monitor 时应用
- *#workspaces .workspace-label*
- *#workspaces .taskbar-window*
  - 仅当 `workspace-taskbar.enable` 为 `true` 时
- *#workspaces .taskbar-window.active*
  - 当窗口处于聚焦状态时应用
  - 仅当 `workspace-taskbar.enable` 和 `workspace-taskbar.update-active-window` 都为 `true` 时


#### CSS 的评估方式要求你按重要性顺序排列，最后的优先级最高。

#### 示例：

此顺序使特殊情况的样式优先级高于常规样式。如果你想将 persistent 包含在内，我建议将其放在 empty 之前。

![image](https://github.com/Alexays/Waybar/assets/1778670/6421e9ce-50be-4086-8045-688338d5fbe7)

活动显示器：
活动工作区显示绿色图标。
![image](https://github.com/Alexays/Waybar/assets/1778670/48c58198-aae4-42ac-802a-33b1e3db5e33)

非活动显示器：
可见但非活动的工作区显示蓝色图标。


***

## 窗口

`window` 模块显示 Wayland 合成器 [Hyprland](https://github.com/hyprwm/Hyprland) 中当前聚焦窗口的标题。

### 配置

通过 `hyprland/window` 引用

| option             | typeof  | default | description |
| ------------------ | ------- | ------- | ----------- |
| `format`           | string  | `{title}`    | 信息的显示格式。`{}` 处显示当前窗口标题。|
| `max-length`       | integer |         | 模块应显示的最大字符长度。 |
| `rewrite`          | object  | `{}`    | 用于重写模块格式输出的规则。规则与 [`sway/window` 的规则](https://github.com/Alexays/Waybar/wiki/Module:-Sway#rewrite-rules)相同。 |
| `separate-outputs` | bool    | `false`   | 显示栏所属显示器的活动窗口，而非聚焦窗口。 |
| `icon`             | bool    | `false`   | 禁用应用程序图标的选项。|
| `icon-size`        | integer | `24`      | 设置应用程序图标的大小。|

#### 格式替换：
参见 "hyprctl clients" 的输出了解示例

| string           | replacement                              |
| ---------------- | ---------------------------------------- |
| `{class}`        | 聚焦窗口的当前类。 |
| `{initialClass}` | 聚焦窗口的初始类。 |
| `{initialTitle}` | 聚焦窗口的初始标题。 |
| `{title}`        | 聚焦窗口的当前标题。 |

#### 示例：

```json
"hyprland/window": {
    "format": "👉 {}",
    "rewrite": {
        "(.*) — Mozilla Firefox": "🌎 $1",
        "(.*) - fish": "> [$1]"
    },
    "separate-outputs": true
}
```

### 样式

- `#window`

以下类可以将样式应用于*整个 Waybar*（详见 [Sway 模块页面](https://github.com/Alexays/Waybar/wiki/Module:-Sway#style-1)）：
- `window#waybar.empty` 当工作区中没有窗口时
- `window#waybar.solo` 当工作区中有一个可见的平铺窗口时（可能存在浮动窗口）
- `window#waybar.<app_id>` 其中 `<app_id>` 是工作区中唯一平铺窗口的类（例如 `chromium`）（使用 *hyprctl clients* 查看类）
- `window#waybar.floating` 当工作区中只有浮动窗口可见时
- `window#waybar.fullscreen` 当工作区中有全屏窗口时；适用于 Hyprland 的 `fullscreen, 1` 模式
- `window#waybar.swallowing` 当工作区中有隐藏窗口时；通常由窗口吞噬引起

#### 示例：

这将在 Chromium 或 kitty 占据屏幕时改变整个栏的颜色。
```css
#window {
    border-radius: 20px;
    padding-left: 10px;
    padding-right: 10px;
}

window#waybar.kitty {
    background-color: #111111;
    color: #ffffff;
}

window#waybar.chromium {
    background-color: #eeeeee;
    color: #000000;
}

/* make window module transparent when no windows present */
window#waybar.empty #window {
    background-color: transparent;
}
```

***

## 窗口计数

`windowcount` 模块显示当前 [Hyprland](https://github.com/hyprwm/Hyprland) 工作区中的窗口数量。

### 配置

通过 `hyprland/windowcount` 引用。

| option              | typeof | default | description                                                                                                 |
| ------------------- | ------ | ------- | ----------------------------------------------------------------------------------------------------------- |
| `format`            | string | `{}`    | 信息的显示格式。`{}` 处显示当前工作区的窗口数量。 |
| `format-empty`      | string |         | 当工作区中没有窗口时覆盖默认格式。                                                 |
| `format-windowed`   | string |         | 当工作区中没有全屏窗口时覆盖默认格式。                                      |
| `format-fullscreen` | string |         | 当工作区中有全屏窗口时覆盖默认格式。                                        |
| `separate-outputs`  | bool   | `true`  | 显示栏所属显示器的活动工作区窗口数量，而非聚焦工作区的窗口数量。 |

#### 示例：

```jsonc
"hyprland/windowcount": {
    "format": "[{}]",
    "format-empty": "[X]",
    "format-windowed": "[T]",
    // "format-fullscreen": "[{}]",
    "separate-outputs": true
}
```

### 样式

- `#windowcount`
- `window#waybar.empty #windowcount` 当工作区中没有窗口时
- `window#waybar.fullscreen #windowcount` 当工作区中有全屏窗口时；适用于 Hyprland 的 fullscreen, 1 模式

#### 示例：

```css
/* Adding margin and padding */
#windowcount {
    margin-left: 0px;
    padding: 0px 5px;
}

/* Different background when empty */
window#waybar.empty #windowcount {
    background: darkred;
}

/* Hide the windowcount module when not in windowed mode (i.e. not fullscreen) */
window#waybar:not(.fullscreen) #windowcount {
    opacity: 0;
}
```

*** 

## 语言

`language` 模块显示 Wayland 合成器 [Hyprland](https://github.com/hyprwm/Hyprland) 中当前选择的键盘语言（布局）。

### 配置

通过 `hyprland/language` 引用

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | 信息的显示格式。`{}` 处显示当前布局的全名。|
| `format-<lang>`  | string  |         | 为每种语言提供替代显示名称，其中 <lang> 是你选择的语言。可以如下方示例所示传递多个不同语言的参数。| 
| `keyboard-name`  | string  |         | 使用哪个键盘，来自 `hyprctl devices` 的输出。你应该使用以 "at-translated-set..." 开头的选项。|


#### 示例：

```json
"hyprland/language": {
    "format": "Lang: {}",
    "format-en": "AMERICA, HELL YEAH!",
    "format-en-colemak_dh": "AMERICA (Colemak-DH), HELL YEAH",
    "format-tr": "As bayrakları",
    "keyboard-name": "at-translated-set-2-keyboard"
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

***

## 子映射

`submap` 模块显示当前活动的子映射，类似于 Wayland 合成器 [Hyprland](https://github.com/hyprwm/Hyprland) 中的 *sway/mode*。

### 配置

通过 `hyprland/submap` 引用

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | 信息的显示格式。`{}` 处显示当前活动的子映射。 |
| `max-length`     | integer |         | 模块应显示的最大字符长度。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停提示的选项。 |
| `always-on` | bool  | `false`              | 即使没有活动的子映射也显示组件的选项。 |
| `default-submap` | string  | `Default`              | 没有活动子映射时显示的默认子映射名称。 |


#### 示例：
```json
"hyprland/submap": {
    "format": "✌️ {}",
    "max-length": 8,
    "tooltip": false
}
```

### 样式

- *#submap*
- *#submap.\<name\>*
