- [Workspaces](#workspaces)
- [Window](#window)
- [Window Count](#window-count)
- [Language](#language)
- [Submap](#submap)

***

## Workspaces

The `workspaces` module displays the currently used workspaces in hyprland compositor.

### Configuration

Addressed by `hyprland/workspaces`

| option             | typeof  | default | description |
| ------------------ | ------- | ------- | ----------- |
| `active-only`      | bool    | `false` | If set to true only active workspace will be shown on bar. Unless a workspace is persistent, visible, or special. Otherwise all workspace groups are shown.|
| `hide-active`      | bool    | `false` | If set to true, the active workspace will be hidden. Unless a workspace is persistent or special |
| `all-outputs`      | bool    | `false` | If set to false workspaces group will be shown only in assigned output. Otherwise all workspace groups are shown.|
| `format`           | string  | `{id}`    | The format, how information should be displayed.|
| `format-icons`   | object   |          | Based on the workspace name and state, the corresponding icon gets selected.<br>See [`Icons`](#module-hyprland-configuration-icons)|
| `persistent-workspaces` | object |    | Lists workspaces that should always be shown, even when nonexistent.<br>See[`Persistent workspaces`](#persistent-workspaces) |
| `workspace-taskbar` | object |    | Show per-workspace taskbars with app icons (similar to `wlr/taskbar`) instead of text representations.<br>See[`Workspace taskbars`](#workspace-taskbars) |
| `persistent-only` | bool | `false` | If set to true only persistent workspaces will be shown on bar |
| `show-special`     | bool    | `false` | If set to true, will display special workspaces alongside regular workspaces|
| `special-visible-only`     | bool    | `false` | If this and show-special are to true, special workspaces will be shown only if visible.|
| `sort-by` | string | `DEFAULT` | How to sort workspaces |
| `window-rewrite` | object (see [example](#module-hyprland-window-rewrite-example)) | empty | An object of regexes to match against window classes (and/or titles, [see below](#module-hyprland-window-rewrite) and map to a new representation. Mapping `firefox` → ` `, for example.
| `window-rewrite-default` | string | `?` | The default representation to be used when a window does not match any rules configured in `window-rewrite`.
| `format-window-separator` | string | `<space>` | The string used to separate window representations from eachother.
| `move-to-monitor` | bool | `false` | If set to true, open the workspace on the current monitor when clicking on a workspace button. Otherwise, the workspace will open on the monitor where it was previously assigned. Analog to using `focusworkspaceoncurrentmonitor` dispatcher instead of `workspace` in Hyprland.
| `ignore-workspaces` | array | empty | An array of regexes to match against workspace names. If there's a match, the workspace will be ignored and won't be shown in your bar.
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |

#### Format replacements:
| string | replacement |
|--------|-------------|
| `{icon}` | Icon, as defined in *format-icons*. |
| `{name}` | Name of workspace assigned by compositor. |
| `{windows}` | All windows representations (ex. window icons) as configured by the user, separated by whichever separator the user configured. |

<a name="module-hyprland-window-rewrite"></a>

#### Window Rewrite Rules

The rules are regexes that may match against class, title, or both in order to fine tune window representation. In order to understand them, let's break the possible rules in 4 categories:

| How it appears in config | Category |
| --- | --- |
| `something` | Vague |
| `class<something>` | Class-only |
| `title<something>` | Title-only |
| `class<something1> title<something2>` | Hybrid |

When a user's config only contains "vague" rules, they will be used to match against windows **classes**. This is both for backwards compatibility and performance reasons: this feature originally supported only classes, since they *usually* don't change during a program's lifetime. When the title config was introduced, matching previously existing rules to both classes and titles wound cause a whole lot of "wrong" matches, so it's disabled by default. Additionally, matching against the title requires listening to window title changes via Hyprland's IPC, which is not necessary when not in use. 

When the config contains **at least one** "title-only" or "hybrid" rewrite rule, then all of the "vague" rules will match against **both class and title**. Though confusing at first, this is in place to allow users to define vague rules, where it doesn't matter whether the class or title matched.

Examples that use all 4 categories are available [below](#module-hyprland-window-rewrite-example).

<a name="module-hyprland-configuration-icons"></a>

#### Icons:

Additional to workspace name matching, the following `format-icons` can be set.

| port name    | note |
| ------------ | ---- |
| `active`     | Will be shown when workspace is active |
| `default`    | Will be shown when no string matches is found. |
| `empty` | Will be shown on active empty workspaces |
| `persistent` | Will be shown on non-active persistent workspaces |
| `special`    | Will be shown on non-active special workspaces |
| `urgent`    | Will be shown on non-active urgent workspaces |

#### Sort:

How to sort workspaces.

| name    | note |
| ------------ | ---- |
| `default`    | Default hyprland/workspaces sorting algorithm with custom prioritization |
| `id` | Sort workspaces by id |
| `name` | Sort workspaces by name |
| `number`     | Sort workspaces by number |
| `special-centered` | Default sorting with special workspaces in the center |

<a name="module-hyprland-window-rewrite-example"></a>

#### Window Rewrite Example

```jsonc
"hyprland/workspaces": {
  "format": "<sub>{icon}</sub>\n{windows}",
  "format-window-separator": "\n",
  "window-rewrite-default": "",
  "window-rewrite": {
    "title<.*youtube.*>": "", // Windows whose titles contain "youtube"
    "class<firefox>": "", // Windows whose classes are "firefox"
    "class<firefox> title<.*github.*>": "", // Windows whose class is "firefox" and title contains "github". Note that "class" always comes first.
    "foot": "", // Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
    "code": "󰨞",
	},
  ...
}
```

<details>

<summary>Screenshot</summary>

![](https://user-images.githubusercontent.com/25804378/270065881-acef7b73-e528-4648-82c1-ba70ea9f7804.png)


</details>

#### Persistent workspaces:
Each entry of `persistent-workspace` names a workspace that should always be shown. Associated with that value is a list of outputs indicating *where* the workspace should be shown, an empty list denoting all outputs

> [!WARNING]
> You have to explicitly set `workspace = <num>, monitor:<monitor>, persistent:true` in your Hyprland config in order to actually work<br>
> Here's an example of how it should set
> ```py
> # ... parts of config
>   workspace = 1, monitor:eDP-1, persistent:true
>   workspace = 2, monitor:eDP-1, persistent:true
>   workspace = 3, monitor:eDP-1, persistent:true
>   workspace = 4, monitor:eDP-1, persistent:true
> # ... another parts of config
> ```
```jsonc
"hyprland/workspaces": {
    "persistent-workspaces": {
             "*": 5, // 5 workspaces by default on every monitor
             "HDMI-A-1": 3 // but only three on HDMI-A-1
       }
}
```

```jsonc
"hyprland/workspaces": {
    "persistent-workspaces": {
      "1": [
        "DP-3" // workspace 1 shown on DP-3
      ],
      "2": [
        "DP-1" // workspace 2 shown on DP-1
      ],
      "3": [
        "DP-1" // workspace 3 shown on DP-1
      ],
    }
}
```

```jsonc
"hyprland/workspaces": {
   "persistent-workspaces": {
      "DP-3": [ 1 ], // workspace 1 shown on DP-3
      "DP-1": [ 2, 3 ], // workspaces 2 and 3 shown on DP-1
    }
}
```

#### Persistent workspaces example

```jsonc
"hyprland/workspaces": {
	"format": "{name}: {icon}",
	"format-icons": {
		"1": "",
		"2": "",
		"3": "",
		"4": "",
		"5": "",
		"active": "",
		"default": ""
	},
       "persistent-workspaces": {
             "*": 5, // 5 workspaces by default on every monitor
             "HDMI-A-1": 3 // but only three on HDMI-A-1
       }
}
```

#### Workspace taskbars:

Starting with Waybar 0.14, you can make `hyprland/workspaces` behave like `wlr/taskbar` where the window icons are grouped by workspace.

```jsonc
"hyprland/workspaces": {
    "workspace-taskbar": {
        // Enable the workspace taskbar. Default: false
        "enable": true,

        // If true, the active/focused window will have an 'active' class. Could cause higher CPU usage due to more frequent redraws. Default: false
        "update-active-window": true,

        // Format of the windows in the taskbar. Default: "{icon}". Allowed variables: {icon}, {title}
        "format": "{icon} {title:.20}",

        // Icon size in pixels. Default: 16
        "icon-size": 16,

        // Either the name of an installed icon theme or an array of themes (ordered by priority). If not set, the default icon theme is used.
        "icon-theme": "some_icon_theme",

        // Orientation of the taskbar ("horizontal" or "vertical"). Default: "horizontal".
        "orientation": "horizontal",

        // List of regexes. A window will NOT be shown if its window class or title match one or more items. Default: []
        "ignore-list": [ "code", "Firefox - .*" ],

        // Command to run when a window is clicked. Default: "" (switch to the workspace as usual). Allowed variables: {address}, {button}
        "on-click-window": "/some/arbitrary/script {address} {button}"
    }
}
```

If `workspace-taskbar.enable` is set to `false` (or undefined), the other fields in the `workspace-taskbar` object are ignored. If it is set to `true`, the following fields are ignored: `window-rewrite`, `window-rewrite-default`.

You can use the `on-click-window` config to set the command that will be executed when a specific window is clicked. For example: `hyprctl dispatch focuswindow address:{address}`.
- The pattern `{address}` will be replaced with the Hyprland address of the clicked window.
- The pattern `{button}` will be replaced with the pressed button number. See [GdkEventButton.button](https://api.gtkd.org/gdk.c.types.GdkEventButton.button.html).

#### Workspace Taskbars example:

![Workspace taskbars example](https://github.com/user-attachments/assets/c5387d8b-6612-442a-83af-2a0d881fa6db)

```jsonc
"hyprland/workspaces": {
    "format": "{icon}: {windows}",
    "format-window-separator": "",
    "workspace-taskbar": {
        "enable": true,
        "update-active-window": true,
        "format": "{icon} {title:.22}",
        "icon-size": 18,
        "on-click-window": "${SCRIPTS}/focus-window.sh {address} {button}"
    }
},
```

<details>

<summary>See CSS</summary>

```css
#workspaces button {
    font-family: "Cantarell";
    font-weight: bold;
    background-color: transparent;
    color: #ffffff;
    box-shadow: none;
    text-shadow: none;
    padding: 0px;
    border-radius: 0;
    padding-left: 5px;
    padding-right: 2px;
}

#workspaces .workspace-label {
    padding-left: 3px;
    border-top: 1px solid transparent;
}

#workspaces .taskbar-window {
    border-top: 1px solid transparent;
    font-weight: normal;
    padding-left: 5px;
    padding-right: 5px;
}

#workspaces button.visible .taskbar-window,
#workspaces button.visible .workspace-label {
    border-color: white;
}

#workspaces .taskbar-window.active {
    background-color: rgba(255, 255, 255, 0.15);
}

#workspaces .taskbar-window image {
    margin-top: 1px;
}

#workspaces button.urgent {
    background-color: @urgent-color;
}
```

</details>

<details>

<summary>See focus-window.sh</summary>

```sh
#!/bin/sh

address=$1

# https://api.gtkd.org/gdk.c.types.GdkEventButton.button.html
button=$2

if [ $button -eq 1 ]; then
    # Left click: focus window
    hyprctl keyword cursor:no_warps true
    hyprctl dispatch focuswindow address:$address
    hyprctl keyword cursor:no_warps false
elif [ $button -eq 2 ]; then
    # Middle click: close window
    hyprctl dispatch closewindow address:$address
fi
```

</details>

### Style

- *#workspaces*
- *#workspaces button*
- *#workspaces button.active*
- *#workspaces button.empty*
- *#workspaces button.persistent*
- *#workspaces button.special*
- *#workspaces button.visible*
- *#workspaces button.urgent*
- *#workspaces button.hosting-monitor*
  - Gets applied if workspace-monitor == waybar-monitor
- *#workspaces .workspace-label*
- *#workspaces .taskbar-window*
  - Only if `workspace-taskbar.enable` is `true`
- *#workspaces .taskbar-window.active*
  - Gets applied if the window is focused
  - Only if `workspace-taskbar.enable` and `workspace-taskbar.update-active-window` are `true`


#### The way the CSS is evaluated you need to order it in order of importance with last taking precedent.

#### Example: 

This order makes it so that my priority of styling is special cases override the norm. If you wanted to include persistent in here, I'd throw it in before empty, personally. 

![image](https://github.com/Alexays/Waybar/assets/1778670/6421e9ce-50be-4086-8045-688338d5fbe7)

Active Monitor: 
Green icon for active workspace. 
![image](https://github.com/Alexays/Waybar/assets/1778670/48c58198-aae4-42ac-802a-33b1e3db5e33)

Inactive Monitor:
Blue icon for visible but not active. 


***

## Window

The `window` module displays the title of the currently focused window of [Hyprland](https://github.com/hyprwm/Hyprland), the Wayland compositor.

### Configuration

Addressed by `hyprland/window`

| option             | typeof  | default | description |
| ------------------ | ------- | ------- | ----------- |
| `format`           | string  | `{title}`    | The format, how information should be displayed. On `{}` the current window title is displayed.|
| `max-length`       | integer |         | The maximum length in character the module should display. |
| `rewrite`          | object  | `{}`    | Rules to rewrite the module format output. The rules are identical to [those for `sway/window`](https://github.com/Alexays/Waybar/wiki/Module:-Sway#rewrite-rules). |
| `separate-outputs` | bool    | `false`   | Show the active window of the monitor the bar belongs to, instead of the focused window. |
| `icon`             | bool    | `false`   | Option to disable application icon.|
| `icon-size`        | integer | `24`      | Set the size of application icon.|

#### Format Replacements:
See the output of "hyprctl clients" for examples

| string           | replacement                              |
| ---------------- | ---------------------------------------- |
| `{class}`        | The current class of the focused window. |
| `{initialClass}` | The initial class of the focused window. |
| `{initialTitle}` | The initial title of the focused window. |
| `{title}`        | The current title of the focused window. |

#### Example:

```json
"hyprland/window": {
    "format": "👉 {}",
    "rewrite": {
        "(.*) — Mozilla Firefox": "🌎 $1",
        "(.*) - fish": "> [$1]"
    },
    "separate-outputs": true
}
```

### Style

- `#window`

The following classes can apply styles to *the entire Waybar* (see [the Sway module's page](https://github.com/Alexays/Waybar/wiki/Module:-Sway#style-1) for more info):
- `window#waybar.empty` When no windows are in the workspace
- `window#waybar.solo` When one tiled window is visible in the workspace (floating windows may be present)
- `window#waybar.<app_id>` Where `<app_id>` is the class (e.g. `chromium`) of the solo tiled window in the workspace (use *hyprctl clients* to see classes)
- `window#waybar.floating` When there are only floating windows visible in the workspace
- `window#waybar.fullscreen` When there is a fullscreen window in the workspace; useful with Hyprland's `fullscreen, 1` mode
- `window#waybar.swallowing` When there are hidden windows in the workspace; usually occurs due to window swallowing

#### Example:

This will change the color of the entire bar when either Chromium or kitty occupy the screen.
```css
#window {
    border-radius: 20px;
    padding-left: 10px;
    padding-right: 10px;
}

window#waybar.kitty {
    background-color: #111111;
    color: #ffffff;
}

window#waybar.chromium {
    background-color: #eeeeee;
    color: #000000;
}

/* make window module transparent when no windows present */
window#waybar.empty #window {
    background-color: transparent;
}
```

***

## Window Count

The `windowcount` module displays the number of windows in the current [Hyprland](https://github.com/hyprwm/Hyprland) workspace.

### Configuration

Addressed by `hyprland/windowcount`.

| option              | typeof | default | description                                                                                                 |
| ------------------- | ------ | ------- | ----------------------------------------------------------------------------------------------------------- |
| `format`            | string | `{}`    | The format for how information should be displayed. On {}, the current workspace window count is displayed. |
| `format-empty`      | string |         | Override the format when the workspace contains no windows.                                                 |
| `format-windowed`   | string |         | Override the format when the workspace contains no fullscreen windows.                                      |
| `format-fullscreen` | string |         | Override the format when the workspace contains a fullscreen window.                                        |
| `separate-outputs`  | bool   | `true`  | Show the active workspace window count of the monitor the bar belongs to, instead of the focused workspace. |

#### Example:

```jsonc
"hyprland/windowcount": {
    "format": "[{}]",
    "format-empty": "[X]",
    "format-windowed": "[T]",
    // "format-fullscreen": "[{}]",
    "separate-outputs": true
}
```

### Style

- `#windowcount`
- `window#waybar.empty #windowcount` When no windows are in the workspace
- `window#waybar.fullscreen #windowcount` When there is a fullscreen window in the workspace; useful with Hyprland's fullscreen, 1 mode

#### Example:

```css
/* Adding margin and padding */
#windowcount {
    margin-left: 0px;
    padding: 0px 5px;
}

/* Different background when empty */
window#waybar.empty #windowcount {
    background: darkred;
}

/* Hide the windowcount module when not in windowed mode (i.e. not fullscreen) */
window#waybar:not(.fullscreen) #windowcount {
    opacity: 0;
}
```

*** 

## Language

The `language` module displays the currently selected keyboard language (layout) for [Hyprland](https://github.com/hyprwm/Hyprland), the Wayland compositor.

### Configuration

Addressed by `hyprland/language`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | The format, how information should be displayed. On `{}` the current layout's full name is displayed.|
| `format-<lang>`  | string  |         | Provide an alternative name to display per language where <lang> is the language of your choosing. Can be passed multiple times with multiple languages as shown by the example below.| 
| `keyboard-name`  | string  |         | Which keyboard to use, from the output of `hyprctl devices`. You should use the option that begins with "at-translated-set..."|


#### Example:

```json
"hyprland/language": {
    "format": "Lang: {}",
    "format-en": "AMERICA, HELL YEAH!",
    "format-en-colemak_dh": "AMERICA (Colemak-DH), HELL YEAH",
    "format-tr": "As bayrakları",
    "keyboard-name": "at-translated-set-2-keyboard"
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

***

## Submap

The `submap` module displays the currently active submap similar to *sway/mode* for [Hyprland](https://github.com/hyprwm/Hyprland), the Wayland compositor.

### Configuration

Addressed by `hyprland/submap`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | The format, how information should be displayed. On {} the currently active submap is displayed. |
| `max-length`     | integer |         | The maximum length in character the module should display. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |
| `always-on` | bool  | `false`              | Option to display the widget even when there's no active submap. |
| `default-submap` | string  | `Default`              | Option to display the widget even when there's no active submap. |


#### Example:
```json
"hyprland/submap": {
    "format": "✌️ {}",
    "max-length": 8,
    "tooltip": false
}
```

### Style

- *#submap*
- *#submap.\<name\>*
