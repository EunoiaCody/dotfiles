The `workspaces` module displays the current active workspaces in your Wayland compositor.

Note: To use this module, your compositor has to implement the `ext-workspace-v1` Wayland protocol.

Waybar needs to be built with `-Dexperimental=true` for `ext/workspaces` to be available (see [#1766](https://github.com/Alexays/Waybar/issues/1766)).

# Config
| option | typeof | default | description |
|--------|:------:|:-------:|-------------|
| `format`         | string  | `{name}` | The format, how information should be displayed. |
| `format-icons`   | array   |          | Based on the workspace name and state, the corresponding icon gets selected.<br>See [`Icons`](#module-workspaces-config-icons) |
| `sort-by-name`         | bool  | `true` | Should workspaces be sorted by name. |
| `sort-by-coordinates`         | bool  | `true` | Should workspaces be sorted by coordinates. Note that if both  *sort-by-name* and *sort-by-coordinates* are true sort by name will be first. If both are false - sort by id will be performed. |
| `sort-by-number` | bool | `false` | 	If set to true, workspace names will be sorted numerically. Takes presedence over any other sort-by option. |
| `all-outputs`         | bool  | `false` | If set to false workspaces group will be shown only in assigned output. Otherwise all workspace groups are shown. |
| `active-only`         | bool  | `false` | If set to true only active or urgent workspaces will be shown. |
| `persistent-workspaces` | json (see below) | empty | Lists workspaces that should always be shown, even when non existant. Doesn't work when *all-outputs* is true or on `ext/workspaces` |
| `on-click`         | Actions (see below)  |  | Can be used to activate or close workspaces when clicked on |

## Format replacements:
| string | replacement |
|--------|-------------|
| `{name}` | Name of workspace assigned by compositor. |
| `{icon}` | Icon, as defined in *format-icons*. |


<a name="module-workspaces-config-icons"></a>

#### Icons:

Additional to workspace name matching, the following `format-icons` can be set.

| port name    | note |
| ------------ | ---- |
| `default`    | Will be shown, when no string matches is found. |
| `urgent`     | Will be shown, when workspace is flagged as urgent. |
| `active`    | Will be shown, when workspace is active |

## Actions:
| string | action |
|--------|--------|
| `activate` | Switch to workspace. |
| `close` | Close the workspace. |

## Persistent workspaces:
Each entry of `persistent-workspace` names a workspace that should always be shown. Associated with that value is a list of outputs indicating *where* the workspace should be shown, an empty list denoting all outputs
```jsonc
"ext/workspaces": {
    "persistent-workspaces": {
        "3": [], // Always show a workspace with name '3', on all outputs if it does not exists
        "4": ["eDP-1"], // Always show a workspace with name '4', on output 'eDP-1' if it does not exists
        "5": ["eDP-1", "DP-2"] // Always show a workspace with name '5', on outputs 'eDP-1' and 'DP-2' if it does not exists
    }
}
```
n.b.: This currently doesn't work if `all-outputs` is true.

## Example for [Sway](./Module:-Sway):
```jsonc
"sway/workspaces": {
  "format": "{icon}",
  "on-click": "activate",
  "format-icons": {
    "1": "",
    "2": "",
    "3": "",
    "4": "",
    "5": "",
    "urgent": "",
    "active": "",
    "default": ""
  },
  "sort-by-number": true
}
```

## Example for [Hyprland](https://github.com/Alexays/Waybar/wiki/Module:-Hyprland#workspaces):
```jsonc
"hyprland/workspaces": {
  "format": "{icon}",
  "on-click": "activate",
  "format-icons": {
    "1": "",
    "2": "",
    "3": "",
    "4": "",
    "5": "",
    "urgent": "",
    "active": "",
    "default": ""
  },
  "sort-by-number": true
}
```

- See the [full documentation here](https://github.com/Alexays/Waybar/wiki/Module:-Hyprland#workspaces).

## Example for Labwc:
```jsonc
"ext/workspaces": {
    "format": "{name}",
    "sort-by-number": true,
    "on-click": "activate",
},
```

# Style

Note: Sway uses a different set of classes. Please see the [Sway](./Module:-Sway) module page.

- *#workspaces*
- *#workspaces button*
- *#workspaces button.active*
- *#workspaces button.visible*
- *#workspaces button.urgent*
- *#workspaces button.empty*
- *#workspaces button.persistent*
- *#workspaces button.hidden*