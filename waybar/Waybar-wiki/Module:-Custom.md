The `custom` module displays either the output of a script or static text. To display static text, specify only the `format` field.

### Config

Addressed by `custom/<name>`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `exec`           | string  |                    |         | The path to the script, which should be executed. |
| `exec-if`        | string  |         | The path to a script, which determines if the script in `exec` should be executed.<br>`exec` will be executed if the exit code of `exec-if` equals 0. |
| `exec-on-event`  | bool    | `true`  | If an event command is set (e.g. `on-click` or `on-scroll-up`) then re-execute the script. There are no guarantees that `exec` is executed after the `on-*` event commands finished. See https://github.com/Alexays/Waybar/pull/1784 for a possible patch. |
| `hide-empty-text`| bool    | `false` | (Post-0.10.3 option) Disables the module when output is empty, but format might contain additional static content. |
| `return-type`    | string  |         | See [`return-type`](#module-custom-config-return-type) |
| `interval`       | integer |         | The interval (in seconds) in which the information gets polled.<br>Use `once` if you want to execute the module only on startup. You can update it manually with a signal. If no `interval` is defined, it is assumed that the out script loops it self. |
| `restart-interval`       | integer |         | The restart interval (in seconds).<br>Can't be used with the *interval* option, so only with continuous scripts.<br>Once the script exit, it'll be re-executed after the *restart-interval*. |
| `signal`         | integer |         | The signal number used to update the module. The number is valid between 1 and  N,  where  `SIGRTMIN+N` = `SIGRTMAX`. |
| `format`         | string  | `{}`    | The format, how information should be displayed. On `{}` data gets inserted. |
| `format-icons`   | array/object/string   |         | If the type is an array, then based on the set percentage, the corresponding icon gets selected (*low* to *high*).<br>If the type is an object, then the icon will be selected according to `alt` string from the output.<br>If the type is a string, it will be pasted as is.<br>**NOTE**: Arrays can be nested into objects. Icons will be selected first according to `alt` then percentage. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `min-length`     | integer |         | The minimum length in character the module should display. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |
| `tooltip-format` | string  |             | The format of the tooltip. |
| `escape` 	| bool  | `false` | Option to enable escaping of script output |

<a name="module-custom-config-return-type"></a>

#### Return-Type:

- When `return-type` is set to `json`, Waybar expects the `exec`-script  to output its data in JSON format.
  This should look like this: `{"text": "$text", "alt": "$alt", "tooltip": "$tooltip", "class": "$class", "percentage": $percentage }`. This means the output should also be on a single line. This can be achieved by piping the output of your script through `jq --unbuffered --compact-output`. The `class` parameter also accepts an array of strings. 
- If you want to have multiline tooltips, use `\r` in your script
    - If using PowerShell for scripting, use the standard newline operator "\`n" in double quotes; `\r` and `\n` will not work.
- If nothing or an invalid option is specified Waybar expects i3blocks style output, where values are `newline` separated.
  This should look like this: `$text\n$tooltip\n$class`

`class` is a CSS class, to apply different styles in `style.css`

#### Continuous script:

The `exec` script may be continuous (i.e. contain some kind of infinite loop). The display will be updated for each new line of data on stdout (following the chosen [`return-type`](#module-custom-config-return-type)).

The `interval` option does not work with continuous script (no need to call it several times… as it will continuously run). However you might want to set the `restart-interval` to start again the script if it stops after some time.

Be warned that some technologies use a buffer for their output. If your module displays nothing even if your script is working as expected, the output might be hold temporarily in a buffer. Look for the correct way to flush the output buffer for your language of choice.

For example, in ruby you can do the following thing:

```ruby
loop do
  puts { text: 'My module text', class: 'class', … }.to_json
  $stdout.flush
  sleep 5
end
```

#### Format replacements:

| string             | replacement |
| ------------------ | ----------- |
| `{}` | Output of the script. |
| `{percentage}` | Percentage which can be set via a json return-type. |
| `{icon}` | An icon from 'format-icons' according to percentage. |
| `{text}` | The text which can be set via a json return-type. |
| `{alt}` | The alt which can be set via a json return-type. |

The `{}` placeholder is special: it automatically displays the text output from your script.
However, `{}` cannot be combined with other placeholders like `{icon}` in the format string — using both together will not work as expected.

For example, if you want to display both an icon from `format-icons` and some text, you should use `{icon}` and `{text}` explicitly:
```json
"custom/media": {
    "exec": "/path/to/your/awesome/script",
    "format": "{icon} {text}",
    "format-icons": {
      "spotify": "",
      "default": "🎵"
    }
}
```
In this example:  
- `{icon}` shows an icon based on the "alt" field returned by your awesome script  
- `{text}` shows the value of the "text" field from your script’s JSON output

### Tooltip Format
`tooltip-format` can receive any of the above format replacements.

If the output of the custom script specifies a value in the `tooltip` field, this is the default. Otherwise, it is `{}`.

### Style

- `#custom-<name>`
- `#custom-<name>.<class>`
  - `<class>` can be set by the script. For more information see [`return-type`](#module-custom-config-return-type)

### Output name

The `exec` script will have `WAYBAR_OUTPUT_NAME` set to the name of the output the bar is on.

### Troubleshooting

#### Self-looping module don't show up

If your module is self-looping, and it doesn't even show up in the bar, check that:

1. Its configuration does __not__ include an `interval` parameter
2. Output to stdout is not buffered (see [#2358](https://github.com/Alexays/Waybar/discussions/2358))

#### Custom json class not displayed

If you have a json class in your custom script that is not displayed by styles.css, the json with more variables must be displayed first (see [#3234](https://github.com/Alexays/Waybar/issues/3234))