The `backlight` module displays the current backlight level.

### Config

Addressed by `backlight`

| option                       | typeof  | default      | description |
| ---------------------------- | ------- | ------------ | ----------- |
| `interval`                   | integer | 2            | The polling interval (in seconds) for the backlight level. |
| `format`                     | string  | `{percent}%` | The format, how information should be displayed. On `{}` data gets inserted. |
| `format-icons`   | array |              | Based on the current screen brightness, the corresponding icon gets selected.<br>The order is *low* to *high*.<br> |
| `max-length`                 | integer |              | The maximum length in characters the module should display. |
| `rotate`	               | integer | 		| Positive value to rotate the text label. |
| `states`                     | array   |              | A number of backlight states which get activated on certain brightness levels.<br>See [States](https://github.com/Alexays/Waybar/wiki/States) |
| `on-click`                   | string  |              | Command to execute when clicking on the module. |
| `on-click-middle`            | string  |              | Command to execute when you middle click on the module using the mousewheel. |
| `on-click-right`             | string  |              | Command to execute when you right click on the module. |
| `on-scroll-up`               | string  |              | Command to execute when scrolling up on the module. This replaces the default behaviour of brightness control. |
| `on-scroll-down`             | string  |              | Command to execute when scrolling down on the module. This replaces the default behaviour of brightness control. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `reverse-scrolling`          | bool    | false        | Option to reverse the scroll direction for devices other than a mouse (touchpad, trackpad, etc)  |
| `reverse-mouse-scrolling`    | bool    | false        | Option to reverse the scroll direction for mice |
| `scroll-step`                | float   | 1.0          | The speed in which to change the brightness when scrolling. |
| `tooltip`                    | bool    | `true`       | Option to disable tooltip on hover. |
| `tooltip-format`             | string  |              | Text to be displayed in the tooltip |

#### Format replacements:

| string       | replacement |
| ------------ | ----------- |
| `{percent}` | Screen brightness as a percentage |
| `{icon}`     | Icon, as defined in `format-icons`. |

#### Example:
```jsonc
"backlight": {
    "device": "intel_backlight",
    "format": "{percent}% {icon}",
    "format-icons": ["", ""]
}
```

### Style

- `#backlight`

### See also
* [External screen brightness](https://gist.github.com/nicodebo/297c1e134256ea24abf02a485ce41420) (using [ddcutil](https://github.com/rockowitz/ddcutil))
* [Another external screen brightness](https://gist.github.com/Ar7eniyan/42567870ad2ce47143ffeb41754b4484) (using ddcutil too)
* [Screen brightness without external scripts](https://gist.github.com/MyrikLD/4467d4dae3f0911cd5094b8440cbf418) (still ddcutil) Note: Can close Monitor **O**n**S**creen**D**isplay each set interval (e.g.: AOC 27G2G8)
* [Screen brightness with simple bash script](https://gist.github.com/negoro26/c59167fb4c08da46c4e08e1fdcd7aeb1) (with ddcutil too)
