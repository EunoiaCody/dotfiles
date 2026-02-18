The `mpris` module displays currently playing media via `libplayerctl`.

### Config

| option                        | typeof  | default                        | description |
| ----------------------------- | ------- | ------------------------------ | ----------- |
| `player` | string | playerctld | Name of the MPRIS player to attach to. Using the default value always follows the currenly active player. |
| `ignored-players` | array[string] | | Ignore updates of the listed players, when using playerctld. |
| `interval` | integer | | Refresh MPRIS information on a timer.
| `format` | string | `{player} ({status}) {dynamic}` | The text format.
| `format-[status]` | string | | The status-specific text format.
| `tooltip-format` | string | | Format of the default tooltip.
| `tooltip-format-[status]` | string | | Format of the tooltip when `[status]` is one of `playing`, `paused`, or `stopped`.
| `enable-tooltip-len-limits` | bool | `false` | This needs to be set to true for {dynamic} and hour truncations to work in tooltips. |
| `on-click` | string | play-pause | Overwrite default action toggles.
| `on-click-middle` | string | previous track | Overwrite default action toggles.
| `on-click-right` | string | next track | Overwrite default action toggles.
| `player-icons` | map[string]string | | Allows setting `{player-icon}` based on player-name property.
| `status-icons` | map[string]string | | Allows setting `{status-icon}` based on player status (`playing`, `paused`, `stopped`).
| `dynamic-order` | list[string] | `["title", "artist", "album", "position", "length"]` | Choose the order of items in `{dynamic}`, separated by `{dynamic-separator}`. If `position` and `length` are present and adjacent (in order), they will appear in the format `<small>[{position}/{length}]</small>`.
| `[format]-len` | integer | `-1` | Where `[format]` is the name of a format segment, this is the maximum length allowed for that replacement. If the length of the replacement is greater than this value, it will be truncated with the `ellipsis` character/string added to the end.
| `ellipsis` | string/char | `…` | The character to append to the end of a truncated format replacement.
| `dynamic-len` | integer | `-1` | If the total length of `{dynamic}` is greater than this value, start removing segments according to `dynamic-importance-order` to make the string fit within this defined limit.
| `dynamic-separator` | string | `  -  ` | The separator to use between segments of `dynamic-order`
| `dynamic-importance-order` | list[string] | `["title", "artist", "album", "position", "length"]` | Choose which format replacements to omit if the string would be longer than `dynamic-len`. Format replacement names that appear first are considered higher priority, any that come towards the end are the most likely to be removed.
| `rotate` | integer | | Positive value to rotate the text label. |

### Format replacements

#### When playing/paused:

| string             | replacement |
| ------------------ | ----------- |
| `{player}` | The name of the current media player |
| `{status}` | The current status (`playing`, `paused`, `stopped`) |
| `{artist}` | The artist of the current track |
| `{album}` | The album title of the current track |
| `{title}` | The title of the current track |
| `{length}` | Length of the track, formatted as HH:MM:SS |
| `{position}` | Current playback position in the track, formatted as HH:MM:SS |
| `{dynamic}` | Use `{artist}`, `{album}`, `{title}` and `{length}`, automatically omit empty values |
| `{player_icon}` | Chooses an icon from `player-icons` based on `{player}` |
| `{status_icon}` | Chooses an icon from `status-icons` based on `{status}` |

### Example

```jsonc
"mpris": {
	"format": "DEFAULT: {player_icon} {dynamic}",
	"format-paused": "DEFAULT: {status_icon} <i>{dynamic}</i>",
	"player-icons": {
		"default": "▶",
		"mpv": "🎵"
	},
	"status-icons": {
		"paused": "⏸"
	},
	// "ignored-players": ["firefox"]
}
```

### Style

- `#mpris`
- `#mpris.${status}`
- `#mpris.${player}`
