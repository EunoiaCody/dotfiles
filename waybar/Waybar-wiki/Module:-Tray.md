:warning: **`tray` is still in beta. There may be bugs. Breaking changes may occur.**



### Config

Addressed by `tray`

| option      | typeof  | default | description |
| ----------- | ------- | ------- | ----------- |
| `icon-size` | integer |         | Defines the size of the tray icons. |
| `show-passive-items`         | bool    | `false`   | Defines visibility of the tray icons with `Passive` status. |
| `smooth-scrolling-threshold` | double  |         | Threshold to be used when scrolling. |
| `spacing`   | integer |         | Defines the spacing between the tray icons. |
| `reverse-direction`   | bool | `false`   | Defines if new app icons should be added in a reverse order. |
| `icons`                      | object  | `{}`    | Override icon mapping for tray icons.                        |

### Icons

Each entry of `icons` must be `app_name`/`app_id` : `icon_name`/`image_path` mapping. `icon_name` can be a globally identified icon.

For now, it only works with actual image files, not font-based icons. It might not work for some electron apps (https://github.com/electron/electron/issues/40936).

#### Example:

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

### Style

- `#tray`
- `#tray menu` for the context menu
- `#tray > .passive` for icons with status `Passive`
- `#tray > .active` for icons with status `Active`
- `#tray > .needs-attention` for icons with status `NeedsAttention`
