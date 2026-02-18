The `clock` module displays the current date and time.

**Note:** There are two `clock` implementations:
1. `clock`: Fully consistent with what is written below. This is enabled if either one of the following build time conditions is met:
> 1. C++20 with __cpp_concepts >= 201907  (gcc >=13)
> 2. [date.h](https://github.com/HowardHinnant/date) is installed
2. `simpleclock`: Provides only date time functionality. That's it. Conditions for using: False the first point.

### Config

Addressed by `clock`

| option           | typeof  | default    | description |
| ---------------- | ------- | ---------- | ----------- |
| `interval`       | integer | 60         | The interval in which the information gets polled. |
| `format`         | string  | `{:%H:%M}` | The format, how the date and time should be displayed; see format options [here](https://fmt.dev/latest/syntax/#chrono-format-specifications). Split braces like `{0:%H}text{0:%M}`. |
| `format-alt`     | string  |            | Toggle to this alternative format on click, if specified. |
| `timezone`       | string  |            | The timezone to display the time in, e.g. America/New_York. See [Wikipedia's unofficial list of timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). |
| `timezones`      | list of strings  |   | A list of timezones (as in `timezone`) to use for time display, changed using the scroll wheel. Do not specify `timezone` option when `timezones` is specified. |
| `locale`         | string  |            | A locale to be used to display the time. Intended to render times in custom timezones with the proper language and format. |
| `max-length`     | integer |            | The maximum length in character the module should display. |
| `rotate`         | integer | 		  | Positive value to rotate the text label. |
| `on-click`       | string  |            | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |            | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |            | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip`        | bool    | true       | Option to enable tooltip on hover. |
| `tooltip-format` | string  | same as format | Tooltip on hover. Can also show a list of clocks in other timezones. See below the example using the property `tz_list`. |

Addressed by `clock: calendar`
| option           | typeof  | default    | description |
| ---------------- | ------- | ---------- | ----------- |
| `mode`           | string  | month      | Calendar view mode. Possible values: year\|month|
| `mode-mon-col`   | integer | 3          | Relevant for `mode=year`. Count of months per row|
| `weeks-pos`      | string  |            | The position where week numbers should be displayed. Disabled when is empty. Possible values: left\|right|
| `on-scroll`      | integer | 1          | Value to scroll months/years forward/backward. Can be negative. Is configured under `on-scroll` option|

Addressed by `clock: calendar: format`
| option           | typeof  | default    | description |
| ---------------- | ------- | ---------- | ----------- |
| `months`         | string  |            | Format is applied to months header(January, February,...etc.) |
| `days`           | string  |            | Format is applied to days |
| `weeks`          | string  | `{:%U}`    | Format is applied to week numbers. When weekday format is not provided then is used default format: '{:%W}' when week starts with Monday, '{:%U}' otherwise |
| `weekdays`       | string  |            | Format is applied to weeks header(Su,Mo,...etc.) |
| `today`          | string  | `<b><u>{}</u></b>` | Format is applied to Today |

### Actions
| string           | action  |
| ---------------- | ------- |
| `mode`           | Switch calendar mode between year/month     |
| `tz_up`          | Switch to the next provided time zone       |
| `tz_down`        | Switch to the previous provided time zone   |
| `shift_up`       | Switch to the next calendar month/year      |
| `shift_down`     | Switch to the previous calendar month/year  |
| `shift_reset`     | Switch to current calendar month/year  |

#### Example:
1. General
```jsonc
"clock": {
    "interval": 60,
    "format": "{:%H:%M}",
    "max-length": 25
}
```
2. Calendar
```jsonc
    "clock": {
        "format": "{:%H:%M}  ",
        "format-alt": "{:%A, %B %d, %Y (%R)}  ",
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "calendar": {
                    "mode"          : "year",
                    "mode-mon-col"  : 3,
                    "weeks-pos"     : "right",
                    "on-scroll"     : 1,
                    "format": {
                              "months":     "<span color='#ffead3'><b>{}</b></span>",
                              "days":       "<span color='#ecc6d9'><b>{}</b></span>",
                              "weeks":      "<span color='#99ffdd'><b>W{}</b></span>",
                              "weekdays":   "<span color='#ffcc66'><b>{}</b></span>",
                              "today":      "<span color='#ff6699'><b><u>{}</u></b></span>"
                              }
                    },
        "actions":  {
                    "on-click-right": "mode",
                    "on-scroll-up": "tz_up",
                    "on-scroll-down": "tz_down",
                    "on-scroll-up": "shift_up",
                    "on-scroll-down": "shift_down"
                    }
    },
```
![calendar](https://github.com/Alexays/Waybar/assets/6098822/e5c38984-6b3c-43ef-8cac-05122a078d58)

3. Full date on hover
```jsonc
"clock": {
    "interval": 60,
    "tooltip": true,
    "format": "{:%H.%M}",
    "tooltip-format": "{:%Y-%m-%d}",
}
```
4. Show in the clock tooltip a list of clocks from other timezones
```json
"clock": {
    "format": "{:%H:%M:%S (%Z)}",
    "tooltip-format": "{tz_list}",
    "timezones": [
        "Etc/UTC",
        "America/New_York",
        "America/Montevideo",
        "America/Los_Angeles",
        "Asia/Tokyo"
    ]
}
```

### Style

- `#clock`


#### Displaying seconds causes other modules to shift/be nudged side to side

This is a common issue with proportional fonts; the width of numeric glyphs varies wildly. If your font supports it, you may add `font-feature-settings: "tnum";` to your `#clock` style, or wherever you set font styling for the whole bar. A supported font will then use fixed-width numbers.

### Troubleshooting

If clock module is disabled at startup with `locale::facet::_S_create_c_locale name not valid` error message try one of the followings:
* check if `LC_TIME` is set properly (glibc)
* set locale to `C` in the config file (musl)

If using `clock` instead of `simpleclock`, the locale will default to `C` regardless of the locale settings. To override this behavior you have to perpend `L` to the formatting string. For example, `{:%a %m %d}` becomes `{:L%a %m %d}`.

The `locale` option must be set for {calendar} to use the correct start-of-week, regardless of system locale.

#### Calendar in Chinese. Alignment
In order to have aligned Chinese calendar there are some useful recommendations:
1. Use "WenQuanYi Zen Hei Mono" which is provided in most Linux distributions
2. Try different font sizes and find best for you. size = 9pt should be fine
3. In case when "WenQuanYi Zen Hei Mono" font is used disable monospace font pango tag

Example of working config
```json
"clock": {
        "format": "{:%H:%M}  ",
        "format-alt": "{:L%A, %B %d, %Y (%R)}  ",
        "tooltip-format": "\n<span size='9pt' font='WenQuanYi Zen Hei Mono'>{calendar}</span>",
        "calendar": {
                    "mode"          : "year",
                    "mode-mon-col"  : 3,
                    "weeks-pos"     : "right",
                    "on-scroll"     : 1,
                    "format": {
                              "months":     "<span color='#ffead3'><b>{}</b></span>",
                              "days":       "<span color='#ecc6d9'><b>{}</b></span>",
                              "weeks":      "<span color='#99ffdd'><b>W{}</b></span>",
                              "weekdays":   "<span color='#ffcc66'><b>{}</b></span>",
                              "today":      "<span color='#ff6699'><b><u>{}</u></b></span>"
                              }
                    },
        "actions":  {
                    "on-click-right": "mode",
                    "on-click-forward": "tz_up",
                    "on-click-backward": "tz_down",
                    "on-scroll-up": "shift_up",
                    "on-scroll-down": "shift_down"
                    }
    },
```
![calendar-chinese](https://github.com/Alexays/Waybar/assets/6098822/aa537991-3ea2-4c45-9bc6-12c1adf9663e)