The `pulseaudio` module displays the current volume reported by PulseAudio.

Additionally you can control the volume by scrolling *up* or *down* while the cursor is over the module.

### Config

| option             | typeof  | default     | description |
| ------------------ | ------- | ----------- | ----------- |
| `format`           | string  | `{volume}%` | The format, how information should be displayed.<br>This format is used when other formats aren't specified. |
| `format-bluetooth` | string  |             | This format is used when using bluetooth speakers. |
| `format-muted`     | string  |             | This format is used when the sound is muted. |
| `format-source`     | string  |   `{volume}%`          | This format used for the source. |
| `format-source-muted`     | string  |             | This format is used when the source is muted. |
| `format-icons`     | array   |             | Based on the current port-name and volume, the corresponding icon gets selected.<br>The order is *low* to *high*. See [`Icons`](#module-pulseaudio-config-icons) |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `states`         | array   |               | A number of volume states which get activated on certain volume levels.<br>See [States](https://github.com/Alexays/Waybar/wiki/States) |
| `max-length`       | integer |             | The maximum length in character the module should display. |
| `scroll-step`      | float | 1.0           | The speed in which to change the volume when scrolling. |
| `on-click`         | string  |             | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`     | string  |             | Command to execute when scrolling up on the module.<br>This replaces the default behaviour of volume control. |
| `on-scroll-down`   | string  |             | Command to execute when scrolling down on the module.<br>This replaces the default behaviour of volume control. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |
| `tooltip-format`| string | `{desc}` | Tooltip on hover. |
| `max-volume` | integer | 100 | The maximum volume that can be set, in percentage. |
| `ignored-sinks` | array |       | List of sinks to ignore, by description.<br>Use `pactl list sinks` to find the correct description. |
| `reverse-scrolling` | bool | false | Option to reverse the scroll direction for devices other than a mouse (touchpad, trackpad, etc) |
| `reverse-mouse-scrolling` | bool | false | Option to reverse the scroll direction for mice |

#### Format replacements:

| string     | replacement |
| ---------- | ----------- |
| `{volume}` | Volume in percentage |
| `{icon}`   | Icon, as defined in `format-icons`. |
| `{format_source}` | Source format, `format-source`, `format-source-muted`. |
| `{desc}` | Pulseaudio port's description, for bluetooth it'll be the device name. |

<a name="module-pulseaudio-config-icons"></a>

#### Icons:

The following strings for *format-icons* are supported.

| string              | note  |
| ------------------- | ----- |
| `[the device name]` | Looks something like `alsa_output.pci-0000_00_1f.3.3.analog-stereo`.<br>You can use a PulseAudio frontend to find this such as `pacmd list-sinks` or `pamixer --list-sinks` |

If they are found in the current PulseAudio port name, the corresponding icons will be selected.

| string       | note |
| ------------ | ---- |
| `default`    | Will be shown, when no other port is found. |
| `headphone`  | `headphones` until 0.9.0 |
| `speaker`    |      |
| `hdmi`       |      |
| `headset`    |      |
| `hands-free` | `handsfree` until 0.9.0 |
| `portable`   |      |
| `car`        |      |
| `hifi`       |      |
| `phone`      |      |

Additionally, suffixing a device name or port with `-muted` will cause the icon to be selected when the corresponding audio device is muted. This applies to `default` as well.


#### Example:

```jsonc
"pulseaudio": {
    "format": "{volume}% {icon}",
    "format-bluetooth": "{volume}% {icon}",
    "format-muted": "",
    "format-icons": {
        "alsa_output.pci-0000_00_1f.3.analog-stereo": "",
        "alsa_output.pci-0000_00_1f.3.analog-stereo-muted": "",
        "headphone": "",
        "hands-free": "",
        "headset": "",
        "phone": "",
        "phone-muted": "",
        "portable": "",
        "car": "",
        "default": ["", ""]
    },
    "scroll-step": 1,
    "on-click": "pavucontrol",
    "ignored-sinks": ["Easy Effects Sink"]
}
```

### Style

- `#pulseaudio`
- `#pulseaudio.bluetooth`
- `#pulseaudio.muted`
- `#pulseaudio.source-muted`
