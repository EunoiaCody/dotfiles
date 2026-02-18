## Module: Wayfire

- [Workspaces](#workspaces)
- [Window](#window)

---

## Workspaces

The `workspaces` module displays the currently used workspaces in wayfire.

### Configuration

Addressed by `wayfire/workspaces`

| Option           | Type   | Default   | Description                                                               |
| ---------------- | ------ | --------- | ------------------------------------------------------------------------- |
| `format`         | string | `{value}` | The format that defines how information is displayed                      |
| `format-icons`   | array  |           | Selects an icon based on workspace name, index, and state (see **Icons**) |
| `disable-click`  | bool   | `false`   | If `true`, clicking to change workspaces is disabled                      |
| `disable-markup` | bool   | `false`   | If `true`, button labels will escape Pango markup                         |
| `current-only`   | bool   | `false`   | If `true`, only the active or focused workspace is shown                  |
| `on-update`      | string |           | Command to execute when the module updates                                |
| `expand`         | bool   | `false`   | Allows the module to consume leftover space dynamically                   |


### Formats replacements

| String | Replacements |
|------------|-------------|
| `{icon}`   | Icon, as defined in *format-icons*. |
| `{index}`  | Index of the workspace on its output. |
| `{output}` | Output where the workspace is located. |

### Icons
Additional to workspace name matching, the following format-icons can be set.

|port | note |
|-----------|--------------|
| `default` | Will be shown, when no string matches are found. |
| `focused` |Will be shown, when workspace is focused. |

### Examples

```jsonc
"wayfire/workspaces": {
  "format": "{icon}",
  "format-icons": {
    "1": "",
    "2": "",
    "3": "",
    "4": "",
    "5": "",
    "focused": "",
    "default": ""
  }
}
```

### Style
- *#workspaces button*
- *#workspaces button.focused*   
- *#workspaces button.empty*    
- *#workspaces button.current_output*

---

## Window

### Description

The **window** module displays the title of the currently focused window in **Wayfire**.

### Configuration

**Module name:** `wayfire/window`

### Options

| Option       | Type    | Default   | Description |
|-------------|---------|-----------|-------------|
| `format`    | string  | `{title}` | The format, how information should be displayed. On {} the current window title is displayed. |
| `rewrite`   | object  | —         | Rules used to rewrite the window title. See [Rewrite Rules](#rewrite-rules). |
| `icon`      | bool    | `false`   | Show or hide the application icon. |
| `icon-size` | integer | `24`      | Option to change the size of the application icon. |
| `expand`    | bool    | `false`   | Enables this module to consume all left over space dynamically. |

### Format Replacements

|string       |	replacement |
|-------------|--------------|
|{title}:     | The current title of the focused window.|
|{app_id}:    | The current app ID of the focused window. |

### Rewrite rules
rewrite is an object where keys are regular expressions and values are rewrite rules if the expression matches. Rules may contain references to captures of the expression.

Regular expression and replacement follow ECMA-script rules.<br>

If no expression matches, the title is left unchanged.<br>

Invalid expressions (e.g., mismatched parentheses) are skipped.

##Examples

```
"wayfire/window": {
	"format": "{}",
	"rewrite": {
		"(.*) - Mozilla Firefox": "🌎 $1",
		"(.*) - zsh": "> [$1]"
	}
}
```

### Style
- *#window*
- *#window#waybar.empty #window* When no windows are on the workspace

The following classes are applied to the entire Waybar rather than just the window widget:  
- *#window#waybar.empty*  When no windows are in the workspace  
- *#window#waybar.solo*   When only one window is on the workspace  
- *#window#waybar.*       Where app-id is the app ID of the only window on the workspace  