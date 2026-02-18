The `load` module displays the current CPU load.

### Config

Addressed by `load`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `interval`       | integer | 10      | The interval in which the information gets polled. |
| `format`         | string  | `{}`    | The format, how information should be displayed. |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |

#### Format replacements:

| string             | replacement |
| ------------------ | ----------- |
| `{}`               | Equivalent to `load1` |
| `{load1}`          | Current CPU load average over the last minute |
| `{load5}`          | Current CPU load average over the last 5 minutes |
| `{load15}`         | Current CPU load average over the last 15 minutes |

#### Examples:
```jsonc
"load": {
    "interval": 10,
    "format": "load: {load1}",
    "max-length": 10
}
```

```jsonc
"load": {
    "interval": 1,
    "format": "load: {load1} {load5} {load15}"
}
```

### Style

- `#load`