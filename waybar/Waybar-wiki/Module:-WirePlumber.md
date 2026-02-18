The `wireplumber` module displays the current volume reported by WirePlumber.

Additionally you can control the volume by scrolling *up* or *down* while the cursor is over the module.

### Config

| option             | typeof  | default     | description |
| ------------------ | ------- | ----------- | ----------- |
| `format`           | string  | `{volume}%` | The format, how information should be displayed.<br>This format is used when other formats aren't specified. |
| `format-muted`     | string  |             | This format is used when the sound is muted. |
| `format-source`    | string  | `{volume}%` | This format used for the source. |
| `format-source-muted` | string |           | This format is used when the source is muted. |
| `format-icons`     | array   |             | Based on the current volume, the corresponding icon gets selected.<br>The order is *low* to *high*. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `states`         | array   |               | A number of volume states which get activated on certain volume levels.<br>See [States](https://github.com/Alexays/Waybar/wiki/States) |
| `max-length`       | integer |             | The maximum length in character the module should display. |
| `scroll-step`      | float | 1.0           | The speed in which to change the volume when scrolling. |
| `on-click`         | string  |             | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`     | string  |             | Command to execute when scrolling up on the module.<br>This replaces the default beaviour of volume control. |
| `on-scroll-down`   | string  |             | Command to execute when scrolling down on the module.<br>This replaces the default beaviour of volume control. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |
| `tooltip-format`| string | `{node_name}` | Tooltip on hover. |
| `max-volume` | float | 100.0 | The maximum volume that can be set, in percentage. |
| `reverse-scrolling`          | bool    | false        | Option to reverse the scroll direction for devices other than a mouse (touchpad, trackpad, etc)  |
| `reverse-mouse-scrolling`    | bool    | false        | Option to reverse the scroll direction for mice |
| `node-type`| string | `Audio/Sink` | The type of node. Can be `Audio/Sink` or `Audio/Source`. |
| `only-physical`| bool | false | Option to follow the links to the first physical output node if the default output is virtual (has no device.id). |

#### Format replacements:

| string     | replacement |
| ---------- | ----------- |
| `{volume}` | Volume in percentage |
| `{icon}`   | Icon, as defined in `format-icons`. |
| `{node_name}` | The node's nickname (WirePlumber's `node.nick` property) |
| `{format_source}` | Source format, `format-source`, `format-source-muted`. |
| `{source_volume}` | Source volume in percentage |
| `{source_desc}` | Source description (node.nick or node.description) |


#### Example:

```jsonc
"wireplumber": {
    "format": "{volume}%",
    "format-muted": "",
    "on-click": "helvum",
    "max-volume": 150,
    "scroll-step": 0.2
}
```

With icon support:

```jsonc
"wireplumber": {
    "format": "{volume}% {icon}",
    "format-muted": "",
    "on-click": "helvum",
    "format-icons": ["", "", ""]
}
```

For source (microphone etc) nodes:

```jsonc
"wireplumber#source": {
    "node-type": "Audio/Source",
    "format": "{volume}% 󰍬",
    "format-muted": "󰍭",
    "on-click-right": "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
    "scroll-step": 5,
},
```

With combined sink and source information:

```jsonc
"wireplumber": {
    "format": "{volume}% {icon} {format_source}",
    "format-muted": " {format_source}",
    "format-source": "{source_volume}% ",
    "format-source-muted": " ",
    "format-icons": {
        "default": ["", ""]
    },
    "on-click": "helvum"
}
```

### Style

- `#wireplumber`
- `#wireplumber.muted`
- `#wireplumber.sink-muted`
- `#wireplumber.source-muted`
