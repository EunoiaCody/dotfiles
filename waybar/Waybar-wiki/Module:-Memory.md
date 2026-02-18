The `memory` module displays the current **RAM** and **swap** utilization.

### Config

Addressed by `memory`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `interval`       | integer | 30      | The interval in which the information gets polled. |
| `format`         | string  | `{percentage}%`   | The format, how information should be displayed. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `states`         | array   |               | A number of memory utilization states which get activated on certain percentage thresholds.<br>See [States](https://github.com/Alexays/Waybar/wiki/States) |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |
| `tooltip-format` | string  | `{used:0.1f}GiB used` | Format of the text to display in the tooltip |

#### Format replacements:

| string         | replacement |
| -------------- | ----------- |
| `{percentage}` | Percentage of memory in use. |
| `{swapPercentage}` | Percentage of swap in use. |
| `{total}`      | Amount of total memory in GiB. |
| `{swapTotal}`      | Amount of total swap in GiB. |
| `{used}`       | Amount of used memory in GiB. |
| `{swapUsed}`       | Amount of used swap in GiB. |
| `{avail}`      | Amount of available memory in GiB. |
| `{swapAvail}`      | Amount of available swap in GiB. |

#### Examples:
```jsonc
"memory": {
    "interval": 30,
    "format": "{}% ",
    "max-length": 10
}
```

Formatted memory values:
```jsonc
"memory": {
    "interval": 30,
    "format": "{used:0.1f}G/{total:0.1f}G "
}
```

### Style

- `#memory`
