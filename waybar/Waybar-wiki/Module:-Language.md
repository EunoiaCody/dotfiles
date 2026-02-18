The `sway/language` module displays the current keyboard layout in Sway.
# Config
| option | typeof | default | description |
|--------|:------:|:-------:|-------------|
| `format` | string | `{}` | The format, how layout should be displayed. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |         | Command to execute when you right clicked on the module. |
| `tooltip-format` | string | `{}` | The format, how layout should be displayed in tooltip. |
| `tooltip` | bool | `true` | Option to disable tooltip on hover. |

## Format replacements:
| string | replacement |
|--------|-------------|
| `{}` | The same as `{short}`. |
| `{short}` | Short name of layout (e.g. "us"). |
| `{shortDescription}` | Short description of layout (e.g. "en"). |
| `{long}` | Long name of layout (e.g. "English (Dvorak)"). |
| `{variant}` | Variant of layout (e.g. "dvorak"). |
| `{flag}` | Flag of the country. |


## Example:
```jsonc
"sway/language": {
    "format": "{}",
    "on-click": "swaymsg input type:keyboard xkb_switch_layout next",
},

"sway/language": {
    "format": "{short} {variant}",
}

```

# Style

- `#language`
- `#language.<short>`