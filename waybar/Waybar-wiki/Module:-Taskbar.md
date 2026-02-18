The `wlr/taskbar` module can be used to add a taskbar based on the foreign-toplevel-manager protocol. For this module to work, you need a wayland compositor that implements the protocol.
# Config
| option | typeof | default | description |
|--------|:------:|:-------:|-------------|
| `all-outputs` | bool | `false` | If set to `false` only applications on waybar's current output will be shown. Otherwise all applications will be shown. |
| `format` | string | `{icon}` | The format, how information should be displayed for applications. |
| `icon-theme` | string | | The name of the icon-theme that should be used. If omitted, the system default will be used. |
| `icon-size` | int | `16` | The size in pixels for the icon. |
| `markup` | bool | `false` | If set to `true` pango markup will be allowed in format/tooltip_format. |
| `tooltip` | bool | `true` | If set to `false` no tooltip will be shown. |
| `tooltip-format` | string | `{title}` | The format, how information in the tooltip should be displayed for applications. |
| `active-first` | bool | `false` | If set to true, always reorder the tasks in the taskbar so that the currently active one is first. Otherwise don't reorder. |
| `sort-by-app-id` | bool | `false` | If set to true, group tasks by their app_id. Cannot be used with ’active‐first’. |
| `on-click` | string | | The action which should be triggered when clicking on the applications button in the taskbar with the left mouse button. |
| `on-click-middle` | string | | The action which should be triggered when clicking on the applications button in the taskbar with the middle mouse button. |
| `on-click-right` | string | | The action which should be triggered when clicking on the applications button in the taskbar with the right mouse button. |
| `on-update` | string | | Command to execute when the module is updated. |
| `ignore-list` | array[string] | | List of app_id/titles to be invisible. |
| `app_ids-mapping` | object | | Dictionary of app_id to be replaced with. |
| `rewrite` | object | | Rules to rewrite the module format output. See **rewrite rules**. |

## Format replacements:
| string | replacement |
|--------|-------------|
| `{icon}` | The icon of the application. |
| `{title}` | The title of the application. |
| `{name}` | The name of the application. |
| `{app_id}` | The `app_id` of the application. |
| `{state}` | The state (minimized, maximized, active, fullscreen) of the application. |
| `{short_state}` | The state represented as one character (minimized == m, maximized == M, active == A, fullscreen == F) of the application. |

Note: Like all format replacements in waybar, `{title:.15}` places a length limit of 15 bytes on the replaced `title` string.  This may result in invalid text if a multi-byte character is present or (if `markup` is true) if the text includes values that must be escaped in XML.

## Actions:
| string | action |
|--------|--------|
| `activate` | Bring the application into foreground. |
| `minimize` | Toggle application's minimized state. |
| `minimize-raise` | Bring the application into foreground or toggle its minimized state. |
| `maximize` | Toggle application's maximized state. |
| `fullscreen` | Toggle application's fullscreen state. |
| `close` | Close the application. |

## Rewrite Rules:

`rewrite` is an object where keys are regular expressions and values are rewrite rules if the expression matches. Rules may contain references to captures of the expression.

Regular expression and replacement follow [ECMAScript rules](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Cheatsheet) ([formal definition](https://tc39.es/ecma262/#sec-regexp-regular-expression-objects)).

An expression must match fully to trigger the replacement; if no expression matches, the format output is left unchanged.

Invalid expressions (e.g., mismatched parentheses) are ignored.

## Example:
```jsonc
"wlr/taskbar": {
    "format": "{icon}",
    "icon-size": 14,
    "icon-theme": "Numix-Circle",
    "tooltip-format": "{title}",
    "on-click": "activate",
    "on-click-middle": "close",
    "ignore-list": [
       "Alacritty"
    ],
    "app_ids-mapping": {
      "firefoxdeveloperedition": "firefox-developer-edition"
    },
    "rewrite": {
        "Firefox Web Browser": "Firefox",
        "Foot Server": "Terminal"
        ".*(steam_app_[0-9]+).*": "Game"

    }
}
```
# Style

- `#taskbar`
- `#taskbar button`
- `#taskbar button.active`
- `#taskbar button.minimized`
- `#taskbar button.maximized`
- `#taskbar button.fullscreen`
- `#taskbar.empty`