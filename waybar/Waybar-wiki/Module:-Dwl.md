- [Tags](#tags)
- [Window](#window)

IMPORTANT: Using these modules requires patching dwl with the [IPC](https://codeberg.org/dwl/dwl-patches/wiki/ipc) patch.

***

## Tags

The `tags` module displays the current tag state of [dwl](https://codeberg.org/dwl/dwl).

### Config

Addressed by `dwl/tags`

| option           | typeof   | default | description |
| ---------------- | -------  | ------- | ----------- |
| `num-tags`       | integer  | `9`     | The number of tags that configured in dwl. (Must match!).
| `tag-labels`     | array    |         | The label to display for each tag.
| `disable-click`  | bool     | `false` | If set to false, you can left click to set focused tag. Right click to toggle tag focus. If set to true this behavior is disabled.

### Style

- `#tags button`
- `#tags button.occupied`
- `#tags button.focused`
- `#tags button.urgent`

Note that occupied/focused/urgent status may overlap. That is, a tag may be both occupied and focused at the same time.

## Window

Addressed by *dwl/window*

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{title}`    | The format, how information should be displayed. |
| `rotate`         | integer | 	       | Positive value to rotate the text label. |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-right` | string  |         | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip`        | bool    | `true`  | Option to disable tooltip on hover. |
| `rewrite`        | object  | `{}`    | Rules to rewrite the module format output. See **rewrite rules**. |
| `icon`           | bool    | `false`  | Option to disable application icon. |
| `icon-size`           | integer    | `24`  | Set the size of application icon. |

#### Format Replacements:

| string     | replacement                       |
| ---------- | --------------------------------- |
| `{title}`  | The title of the focused window.  |
| `{app_id}` | The app_id of the focused window. |
| `{layout}`  | The layout of the focused window. ||

`title`: The title of the focused window.

`app_id`: The app_id of the focused window.

`layout`: The layout of the focused window.

#### Rewrite Rules:

`rewrite` is an object where keys are regular expressions and values are rewrite rules if the expression matches. Rules may contain references to captures of the expression.

Regular expression and replacement follow [ECMAScript rules](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Cheatsheet) ([formal definition](https://tc39.es/ecma262/#sec-regexp-regular-expression-objects)).

An expression must match fully to trigger the replacement; if no expression matches, the format output is left unchanged.

Invalid expressions (e.g., mismatched parentheses) are ignored.

#### Example 1:
```jsonc
"dwl/window": {
    "format": "{title}",
    "max-length": 50,
    "rewrite": {
       "(.*) - Mozilla Firefox": "🌎 $1",
       "(.*) - vim": " $1",
       "(.*) - zsh": " [$1]"
    }
}
```