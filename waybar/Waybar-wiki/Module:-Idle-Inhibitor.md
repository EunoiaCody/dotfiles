The `idle_inhibitor` module can inhibit idle behavior such as screen blanking, locking, and screensaving, also known as "presentation mode".

### Config

Addressed by `idle_inhibitor`

| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `format`         | string  | `{status}`    | The format, how the state should be displayed. |
| `format-icons`   | array   |               | Based on the current state, the corresponding icon gets selected. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `max-length`     | integer |               | The maximum length in character the module should display. |
| `on-click`       | string  |               | Command to execute when clicked on the module. A click also toggles the state |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |               | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |               | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |
| `tooltip-format-activated` | string | `{status}` | This format is used when the inhibit is activated. |
| `tooltip-format-deactivated` | string | `{status}` | This format is used when the inhibit is deactivated. |
| `start-activated` | bool   | `false`       | Whether the inhibit should be activated when starting waybar. |  
| `timeout` | double  | `0`              | Time in minutes to automatically deactivate. |

#### Format replacements:

| string       | replacement |
| ------------ | ----------- |
| `{status}` | status (`activated` or `deactivated`) |
| `{icon}`     | Icon, as defined in `format-icons`. |

#### Example:
```jsonc
"idle_inhibitor": {
    "format": "{icon}",
    "format-icons": {
        "activated": "",
        "deactivated": ""
    }
}
```

### Style

- `#idle_inhibitor`
- `#idle_inhibitor.<status>`
  - `<status>` is one of the `{status}` format replacement. For more information see [Format replacements](#format-replacements)