`workspaces` 模块显示 Wayland 合成器中当前活动的工作区。

注意：要使用此模块，您的合成器必须实现 `ext-workspace-v1` Wayland 协议。

Waybar 需要使用 `-Dexperimental=true` 构建才能使 `ext/workspaces` 可用（参见 [#1766](https://github.com/Alexays/Waybar/issues/1766)）。

# 配置
| option | typeof | default | description |
|--------|:------:|:-------:|-------------|
| `format`         | string  | `{name}` | 信息的显示格式。 |
| `format-icons`   | array   |          | 根据工作区名称和状态选择相应的图标。<br>参见 [`Icons`](#module-workspaces-config-icons) |
| `sort-by-name`         | bool  | `true` | 是否按名称排序工作区。 |
| `sort-by-coordinates`         | bool  | `true` | 是否按坐标排序工作区。注意，如果 *sort-by-name* 和 *sort-by-coordinates* 都为 true，则先按名称排序。如果两者都为 false，则按 ID 排序。 |
| `sort-by-number` | bool | `false` | 如果设为 true，工作区名称将按数字排序。优先级高于任何其他 sort-by 选项。 |
| `all-outputs`         | bool  | `false` | 如果设为 false，工作区组仅在分配的输出上显示。否则显示所有工作区组。 |
| `active-only`         | bool  | `false` | 如果设为 true，仅显示活动或紧急的工作区。 |
| `persistent-workspaces` | json (see below) | empty | 列出应始终显示的工作区，即使不存在也是如此。当 *all-outputs* 为 true 或在 `ext/workspaces` 上时不起作用 |
| `on-click`         | Actions (see below)  |  | 可用于在点击时激活或关闭工作区 |

## 格式替换：
| string | replacement |
|--------|-------------|
| `{name}` | 合成器分配的工作区名称。 |
| `{icon}` | 图标，如 *format-icons* 中定义的。 |


<a name="module-workspaces-config-icons"></a>

#### 图标：

除了工作区名称匹配外，还可以设置以下 `format-icons`。

| port name | note |
| ------------ | ---- |
| `default`    | 在没有找到匹配的字符串时显示。 |
| `urgent`     | 在工作区被标记为紧急时显示。 |
| `active`    | 在工作区处于活动状态时显示 |

## 操作：
| string | action |
|--------|--------|
| `activate` | 切换到工作区。 |
| `close` | 关闭工作区。 |

## 持久工作区：
`persistent-workspace` 的每个条目命名一个应始终显示的工作区。与该值关联的是一个输出列表，指示工作区应在*哪里*显示，空列表表示所有输出
```jsonc
"ext/workspaces": {
    "persistent-workspaces": {
        "3": [], // Always show a workspace with name '3', on all outputs if it does not exists
        "4": ["eDP-1"], // Always show a workspace with name '4', on output 'eDP-1' if it does not exists
        "5": ["eDP-1", "DP-2"] // Always show a workspace with name '5', on outputs 'eDP-1' and 'DP-2' if it does not exists
    }
}
```
注意：如果 `all-outputs` 为 true，此功能目前不起作用。

## [Sway](./Module:-Sway) 示例：
```jsonc
"sway/workspaces": {
  "format": "{icon}",
  "on-click": "activate",
  "format-icons": {
    "1": "",
    "2": "",
    "3": "",
    "4": "",
    "5": "",
    "urgent": "",
    "active": "",
    "default": ""
  },
  "sort-by-number": true
}
```

## [Hyprland](https://github.com/Alexays/Waybar/wiki/Module:-Hyprland#workspaces) 示例：
```jsonc
"hyprland/workspaces": {
  "format": "{icon}",
  "on-click": "activate",
  "format-icons": {
    "1": "",
    "2": "",
    "3": "",
    "4": "",
    "5": "",
    "urgent": "",
    "active": "",
    "default": ""
  },
  "sort-by-number": true
}
```

- 参见[完整文档](https://github.com/Alexays/Waybar/wiki/Module:-Hyprland#workspaces)。

## Labwc 示例：
```jsonc
"ext/workspaces": {
    "format": "{name}",
    "sort-by-number": true,
    "on-click": "activate",
},
```

# 样式

注意：Sway 使用一组不同的类。请参阅 [Sway](./Module:-Sway) 模块页面。

- *#workspaces*
- *#workspaces button*
- *#workspaces button.active*
- *#workspaces button.visible*
- *#workspaces button.urgent*
- *#workspaces button.empty*
- *#workspaces button.persistent*
- *#workspaces button.hidden*
