`sway/language` 模块显示 Sway 中当前选择的键盘布局。
# 配置
| option | typeof | default | description |
|--------|:------:|:-------:|-------------|
| `format` | string | `{}` | 布局的显示格式。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |         | 右键点击模块时执行的命令。 |
| `tooltip-format` | string | `{}` | 提示中布局的显示格式。 |
| `tooltip` | bool | `true` | 禁用悬停提示的选项。 |

## 格式替换：
| string | replacement |
|--------|-------------|
| `{}` | 与 `{short}` 相同。 |
| `{short}` | 布局的短名称（例如 "us"）。 |
| `{shortDescription}` | 布局的短描述（例如 "en"）。 |
| `{long}` | 布局的长名称（例如 "English (Dvorak)"）。 |
| `{variant}` | 布局的变体（例如 "dvorak"）。 |
| `{flag}` | 国家的旗帜。 |


## 示例：
```jsonc
"sway/language": {
    "format": "{}",
    "on-click": "swaymsg input type:keyboard xkb_switch_layout next",
},

"sway/language": {
    "format": "{short} {variant}",
}

```

# 样式

- `#language`
- `#language.<short>`
