`wlr/taskbar` 模块可用于添加基于 foreign-toplevel-manager 协议的任务栏。要使此模块工作，你需要一个实现了该协议的 Wayland 合成器。
# 配置
| option | typeof | default | description |
|--------|:------:|:-------:|-------------|
| `all-outputs` | bool | `false` | 如果设置为 `false`，仅显示 waybar 当前输出上的应用程序。否则显示所有应用程序。 |
| `format` | string | `{icon}` | 应用程序信息的显示格式。 |
| `icon-theme` | string | | 应使用的图标主题名称。如果省略，将使用系统默认主题。 |
| `icon-size` | int | `16` | 图标的像素大小。 |
| `markup` | bool | `false` | 如果设置为 `true`，将允许在 format/tooltip_format 中使用 pango 标记。 |
| `tooltip` | bool | `true` | 如果设置为 `false`，将不显示工具提示。 |
| `tooltip-format` | string | `{title}` | 工具提示中应用程序信息的显示格式。 |
| `active-first` | bool | `false` | 如果设置为 true，始终重新排序任务栏中的任务，使当前活动的任务排在第一位。否则不重新排序。 |
| `sort-by-app-id` | bool | `false` | 如果设置为 true，按 app_id 对任务进行分组。不能与 'active‐first' 同时使用。 |
| `on-click` | string | | 用鼠标左键点击任务栏中应用程序按钮时触发的操作。 |
| `on-click-middle` | string | | 用鼠标中键点击任务栏中应用程序按钮时触发的操作。 |
| `on-click-right` | string | | 用鼠标右键点击任务栏中应用程序按钮时触发的操作。 |
| `on-update` | string | | 模块更新时执行的命令。 |
| `ignore-list` | array[string] | | 不可见的 app_id/标题列表。 |
| `app_ids-mapping` | object | | 要替换的 app_id 字典。 |
| `rewrite` | object | | 重写模块格式输出的规则。参见**重写规则**。 |

## 格式替换：
| string | replacement |
|--------|-------------|
| `{icon}` | 应用程序的图标。 |
| `{title}` | 应用程序的标题。 |
| `{name}` | 应用程序的名称。 |
| `{app_id}` | 应用程序的 `app_id`。 |
| `{state}` | 应用程序的状态（minimized、maximized、active、fullscreen）。 |
| `{short_state}` | 以单个字符表示的应用程序状态（minimized == m、maximized == M、active == A、fullscreen == F）。 |

注意：与 waybar 中所有格式替换一样，`{title:.15}` 会将替换的 `title` 字符串限制为 15 字节的长度。如果存在多字节字符或（如果 `markup` 为 true）文本包含必须在 XML 中转义的值，则可能导致无效文本。

## 操作：
| string | action |
|--------|--------|
| `activate` | 将应用程序带到前台。 |
| `minimize` | 切换应用程序的最小化状态。 |
| `minimize-raise` | 将应用程序带到前台或切换其最小化状态。 |
| `maximize` | 切换应用程序的最大化状态。 |
| `fullscreen` | 切换应用程序的全屏状态。 |
| `close` | 关闭应用程序。 |

## 重写规则：

`rewrite` 是一个对象，其中键为正则表达式，值为表达式匹配时的重写规则。规则中可以包含对表达式捕获组的引用。

正则表达式和替换遵循 [ECMAScript 规则](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Cheatsheet)（[正式定义](https://tc39.es/ecma262/#sec-regexp-regular-expression-objects)）。

表达式必须完全匹配才能触发替换；如果没有表达式匹配，格式输出将保持不变。

无效的表达式（例如，括号不匹配）将被忽略。

## 示例：
```jsonc
"wlr/taskbar": {
    "format": "{icon}",
    "icon-size": 14,
    "icon-theme": "Numix-Circle",
    "tooltip-format": "{title}",
    "on-click": "activate",
    "on-click-middle": "close",
    "ignore-list": [
       "Alacritty"
    ],
    "app_ids-mapping": {
      "firefoxdeveloperedition": "firefox-developer-edition"
    },
    "rewrite": {
        "Firefox Web Browser": "Firefox",
        "Foot Server": "Terminal"
        ".*(steam_app_[0-9]+).*": "Game"

    }
}
```
# 样式

- `#taskbar`
- `#taskbar button`
- `#taskbar button.active`
- `#taskbar button.minimized`
- `#taskbar button.maximized`
- `#taskbar button.fullscreen`
- `#taskbar.empty`