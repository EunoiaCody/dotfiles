The `battery` module displays the current capacity and state (eg. charging) of your battery.

### Config

Addressed by `battery`

| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `bat`            | string  |               | The battery to monitor, as in `/sys/class/power_supply/` instead of auto detect. |
| `adapter`        | string  |               | The adapter to monitor, as in `/sys/class/power_supply/` instead of auto detect. |
| `design-capacity` | bool   | `false`       | Option to enable the use of the design capacity instead of the actual maximal capacity. Thus, even full, the battery may be at less than 100%. |
| `full-at`        | integer |               | Define the max percentage of the battery, useful for an old battery, e.g. 96 |
| `interval`       | integer | 60            | The polling interval (in seconds) for the battery status. |
| `states`         | array/object |          | A number of battery states which get activated on certain capacity levels.<br>See [States](https://github.com/Alexays/Waybar/wiki/States) |
| `format`         | string  | `{capacity}%` | The format, how the information should be displayed. |
| `format-time`    | string  | `{H} h {M} min` | The format of the estimate of time until full or empty. Use `{m}` for zero-padded minutes. |
| `format-icons`   | array/object |          | Based on the current capacity, the corresponding icon gets selected.<br>The order is *low* to *high*.<br>Or by the state if it is an object. |
| `max-length`     | integer |               | The maximum length (in characters) the module should display. |
| `rotate`         | integer | 	             | Positive value to rotate the text label. |
| `on-click`       | string  |               | Command to execute when clicking the module. |
| `on-click-middle` | string |               | Command to execute when you middle click on the module using the mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right click on the module. |
| `on-scroll-up`   | string  |               | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |               | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold`| double |     | Threshold to be used when scrolling. |
| `tooltip`        | bool    | `true`        | Option to enable tooltip on hover. |
| `tooltip-format` | string  | `{timeTo}`    | The tooltip format. |
| `weighted-average` | bool  | `true`       | For devices with multiple batteries, an option to display the percentage as an average weighted by the size of the batteries, rather than a simple average of their percentage levels |
| `bat-compatibility` | bool | `false`       | Option to enable battery compatibility if not detected. |

#### Format replacements:

| string       | replacement |
| ------------ | ----------- |
| `{capacity}` | Capacity in percentage |
| `{power}`    | Power draw in watts |
| `{icon}`     | Icon, as defined in `format-icons`. |
| `{time}`     | Estimate of time until full or empty. Note that this is based on the power draw at the last refresh time, not an average. |
| `{cycles}`   | The amount of charge cycles the highest-capacity battery has seen *(Linux only)* |

<!--
| `{health}`   | A percentage representing the highest-capacity battery's current maximum charge relative to it's design capacity *(Linux only)* |
-->

<a name="module-battery-config-format-custom"></a>

#### Custom Formats:

The `battery` module allows to define custom formats based on up to two factors. The best fitting format will be selected.

| format                    | description |
| ------------------------- | ----------- |
| `format-<state>`          | With [states](#module-battery-config-states), a custom format can be set depending on the capacity of your battery. |
| `format-<status>`         | With the status, a custom format can be set depending on the status in `/sys/class/power_supply/<bat>/status` (in lowercase). |
| `format-<status>-<state>` | You can also set a custom format depending on both values. |

<a name="module-battery-config-tooltip-format-custom"></a>

#### Custom Tooltip Formats:

The tooltip format can be changed similarly to the label format. The best fitting from `tooltip-format`, `tooltip-format-<state>`, `tooltip-format-<status>` and `tooltip-format-<status>-<state>` will be used (using the same logic as `format-*`). Valid tooltip format replacements are as follows:

| string       | replacement |
| ------------ | ----------- |
| `{capacity}` | Capacity in percentage |
| `{power}`    | Power draw in watts |
| `{time}`     | Estimate of time until full or empty. Note that this is based on the power draw at the last refresh time, not an average. |
| `{timeTo}`   | Either an estimate of time until full or empty, or "Full", "Plugged" or "Empty" depending on the current battery status |
| `{cycles}`   | The amount of charge cycles the highest-capacity battery has seen *(Linux only)* |
| `{health}`   | A percentage representing the highest-capacity battery's current maximum charge relative to it's design capacity *(Linux only)* |

<a name="module-battery-config-states"></a>

#### States:

- Every entry (*state*) consists of a `<name>` (typeof: `string`) and a `<value>` (typeof: `integer`).
  - The state can be addressed as a CSS class in the `style.css`. The name of the CSS class is the `<name>` of the state.
    Each class gets activated when the current capacity is equal or below the configured `<value>`.
  - Also each state can have its own `format`.
    Those can be configured via `format-<name>`.
    Or if you want to differentiate a bit more even as `format-<status>-<state>`. For more information see [custom formats](#module-battery-config-format-custom).

#### Example:
```jsonc
"battery": {
    "bat": "BAT2",
    "interval": 60,
    "states": {
        "warning": 30,
        "critical": 15
    },
    "format": "{capacity}% {icon}",
    "format-icons": ["", "", "", "", ""],
    "max-length": 25
}
```

Custom icon set depending on `<state>`:

```jsonc
"battery": {
    "bat": "BAT2",
    "interval": 60,
    "format": "{capacity}% {icon}",
    "format-icons": {
        "default": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
        "charging": ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    },
}
```

### Style

- `#battery`
- `#battery.<status>`
  - `<status>` is the value of `/sys/class/power_supply/<bat>/status` in lowercase.
- `#battery.<state>`
  - `<state>` can be defined in the `config`. For more information see [`states`](#module-battery-config-states)
- `#battery.<status>.<state>`
  - Combination of both `<status>` and `<state>`.

The following classes can apply styles to _the entire Waybar_:

- `window#waybar.battery-<state>`
  - `<state>` can be defined in the `config`, as previously mentioned.
