:warning: **`tray` 仍处于测试阶段。可能存在错误。可能会发生破坏性变更。**


### 配置

通过 `tray` 进行配置

| option | typeof | default | description |
| ----------- | ------- | ------- | ----------- |
| `icon-size` | integer |         | 定义托盘图标的大小。 |
| `show-passive-items`         | bool    | `false`   | 定义状态为 `Passive` 的托盘图标是否可见。 |
| `smooth-scrolling-threshold` | double  |         | 滚动时使用的阈值。 |
| `spacing`   | integer |         | 定义托盘图标之间的间距。 |
| `reverse-direction`   | bool | `false`   | 定义新的应用图标是否以相反的顺序添加。 |
| `icons`                      | object  | `{}`    | 覆盖托盘图标的图标映射。                        |

### 图标

`icons` 的每个条目必须是 `app_name`/`app_id` : `icon_name`/`image_path` 的映射。`icon_name` 可以是一个全局标识的图标。

目前，它仅适用于实际的图像文件，不适用于基于字体的图标。对于某些 Electron 应用可能不起作用 (https://github.com/electron/electron/issues/40936)。

#### 示例：

```jsonc
"tray": {
    "icon-size": 21,
    "spacing": 10,
    "icons": {
        "blueman": "bluetooth",
        "TelegramDesktop": "$HOME/.local/share/icons/hicolor/16x16/apps/telegram.png"
    }
}
```

### 样式

- `#tray`
- `#tray menu` 用于上下文菜单
- `#tray > .passive` 用于状态为 `Passive` 的图标
- `#tray > .active` 用于状态为 `Active` 的图标
- `#tray > .needs-attention` 用于状态为 `NeedsAttention` 的图标
