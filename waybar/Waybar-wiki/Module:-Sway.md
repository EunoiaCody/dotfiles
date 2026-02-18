- [Mode](#mode)
- [Window](#window)
- [Workspaces](#workspaces)
- [Scratchpad](#scratchpad)
- [Language](#language)

***

## Mode

The `mode` module displays the current binding mode of [sway](https://swaywm.org/).

### Config

Addressed by `sway/mode`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | The format, how information should be displayed. On `{}` data gets inserted. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |

#### Example:
```jsonc
"sway/mode": {
    "format": " {}",
    "max-length": 50
}
```

### Style

- `#mode`

## Window

The `window` module displays the title of the currently focused window in [sway](https://swaywm.org/).

### Config

Addressed by `sway/window`

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
| `all-outputs`    | bool    | `false` | If set to false, displays only title of the window on the same output as bar |
| `offscreen-css`  | bool    | `false` | Only effective when all-outputs is true. Adds style according to present windows on unfocused outputs instead of showing the focused window and style. |
| `offscreen-css-text` | bool    |         | Only effective when both all-outputs and offscreen-css are true. On screens currently not focused, show the given text along with that workspaces styles. |
| `icon`           | bool    | `false`  | Option to disable application icon. |
| `icon-size`           | integer    | `24`  | Set the size of application icon. |

#### Format Replacements:

| string     | replacement                       |
| ---------- | --------------------------------- |
| `{title}`  | The title of the focused window.  |
| `{app_id}` | The app_id of the focused window. |
| `{shell}`  | The shell of the focused window. It's 'xwayland' when the window is running through xwayland, otherwise it's 'xdg-shell'. |

#### Rewrite Rules:

`rewrite` is an object where keys are regular expressions and values are rewrite rules if the expression matches. Rules may contain references to captures of the expression.

Regular expression and replacement follow [ECMAScript rules](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Cheatsheet) ([formal definition](https://tc39.es/ecma262/#sec-regexp-regular-expression-objects)).

An expression must match fully to trigger the replacement; if no expression matches, the format output is left unchanged.

Invalid expressions (e.g., mismatched parentheses) are ignored.

#### Example 1:
```jsonc
"sway/window": {
    "format": "{title}",
    "max-length": 50,
    "rewrite": {
       "(.*) - Mozilla Firefox": "🌎 $1",
       "(.*) - vim": " $1",
       "(.*) - zsh": " [$1]"
    }
}
```
#### Example 2:
```jsonc
"sway/window": {
    "format": "{}",
    "max-length": 50,
    "all-outputs" : true,
    "offscreen-css" : true,
    "offscreen-css-text": "(inactive)",
    "rewrite": {
        "(.*) - Mozilla Firefox": " $1",
        "(.*) - fish": "> [$1]"
    },
}
```

### Style

- `#window`
- `window#waybar.empty` When no windows are in the workspace, or screen is not focused and `offscreen-css` option is not set
- `window#waybar.solo` When one tiled window is in the workspace
- `window#waybar.floating` When there are only floating windows in the workspace
- `window#waybar.stacked` When there is more than one window in the workspace and the workspace layout is stacked
- `window#waybar.tabbed` When there is more than one window in the workspace and the workspace layout is tabbed
- `window#waybar.tiled` When there is more than one window in the workspace and the workspace layout is splith or splitv
- `window#waybar.<app_id>` Where `app_id` is the app_id or `instance` name like (`chromium`) of the only window in the workspace 

Please note that the window module applies the additional css classes listed above to the whole waybar rather than the module widgets. The whole waybar is an element with the name "window" and the id "waybar", whereas the window module itself is an element with the name "box" and the id "window". So in most instances, you probably want to apply formatting to `window#waybar.<stylename> #window`. For better insight regarding css hierarchy, consider [GTK_DEBUG](https://github.com/Alexays/Waybar/wiki/Styling#interactive-styling).

Also, switching layouts does not change the style unless the focus is changed. At this point, sway does not provide events for layout switching and the module does not poll.

#### Example
```css
window#waybar {
  background-color: #990000;
}

window#waybar.empty {
  background-color: transparent;
}

window#waybar.empty #window {
  padding: 0px;
  margin: 0px;
  border: 0px;
/*  background-color: rgba(66,66,66,0.5); */ /* transparent */
  background-color: transparent;
}

window#waybar.solo #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background-color: #073642; /*base02*/
}

window#waybar.floating #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background-color: #b58900; /*yellow*/
}

window#waybar.tiled #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background-color: #cb4b16; /* orange */

}
window#waybar.stacked #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background: #2aa196; /*cyan*/
}
window#waybar.tabbed #window {
    padding-left: 5px;
    padding-right: 5px;
    color: #eee8d5; /* base2 */
    background: #859900; /*green*/
}

window#waybar.code {
    background-color: #007ACC;
}
```

## Workspaces

The `workspaces` module displays the currently used workspaces in [sway](https://swaywm.org/).

### Config

Addressed by `sway/workspaces`

| option           | typeof  | default  | description |
| ---------------- | ------- | -------- | ----------- |
| `all-outputs`    | bool    | `false`  | If set to `false`, workspaces will only be shown on the output they are on.<br>If set to `true` all workspaces will be shown on every output. |
| `format`         | string  | `{name}` | The format, how information should be displayed. |
| `format-icons`   | array   |          | Based on the workspace name and state, the corresponding icon gets selected.<br>See [`Icons`](#module-workspaces-config-icons) |
| `disable-scroll` | bool    | `false`  | If set to `false`, you can scroll to cycle through workspaces.<br>If set to `true` this behaviour is disabled. |
| `disable-click` | bool    | `false`  | If set to `false`, you can click to change workspace.<br>If set to `true` this behaviour is disabled. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `disable-scroll-wraparound` | bool | `false` | If set to `false`, scrolling on the workspace indicator will wrap around to the first workspace when reading the end, and vice versa.<br>If set to `true` this behavior is disabled. |
| `enable-bar-scroll` | bool | `false` | If set to `false`, you can't scroll to cycle throughout workspaces from the entire bar.<br>If set to `true` this behaviour is enabled. |
| `disable-markup` | bool    | `false`  | If set to `true`, button label will escape pango markup. |
| `current-only` | bool | `false` | If set to `true`. Only focused workspaces will be shown. |
| `persistent-workspaces` | json (see below) | empty | Lists workspaces that should always be shown, even when non existant |
| `numeric-first` | bool | `false` | If set to `true`, workspaces with a name that starts with a number are displayed in front of workspaces that do not start with a number. |
| `disable-auto-back-and-forth` | bool | `false` | Whether to disable `workspace_auto_back_and_forth` when clicking on workspaces. If this is set to `true`, clicking on a workspace you are already on won't do anything, even if `workspace_auto_back_and_forth` is enabled in the Sway configuration. |
| `warp-on-scroll` | bool | `true` | If set to `false`, waybar will ephemerally disable mouse_warping (see `man 5 sway`) while using the scroll wheel to switch workspaces |
| `window-rewrite` | object | `{}` | Regex rules to map window class to an icon or preferred method of representation for a workspace's window. |
| `window-rewrite-default` | `string` | `?` | The default method of representation for a workspace's window. This will be used for windows whose classes do not match any of the rules in `window-rewrite` |
| `format-window-separator` | `string` | ` ` | The separator to be used between windows in a workspace. |

#### Format replacements:

| string    | replacement |
| --------- | ----------- |
| `{value}`  | Name of the workspace, as defined by sway |
| `{name}`  | Number stripped from workspace value at colon e.g. "13:NAME" |
| `{icon}`  | Icon, as defined in `format-icons`. |
| `{index}` | Index of the workspace |
| `{output}` | Output where the workspace is located. |
| `{windows}` | Result from window-rewrite |

<a name="module-workspaces-config-icons"></a>

#### Icons:

Additional to workspace name matching, the following `format-icons` can be set.

| port name            | note |
| -------------------- | ---- |
| `default`            | Will be shown, when no string matches is found. |
| `urgent`             | Will be shown, when workspace is flagged as urgent|
| `focused`            | Will be shown, when workspace is focused |
| `persistent`         | Will be shown, when workspace is persistent one. |

If you don't want these additional icons to override your matched workspace icon for some workspaces, then you can list such workspaces in the
`high-priority-named` list (like `"high-priority-named": ["1", "2", "3"]`)

#### Persistent workspaces:
each entry of `persistent_workspace` names a workspace that should always be shown. Associated with that value is a list of outputs indicating *where* the workspace should be shown, an empty list denoting all outputs
```jsonc
"sway/workspaces": {
    "persistent-workspaces": {
        "3": [], // Always show a workspace with name '3', on all outputs if it does not exists
        "4": ["eDP-1"], // Always show a workspace with name '4', on output 'eDP-1' if it does not exists
        "5": ["eDP-1", "DP-2"] // Always show a workspace with name '5', on outputs 'eDP-1' and 'DP-2' if it does not exists
    }
}
```
n.b.: the list of outputs can be obtained from command line using `swaymsg -t get_outputs`


#### Example:

```jsonc
"sway/workspaces": {
    "disable-scroll": true,
    "all-outputs": true,
    "format": "{name}: {icon}",
    "format-icons": {
        "1": "",
        "2": "",
        "3": "",
        "4": "",
        "5": "",
        "urgent": "",
        "focused": "",
        "default": "",
        "high-priority-named": ["1", "2"]
    }
}
```

```jsonc
"sway/workspaces": {
  "format": "<span size='larger'>{name}</span> {windows}",
  "format-window-separator": " | ",
  "window-rewrite-default": "{name}",
  "window-format": "<span color='#e0e0e0'>{name}</span>",
  "window-rewrite": {
    "class<firefox> title<.*chat.gig.tech.*>": "",
    "class<kitty>": "",
  }
}
```

### Style

- `#workspaces button`
- `#workspaces button.visible`
- `#workspaces button.focused`
- `#workspaces button.urgent`
- `#workspaces button.persistent`
- `#workspaces button.empty`
- `#workspaces button.current_output`
- `#workspaces button#sway-workspace-${name}`  


## Scratchpad

The `scratchpad` module displays the scratchpad status in Sway.

### Configuration

Addressed by `sway/scratchpad`

| option           | typeof | default | description |
| ---------------- | ------ | ------- | ----------- |
| `format`         | string | `{icon} {count}` | The format, how information should be displayed. |
| `show-empty`     | bool   | `false`| Option to show module when scratchpad is empty. |
| `format-icons`   | array/object |  | Based on the current scratchpad window counts, the corresponding icon gets selected. |
| `tooltip`        | bool   | `true` | Option to disable tooltip on hover. |
| `tooltip-format` | string | `{app}: {title}` | The format, how information in the tooltip should be displayed. |
| `menu`           | string |        | Action that popups the menu. |
| `menu-file`      | string |        | Location of the menu descriptor file. There need to be an element of type GtkMenu with id `menu` |
| `menu-actions`   | array  |        | The actions corresponding to the buttons of the menu. |

#### Format Replacements

| string    | replacement |
| --------- | ----------- |
| `{icon}`  | Icon, as defined in `format-icons`.         |
| `{count}` | Number of windows in the scratchpad.        |
| `{app}`   | Name of the application in the scratchpad.  |
| `{title}` | Title of the application in the scratchpad. |

#### Example

```json
"sway/scratchpad": {
    "format": "{icon} {count}",
    "show-empty": false,
    "format-icons": ["", ""],
    "tooltip": true,
    "tooltip-format": "{app}: {title}"
}
```

### Style

- `#scratchpad`
- `#scratchpad.empty`

## Language
[sway/language](https://github.com/Alexays/Waybar/wiki/Module:-Language)