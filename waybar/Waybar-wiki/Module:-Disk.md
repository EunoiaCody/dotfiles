The `disk` module tracks the usage of filesystems and partitions.

### Config

Addressed by `disk`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `interval`       | integer | 30      | The interval in which the information gets polled. |
| `format`         | string  | `{percentage_free}%` | The format, how information should be displayed. |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `states`         | array   |         | A number of disk utilization states which get activated on certain percentage thresholds (percentage_used).<br>See [States](https://github.com/Alexays/Waybar/wiki/States) |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |         | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `path` | string | `/` | Mount point of the filesystem to monitor. |
| `smooth-scrolling-threshold` | double  | | Threshold to be used when scrolling. |
| `tooltip`        | bool    | `true`  | Option to enable tooltip on hover. |
| `tooltip-format` | string  | `{used} used out of {total} on {path} ({percentage_used}%)` | Format of the text to display in the tooltip |
| `unit`       | string  |    B     | Used to specify unit for specific_total, specific_used, and specific_free. Accepts B, kB, kiB, MB, MiB, GB, GiB, TB, TiB. Defaults to Bytes. |

#### Format replacements:

| string         | replacement |
| -------------- | ----------- |
| `{percentage_free}` | Percentage of available space. |
| `{percentage_used}` | Percentage of disk space already in use. |
| `{total}`      | Amount of disk space. Will dynamically change display unit depending on amount of space. |
| `{used}`       | Amount of used disk space. Will dynamically change display unit depending on amount of space.|
| `{free}`       | Amount of free disk space. Will dynamically change display unit depending on amount of space.|
| `{specific_total}`      | Amount of disk space always displayed in a specific unit. Defaults to bytes.|
| `{specific_used}`       | Amount of used disk space always displayed in a specific unit. Defaults to bytes. |
| `{specific_free}`       | Amount of free disk space always displayed in a specific unit. Defaults to bytes. |

#### Examples:
```jsonc
"disk": {
    "interval": 30,
    "format": "Only {percentage_free}% remaining on {path}",
    "path": "/"
}

"disk": {
	"interval": 30,
	"format": "{specific_free:0.2f} GB out of {specific_total:0.2f} GB available. Alternatively {free} out of {total} available",
	"unit": "GB"
	// 0.25 GB out of 2000.00 GB available. Alternatively 241.3MiB out of 1.9TiB available.
}
```

### Style

- `#disk`
