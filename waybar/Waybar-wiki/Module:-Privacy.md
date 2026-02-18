### Config

The privacy module displays if any application is capturing audio, sharing the screen or playing audio.

Addressed by `privacy`

| option                | typeof           | default                                           | description |
| --------------------- | ---------------- | ------------------------------------------------- | ----------- |
| `icon-spacing`        | integer          | `4`                                               | The spacing between each privacy icon. |
| `icon-size`           | integer          | `20`                                              | The size of each privacy icon. |
| `transition-duration` | integer          | `250`                                             | The reveal and hide transition duration |
| `modules`             | array of objects | `[{"type": "screenshare"}, {"type": "audio-in"}]` | Which privacy modules to monitor. See *Modules Configuration* for more information. |
| `expand`              | bool             | `false`                                           | Enables this module to consume all left over space dynamically. |
| `ignore-monitor`      | bool             | `true`                                            | Ignore streams with *stream.monitor* property. |
| `ignore`              | array of objects | `[]`                                              | Additional streams to be ignored. See *Ignore Configuration* for more information.|

#### Modules Configuration:

| option              | typeof  | default                                          | description |
| ------------------- | ------- | ------------------------------------------------ | ----------- |
| `type`              | string  | Can be `screenshare`, `audio-in`, or `audio-out` | Specifies which module to use and configure. |
| `tooltip`           | bool    | `true`                                           | Option to disable tooltip on hover. |
| `tooltip-icon-size` | integer | `24`                                             | The size of each icon in the tooltip. |

#### Ignore Configuration

| option              | typeof  |
| ------------------- | ------- |
| `type`              | string  |
| `name`              | string  |

#### Example:

```jsonc
"privacy": {
	"icon-spacing": 4,
	"icon-size": 18,
	"transition-duration": 250,
	"modules": [
		{
			"type": "screenshare",
			"tooltip": true,
			"tooltip-icon-size": 24
		},
		{
			"type": "audio-out",
			"tooltip": true,
			"tooltip-icon-size": 24
		},
		{
			"type": "audio-in",
			"tooltip": true,
			"tooltip-icon-size": 24
		}
	],
	"ignore-monitor": true,
	"ignore": [
		{
			"type": "audio-in",
			"name": "cava"
		},
		{
			"type": "screenshare",
			"name": "obs"
		}
	]
},
```

### Style

- *#privacy*
- *#privacy-item*
- *#privacy-item.screenshare*
- *#privacy-item.audio-in*
- *#privacy-item.audio-out*
