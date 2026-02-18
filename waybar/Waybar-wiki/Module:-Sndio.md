The `sndio` module displays the current volume reported by sndio.

Additionally, you can control the volume by scrolling *up* or *down* while the cursor is over the module, and clicking on the module toggles mute.

### Configuration

| option             | typeof  | default     | description |
| ------------------ | ------- | ----------- | ----------- |
| `format`           | string  | `{volume}%` | The format for how information should be displayed. |
| `format-bluetooth` | string  |             | This format is used when using bluetooth speakers. |
| `rotate` | integer | 0 | Positive value to rotate the text label. |
| `max-length`       | integer |             | The maximum length in character the module should display. |
| `scroll-step`      | integer | 5 | The speed in which to change the volume when scrolling. |
| `on-click`         | string  |             | Command to execute when clicked on the module.<br>This replaces the default behaviour of toggling mute. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`     | string  |             | Command to execute when scrolling up on the module.<br>This replaces the default beaviour of volume control. |
| `on-scroll-down`   | string  |             | Command to execute when scrolling down on the module.<br>This replaces the default beaviour of volume control. |
| `on-update`   | string  |             | Command to execute when the module is updated. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |

#### Format replacements:

| string     | replacement |
| ---------- | ----------- |
| `{volume}` | Volume in percentage. |
| `{raw_volume}` | Volume as reported by sndio. |

#### Example:

```jsonc
"sndio": {
    "format": "{raw_value} 🎜",
    "scroll-step": 3
}
```

### Style

- `#sndio`
- `#sndio.muted`