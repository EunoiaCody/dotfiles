The `cpu` module displays the current cpu utilization.

### Config

Addressed by `cpu`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `interval`       | integer | 10      | The polling interval (in seconds) for CPU info. |
| `format`         | string  | `{usage}%`    | The format, how information should be displayed. Data in `{}` gets inserted (see below). |
| `max-length`     | integer |         | The maximum length in characters the module should display. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `states`         | array   |               | A number of cpu usage states which get activated on certain usage levels.<br>See [States](https://github.com/Alexays/Waybar/wiki/States) |
| `on-click`       | string  |         | Command to execute when clicking on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle click on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right click on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |

#### Format replacements:

| string             | replacement |
| ------------------ | ----------- |
| `{load}`         | The 1 minute cpu load average. |
| `{usage}`         | Current cpu usage (% view). |
| `{usageN}`         | _Nth_ cpu core usage (% view). |
| `{icon}`         | Current cpu usage (icon view). |
| `{iconN}`         | _Nth_ cpu core usage (icon view). |
| `{avg_frequency}`         | Current cpu average frequency (based on all cores) in GHz. |
| `{max_frequency}`         | Current cpu max frequency (based on the core with the highest frequency) in GHz. |
| `{min_frequency}`         | Current cpu min frequency (based on the core with the lowest frequency) in GHz. |

#### Examples:
```jsonc
"cpu": {
    "interval": 10,
    "format": "{}% ",
    "max-length": 10
}
```

```jsonc
"cpu": {
     "format": "{icon0} {icon1} {icon2} {icon3} {icon4} {icon5} {icon6} {icon7}",
     "format-icons": ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"],
},
```

Using [PangoMarkupFormat](https://github.com/Alexays/Waybar/wiki/Configuration#module-format):

```jsonc
"cpu": {
     "interval": 1,
     "format": "{icon0}{icon1}{icon2}{icon3}{icon4}{icon5}{icon6}{icon7}",
     "format-icons": [
          "<span color='#69ff94'>▁</span>", // green
          "<span color='#2aa9ff'>▂</span>", // blue
          "<span color='#f8f8f2'>▃</span>", // white
          "<span color='#f8f8f2'>▄</span>", // white
          "<span color='#ffffa5'>▅</span>", // yellow
          "<span color='#ffffa5'>▆</span>", // yellow
          "<span color='#ff9977'>▇</span>", // orange
          "<span color='#dd532e'>█</span>"  // red
     ]
}
```

```jsonc
"cpu": {
     "format": "{icon0}{icon1}{icon2}{icon3}{icon4}{icon5}{icon6}{icon7}",
     "format-icons": [
       "🁣", "🁤", "🁥", "🁦", "🁧", "🁨", "🁩", 
       "🁪", "🁫", "🁬", "🁭", "🁮", "🁯", "🁰", 
       "🁱", "🁲", "🁳", "🁴", "🁵", "🁶", "🁷", 
       "🁸", "🁹", "🁺", "🁻", "🁼", "🁽", "🁾", 
       "🁿", "🂀", "🂁", "🂂", "🂃", "🂄", "🂅", 
       "🂆", "🂇", "🂈", "🂉", "🂊", "🂋", "🂌", 
       "🂍", "🂎", "🂏", "🂐", "🂑", "🂒", "🂓", "🁢"
     ],
},
```
### Style

- `#cpu`
