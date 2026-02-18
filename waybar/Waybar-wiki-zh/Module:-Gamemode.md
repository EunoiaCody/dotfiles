### 配置

用于 [FeralInteractive/gamemode](https://github.com/FeralInteractive/gamemode) 的模块。

通过 `gamemode` 引用

| option             | typeof  | default                  | description |
| ------------------ | ------- | ------------------------ | ----------- |
| `format`           | string  | `{glyph}`                | 文本格式。 |
| `format-alt`       | string  | `{glyph} {count}`        | 切换后的文本格式。 |
| `tooltip`          | bool    | `true`                   | 禁用悬停提示的选项。 |
| `tooltip-format`   | string  | `Games running: {count}` | 提示文本的格式。 |
| `hide-not-running` | bool    | `true`                   | 定义提示窗口边缘与提示内容之间的间距。 |
| `use-icon`         | bool    | `true`                   | 定义模块是否应显示 GTK 图标而不是指定的字形。 |
| `glyph`            | string  | ``                        | 要显示的字符串图标。仅在 use-icon 设置为 false 时可见。 |
| `icon-name`        | string  | `input-gaming-symbolic`  | 要显示的 GTK 图标。仅在 use-icon 设置为 true 时可见。 |
| `icon-size`        | integer | `20`                       | 定义图标的大小。 |
| `icon-spacing`     | integer | `4`                        | 定义图标与文本之间的间距。 |

#### 格式替换：

| string    | replacement |
| --------- | ----------- |
| `{glyph}` | 用于替代的字符串图标字形。 |
| `{count}` | 使用 gamemode 优化运行的游戏数量。 |

#### 提示格式替换：

| string    | replacement |
| --------- | ----------- |
| `{count}` | 使用 gamemode 优化运行的游戏数量。 |

#### 示例：

```jsonc
"gamemode": {
    "format": "{glyph}",
    "format-alt": "{glyph} {count}",
    "glyph": "",
    "hide-not-running": true,
    "use-icon": true,
    "icon-name": "input-gaming-symbolic",
    "icon-spacing": 4,
    "icon-size": 20,
    "tooltip": true,
    "tooltip-format": "Games running: {count}"
}
```

### 样式

- `#gamemode`
- `#gamemode.running`
