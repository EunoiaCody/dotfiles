### Config

Module for [FeralInteractive/gamemode](https://github.com/FeralInteractive/gamemode).

Addressed by `gamemode`

| option             | typeof  | default                  | description |
| ------------------ | ------- | ------------------------ | ----------- |
| `format`           | string  | `{glyph}`                | The text format. |
| `format-alt`       | string  | `{glyph} {count}`        | The text format when toggled. |
| `tooltip`          | bool    | `true`                   | Option to disable tooltip on hover. |
| `tooltip-format`   | string  | `Games running: {count}` | The text format of the tooltip. |
| `hide-not-running` | bool    | `true`                   | Defines the spacing between the tooltip window edge and the tooltip content. |
| `use-icon`         | bool    | `true`                   | Defines if the module should display a GTK icon instead of the specified glyph. |
| `glyph`            | string  | ``                        | The string icon to display. Only visible if use-icon is set to false. |
| `icon-name`        | string  | `input-gaming-symbolic`  | The GTK icon to display. Only visible if use-icon is set to true. |
| `icon-size`        | integer | `20`                       | Defines the size of the icons. |
| `icon-spacing`     | integer | `4`                        | Defines the spacing between the icon and the text. |

#### Format replacements:

| string    | replacement |
| --------- | ----------- |
| `{glyph}` | The string icon glyph to use instead. |
| `{count}` | The amount of games running with gamemode optimizations. |

#### Tooltip format replacements:

| string    | replacement |
| --------- | ----------- |
| `{count}` | The amount of games running with gamemode optimizations. |

#### Example:

```jsonc
"gamemode": {
    "format": "{glyph}",
    "format-alt": "{glyph} {count}",
    "glyph": "",
    "hide-not-running": true,
    "use-icon": true,
    "icon-name": "input-gaming-symbolic",
    "icon-spacing": 4,
    "icon-size": 20,
    "tooltip": true,
    "tooltip-format": "Games running: {count}"
}
```

### Style

- `#gamemode`
- `#gamemode.running`
