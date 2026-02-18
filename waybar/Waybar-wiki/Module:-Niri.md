These modules require niri >= 0.1.9.

- [Workspaces](#workspaces)
- [Window](#window)
- [Language](#language)

***

## Workspaces

The `workspaces` module displays the currently used workspaces in niri.

### Configuration

Addressed by `niri/workspaces`

| option             | typeof  | default | description |
| ------------------ | ------- | ------- | ----------- |
| `all-outputs`      | bool    | `false` | If set to false, workspaces will only be shown on the output they are on. If set to true all workspaces will be shown on every output.|
| `format`           | string  | `{value}`    | The format, how information should be displayed.|
| `format-icons`   | object   |          | Based on the workspace name and state, the corresponding icon gets selected.<br>See [`Icons`](#module-niri-configuration-icons)|
| `disable-click` | bool | `false` | If set to false, you can click to change workspace. If set to true this behaviour is disabled. |
| `disable-markup` | bool | `false` | If set to true, button label will escape pango markup. |
| `current-only` | bool | `false` | If set to true, only the active or focused workspace will be shown. |
| `on-update` | string | | Command to execute when the module is updated. |

#### Format replacements:

| string | replacement |
|--------|-------------|
| `{value}` | Name of the workspace, or index for unnamed workspaces, as defined by niri. |
| `{name}` | Name of the workspace for named workspaces. |
| `{icon}` | Icon, as defined in *format-icons*. |
| `{index}` | Index of the workspace on its output. |
| `{output}` | Output where the workspace is located. |

<a name="module-niri-configuration-icons"></a>

#### Icons:

Additional to workspace name matching, the following `format-icons` can be set.

| port name    | note |
| ------------ | ---- |
| `default`    | Will be shown when no string matches are found. |
| `focused`    | Will be shown when the workspace is focused. |
| `active`     | Will be shown when the workspace is active on its output. |

#### Example:

```jsonc
"niri/workspaces": {
	"format": "{icon}",
	"format-icons": {
		// Named workspaces
		// (you need to configure them in niri)
		"browser": "",
		"discord": "",
		"chat": "<b></b>",

		// Icons by state
		"active": "",
		"default": ""
	}
}
```

### Style

- `#workspaces`
- `#workspaces button`
- `#workspaces button.focused` The single focused workspace.
- `#workspaces button.active` The workspace is active (visible) on its output.
- `#workspaces button.empty` The workspace is empty.
- `#workspaces button.current_output` The workspace is from the same output as the bar that it is displayed on.
- `#workspaces button#niri-workspace-<name>` Workspaces named this, or index for unnamed workspaces.

#### The way the CSS is evaluated you need to order it in order of importance with last taking precedent.

***

## Window

The `window` module displays the title of the currently focused window in niri.

### Configuration

Addressed by `niri/window`

| option             | typeof  | default | description |
| ------------------ | ------- | ------- | ----------- |
| `format`           | string  | `{title}`    | The format, how information should be displayed. On `{}` the current window title is displayed.|
| `rewrite`          | object  | `{}`    | Rules to rewrite the module format output. The rules are identical to [those for `sway/window`](https://github.com/Alexays/Waybar/wiki/Module:-Sway#rewrite-rules). |
| `separate-outputs` | bool    | `false`   | Show the active window of the monitor the bar belongs to, instead of the focused window. |
| `icon`             | bool    | `false`   | Option to disable application icon.|
| `icon-size`        | integer | `24`      | Set the size of application icon.|

#### Format Replacements:

See the output of `niri msg windows` for examples.

| string           | replacement                              |
| ---------------- | ---------------------------------------- |
| `{title}`        | The current title of the focused window. |
| `{app_id}`       | The current app ID of the focused window.|

#### Example:

```json
"niri/window": {
	"format": "{}",
	"rewrite": {
		"(.*) - Mozilla Firefox": "🌎 $1",
		"(.*) - zsh": "> [$1]"
	}
}
```

### Style

- `#window`

The following classes can apply styles to *the entire Waybar* (see [the Sway module's page](https://github.com/Alexays/Waybar/wiki/Module:-Sway#style-1) for more info):
- `window#waybar.empty` When no windows are in the workspace
- `window#waybar.solo` When one tiled window is visible in the workspace (floating windows may be present)
- `window#waybar.<app_id>` Where `<app_id>` is the app ID (e.g. `neovide`) of the only window on the workspace (use `niri msg windows` to see app IDs).

#### Example:

This will change the color of the entire bar when either Alacritty or Chromium occupy the screen.
```css
#window {
    border-radius: 20px;
    padding-left: 10px;
    padding-right: 10px;
}

window#waybar.Alacritty {
    background-color: #111111;
    color: #ffffff;
}

window#waybar.chromium-browser {
    background-color: #eeeeee;
    color: #000000;
}

/* make window module transparent when no windows present */
window#waybar.empty #window {
    background-color: transparent;
}
```

*** 

## Language

The `language` module displays the currently selected keyboard language (layout) in niri.

### Configuration

Addressed by `niri/language`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | The format, how information should be displayed. On `{}` the current layout's full name is displayed.|
| `format-<lang>`  | string  |         | Provide an alternative name to display per language where <lang> is the language of your choosing. Can be passed multiple times with multiple languages as shown by the example below.|


#### Example:

```json
"niri/language": {
	"format": "Lang: {long}",
	"format-en": "AMERICA, HELL YEAH!",
	"format-tr": "As bayrakları"
}
```

### Style

- *#language*

#### Example:

```css
#language {
    border-radius: 20px;
    padding-left: 10px;
    padding-right: 10px;
}
```