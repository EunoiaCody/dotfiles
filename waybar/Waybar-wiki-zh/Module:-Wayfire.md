## 模块：Wayfire

- [工作区](#workspaces)
- [窗口](#window)

---

## 工作区

`workspaces` 模块显示 Wayfire 中当前使用的工作区。

### 配置

通过 `wayfire/workspaces` 进行配置

| Option | Type | Default | Description |
| ---------------- | ------ | --------- | ------------------------------------------------------------------------- |
| `format`         | string | `{value}` | 定义信息显示方式的格式                      |
| `format-icons`   | array  |           | 根据工作区名称、索引和状态选择图标（参见**图标**） |
| `disable-click`  | bool   | `false`   | 如果为 `true`，则禁用点击切换工作区                      |
| `disable-markup` | bool   | `false`   | 如果为 `true`，按钮标签将转义 Pango 标记                         |
| `current-only`   | bool   | `false`   | 如果为 `true`，仅显示活动或聚焦的工作区                  |
| `on-update`      | string |           | 模块更新时执行的命令                                |
| `expand`         | bool   | `false`   | 允许模块动态占用剩余空间                   |


### 格式替换

| String | Replacements |
|------------|-------------|
| `{icon}`   | 图标，如 *format-icons* 中定义的。 |
| `{index}`  | 工作区在其输出上的索引。 |
| `{output}` | 工作区所在的输出。 |

### 图标
除了工作区名称匹配外，还可以设置以下 format-icons。

|port | note |
|-----------|--------------|
| `default` | 在没有找到匹配的字符串时显示。 |
| `focused` | 在工作区被聚焦时显示。 |

### 示例

```jsonc
"wayfire/workspaces": {
  "format": "{icon}",
  "format-icons": {
    "1": "",
    "2": "",
    "3": "",
    "4": "",
    "5": "",
    "focused": "",
    "default": ""
  }
}
```

### 样式
- *#workspaces button*
- *#workspaces button.focused*   
- *#workspaces button.empty*    
- *#workspaces button.current_output*

---

## 窗口

### 描述

**window** 模块显示 **Wayfire** 中当前聚焦窗口的标题。

### 配置

**模块名称：** `wayfire/window`

### 选项

| Option | Type | Default | Description |
|-------------|---------|-----------|-------------|
| `format`    | string  | `{title}` | 信息的显示格式。使用 {} 时显示当前窗口标题。 |
| `rewrite`   | object  | —         | 用于重写窗口标题的规则。参见[重写规则](#rewrite-rules)。 |
| `icon`      | bool    | `false`   | 显示或隐藏应用程序图标。 |
| `icon-size` | integer | `24`      | 更改应用程序图标大小的选项。 |
| `expand`    | bool    | `false`   | 启用此模块以动态占用所有剩余空间。 |

### 格式替换

|string       |	replacement |
|-------------|--------------|
|{title}:     | 聚焦窗口的当前标题。|
|{app_id}:    | 聚焦窗口的当前应用 ID。 |

### 重写规则
rewrite 是一个对象，其中键是正则表达式，值是表达式匹配时的重写规则。规则可以包含对表达式捕获组的引用。

正则表达式和替换遵循 ECMA-script 规则。<br>

如果没有表达式匹配，标题将保持不变。<br>

无效的表达式（例如，不匹配的括号）将被跳过。

##示例

```
"wayfire/window": {
	"format": "{}",
	"rewrite": {
		"(.*) - Mozilla Firefox": "🌎 $1",
		"(.*) - zsh": "> [$1]"
	}
}
```

### 样式
- *#window*
- *#window#waybar.empty #window* 当工作区没有窗口时


以下类应用于整个 Waybar 而不仅仅是窗口小部件：  
- *#window#waybar.empty*  当工作区没有窗口时  
- *#window#waybar.solo*   当工作区只有一个窗口时  
- *#window#waybar.*       其中 app-id 是工作区中唯一窗口的应用 ID  
