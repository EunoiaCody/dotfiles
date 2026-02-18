The `mpd` module displays information about a running "Music Player Daemon" instance. Note that waybar must be compiled with mpd support in order to use this module.

### Config

Addressed by `mpd`

| option                        | typeof  | default                        | description |
| ----------------------------- | ------- | ------------------------------ | ----------- |
| `server`                      | string  |                                | The network address or Unix socket path of the MPD server. If empty, connect to the default host (`MPD_HOST`). |
| `port`                        | integer |                                | The port MPD listens to. If empty, use the default port (`MPD_PORT`). |
| `password`                    | string  |                                | The password required to connect to the MPD server. If empty, no password is required or sent to MPD. |
| `interval`                    | integer | 10                             | The interval in which the connection to the MPD server is retried. |
| `timeout`                     | integer | 30                             | The timeout for the connection. Change this if your MPD server has a low `connection_timeout` setting. |
| `unknown-tag`                 | string  | "N/A"                          | The text to display when a tag is not present in the current song, but used in `format` |
| `format`                      | string  | "{album} - {artist} - {title}" | Information displayed when a song is playing or paused |
| `format-stopped`              | string  | "stopped"                      | Information displayed when the player is stopped. |
| `format-paused`               | string  |                                | This format is used when a song is paused. |
| `format-disconnected`         | string  | "disconnected"                 | Information displayed when the MPD server can't be reached. |
| `tooltip`                     | bool    | true                           | Option to enable tooltip on hover. |
| `tooltip-format`              | string  | "MPD (connected)"              | Tooltip information displayed when connected to MPD. |
| `tooltip-format-disconnected` | string  | "MPD (disconnected)"           | Tooltip information displayed when the MPD server can't be reached. |
| `artist-len` | integer |  | The maximum length to show of the Artist tag. If empty, no limit. |
| `album-len` | integer |  | The maximum length to show of the Album tag. If empty, no limit. |
| `album-artist-len` | integer |  | The maximum length to show of the Album Artist tag. If empty, no limit. |
| `title-len` | integer |  | The maximum length to show of the Title tag. If empty, no limit. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `state-icons`                 | object  | {}                             | Icon to show depending on the play/pause state of the player (`{ "playing": "...", "paused": "..." }`) |
| `consume-icons`               | object  | {}                             | Icon to show depending on the "consume" option (`{ "on": "...", "off": "..." }`) |
| `random-icons`                | object  | {}                             | Icon to show depending on the "random" option (`{ "on": "...", "off": "..." }`) |
| `repeat-icons`                | object  | {}                             | Icon to show depending on the "repeat" option (`{ "on": "...", "off": "..." }`) |
| `single-icons`                | object  | {}                             | Icon to show depending on the "single" option (`{ "on": "...", "off": "..." }`) |

### Format replacements

#### When playing/paused:

| string             | replacement |
| ------------------ | ----------- |
| `{artist}`         | The artist of the current song |
| `{albumArtist}`    | The artist of the current album |
| `{album}`          | The album of the current song |
| `{title}`          | The title of the current song |
| `{filename}`       | The filename of the current song (with extension) |
| `{date}`           | The date of the current song |
| `{volume}`         | The current volume in percent |
| `{elapsedTime}`    | The current position of the current song. To format as a date/time (see example configuration) |
| `{totalTime}`      | The length of the current song. To format as a date/time (see example configuration) |
| `{songPosition}`   | The position of the song in current queue. |
| `{queueLength}`    | The length of the current queue.  |
| `{stateIcon}`      | The icon corresponding the playing or paused status of the player (see `state-icons` option) |
| `{consumeIcon}`    | The icon corresponding the "consume" option (see `consume-icons` option) |
| `{randomIcon}`     | The icon corresponding the "random" option (see `random-icons` option) |
| `{repeatIcon}`     | The icon corresponding the "repeat" option (see `repeat-icons` option) |
| `{singleIcon}`     | The icon corresponding the "single" option (see `single-icons` option) |

#### When stopped:

| string             | replacement |
| ------------------ | ----------- |
| `{consumeIcon}`    | The icon corresponding the "consume" option (see `consume-icons` option) |
| `{randomIcon}`     | The icon corresponding the "random" option (see `random-icons` option) |
| `{repeatIcon}`     | The icon corresponding the "repeat" option (see `repeat-icons` option) |
| `{singleIcon}`     | The icon corresponding the "single" option (see `single-icons` option) |


#### When disconnected:

Currently, no format replacements when disconnected.

### Example

```jsonc
"mpd": {
    "format": "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ",
    "format-disconnected": "Disconnected ",
    "format-stopped": "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ",
    "interval": 10,
    "consume-icons": {
        "on": " " // Icon shows only when "consume" is on
    },
    "random-icons": {
        "off": "<span color=\"#f53c3c\"></span> ", // Icon grayed out when "random" is off
        "on": " "
    },
    "repeat-icons": {
        "on": " "
    },
    "single-icons": {
        "on": "1 "
    },
    "state-icons": {
        "paused": "",
        "playing": ""
    },
    "tooltip-format": "MPD (connected)",
    "tooltip-format-disconnected": "MPD (disconnected)"
}
```

### Style

- `#mpd`
- `#mpd.disconnected`
- `#mpd.stopped`
- `#mpd.playing`
- `#mpd.paused`