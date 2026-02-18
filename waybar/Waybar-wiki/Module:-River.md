- [Mode](#mode)
- [Tags](#tags)
- [Window](#window)
- [Layout](#layout)

***

## Mode

The `mode` module displays current mapping mode of [river](https://github.com/ifreund/river).

### Config

Addressed by `river/mode`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | The format, how information should be displayed. On `{}` data gets inserted. |
| `rotate`         | integer | 	       | Positive value to rotate the text label. |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-right` | string  |         | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |

#### Example:
```json
"river/mode": {
    "format": "mode: {}"
}
```

### Style

- `#mode`
- `#mode.<mode>`

***

## Tags

The `tags` module displays the current tag state of [river](https://github.com/ifreund/river).

### Config

Addressed by `river/tags`

| option           | typeof   | default | description |
| ---------------- | -------  | ------- | ----------- |
| `num-tags`       | integer  | `9`     | The number of tags that should be displayed. Max 32.
| `tag-labels`     | array    |         | The label to display for each tag.
| `disable-click`  | bool     | `false` | If set to false, you can left click to set focused tag. Right click to toggle tag focus. If set to true this behaviour is disabled.
| `set-tags`       | array    |         | The tags to set when left clicking on the corresponding label.
| `toggle-tags`    | array    |         | The tags to toggle when right clicking on the corresponding label.
| `hide-vacant`    | bool     | `false` | If set to true, empty tags that are not enabled will be hidden


#### Example:
This enables 5 tags and to support sticky tag (tag 32) set-tags is set with the 32 bit true so it will always be selected. 
```json
"river/tags": {
    "num-tags": 5,
    "set-tags": [
      2147483649,
      2147483650,
      2147483652,
      2147483656,
      2147483664
    ]
}
```

### Style

- `#tags button`
- `#tags button.occupied`
- `#tags button.focused`
- `#tags button.urgent`

Note that occupied/focused/urgent status may overlap. That is, a tag may be
both occupied and focused at the same time.

***

## Window

The `window` module displays the title of the currently focused window of [river](https://github.com/ifreund/river).

### Config

Addressed by `river/window`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | The format, how information should be displayed. On `{}` data gets inserted. |
| `rotate`         | integer | 	       | Positive value to rotate the text label. |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-right` | string  |         | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip`        | bool    | `true`  | Option to disable tooltip on hover. |

#### Example:
```json
"river/window": {
    "format": "{}"
}
```

### Style

- `#window`
- `#window.focused`

The `.focused` class is applied when the same output as the bar's is focused. This can be used to create an output focus indicator.

***

## Layout

The `layout` module displays the current [river](https://github.com/ifreund/river) layout as defined by the layout generator. 

### Config

Addressed by `river/layout`

| option            | typeof  | default | description |
| ----------------- | ------- | ------- | ----------- |
| `format`          | string  | `{}`    | The format, how information should be displayed. On {} data gets inserted. |
| `rotate`          | integer | 	    | Positive value to rotate the text label. |
| `max-length`      | integer |         | The maximum length in character the module should display. |
| `min-length`      | integer |         | The minimum length in characters the module should accept. |
| `align`           | integer |         | The alignment of the text, where 0 is left-aligned and 1 is right-aligned. If the module is rotated, it will follow the flow of the text. |
| `on-click`        | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |         | Command to execute when middle-clicked on the module using mousewheel. |
| `on-click-right`  | string  |         | Command to execute when you right-click on the module. |

#### Example:

```json
"river/layout": {
    "format": "{}",
    "min-length": 4,
    "align": "right"
}
```

### Style

- `#layout`
- `#layout.focused` Applied when the output this module's bar belongs to is focused.
- `#layout.<layout>` Style for a specific named layout