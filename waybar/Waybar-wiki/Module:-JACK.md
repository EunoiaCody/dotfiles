The `jack` module displays the current state of the [JACK](https://jackaudio.org/) server. Supports both [JACK2](https://github.com/jackaudio/jack2) and [PipeWire](https://pipewire.org/) implementations of the JACK API.

NOTE: PipeWire users are advised to upgrade to v0.3.57 at minimum; earlier versions without [this bugfix](https://gitlab.freedesktop.org/pipewire/pipewire/-/commit/d7da581b9c9f1783a599cd95edd0bd5a5a5b4f05) cause the Waybar client to hang indefinitely if the server shuts down while the Waybar module is running.

### Config

Addressed by `jack`

| option           | typeof  | default      | description |
| ---------------- | ------- | -------------| ----------- |
| `format`         | string  | `{load}%`    | The format, how information should be displayed. This format is used when other formats aren't specified. |
| `format-connected` | string |             | This format is used when the module is connected to the JACK server. |
| `format-disconnected` | string |          | This format is used when the module is not connected to the JACK server. |
| `format-xrun`    | string  |              | This format is used for one polling interval, when the JACK server reports an xrun. |
| `realtime`       | bool    | `true`       | Option to drop real-time privileges for the JACK client opened by Waybar. |
| `tooltip`        | bool    | `true`       | Option to disable tooltip on hover. |
| `tooltip-format` | string  | `{bufsize}/{samplerate} {latency}ms` | The format of information displayed in the tooltip. |
| `interval`       | integer | `1`          | The interval in which the information gets polled. |
| `rotate`         | integer |              | Positive value to rotate the text label. |
| `max-length`     | integer |              | The maximum length in character the module should display. |
| `min-length`     | integer |              | The minimum length in characters the module should take up. |
| `align`          | float   |              | The alignment of the text, where 0 is left-aligned and 1 is right-aligned. If the module is rotated, it will follow the flow of the text. |
| `on-click`       | string  |              | Command to execute when clicked on the module. |
| `on-click-middle` | string |              | Command to execute when middle-clicked on the module using mousewheel. |
| `on-click-right` | string  |              | Command to execute when you right clicked on the module. |
| `on-update`      | string  |              | Command to execute when the module is updated. |

#### Format replacements:

| string                | replacement |
| ---------------| ----------- |
| `{load}`       | The current CPU load estimated by JACK. |
| `{bufsize}`    | The size of the JACK buffer. |
| `{samplerate}` | The samplerate at which the JACK server is running. |
| `{latency}`    | The duration, in ms, of the current buffer size. |
| `{xruns}`      | The number of xruns reported by the JACK server since starting Waybar. |

#### Examples:

```jsonc
"jack": {
    "format": "DSP {}%",
    "format-xrun": "{xruns} xruns",
    "format-disconnected": "DSP off",
    "realtime": true
}
```

### Style

- `#jack`
- `#jack.connected`
- `#jack.disconnected`
- `#jack.xrun`