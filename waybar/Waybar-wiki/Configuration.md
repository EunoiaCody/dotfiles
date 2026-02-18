## Config file

The configuration uses the JSONC file format and is named `config` or `config.jsonc`.

Valid directories for this file are:
- `$XDG_CONFIG_HOME/waybar/`
- `~/.config/waybar/`
- `~/waybar/`
- `/etc/xdg/waybar/`
- `SYSCONFDIR/xdg/waybar` (if `SYSCONFDIR` set at the build time differs from `/etc`, e.g. `/usr/local/etc` on BSD systems)

A good starting point is the [default config](https://github.com/Alexays/Waybar/blob/master/resources/config.jsonc).

Also a minimal example config can be found on the [bottom of this page](#minimal-config).

All valid options for the modules are listed on the [modules page](https://github.com/Alexays/Waybar/wiki/Modules).

## Bar Config

| option           | typeof  | default      | description |
| ---------------- | ------- | -------------| ----------- |
| `layer`       | string | `bottom`            | Decide if the bar is displayed in front (`top`) of the windows or behind (`bottom`) them. |
| `output` | string|array |               Specifies on which screen this bar will be displayed. |
| `position`         | string  | `top` | Bar position, can be `top`,`bottom`,`left`,`right`. |
| `height`     | integer |              | Height to be used by the bar if possible, leave blank for a dynamic value. |
| `width`     | integer |              | Width to be used by the bar if possible, leave blank for a dynamic value. |
| `modules-left`		   | array | 				| Modules that will be displayed on the left. |
| `modules-center`		   | array | 				| Modules that will be displayed in the center. |
| `modules-right`		   | array | 				| Modules that will be displayed on the right. |
| `margin`         | string   |               | Margins value using the css format without units. |
| `margin-<top\|left\|bottom\|right>`         | integer   |               | Margins value without units. |
| `spacing`         | integer    | `4` | Size of gaps in between of the different modules. |
| `name`         | string   |               | Optional name added as a CSS class, for styling multiple waybars. |
| `mode`         | string   |               | Selects one of the preconfigured display modes. This is an equivalent of the [`sway-bar(5)`](https://github.com/swaywm/sway/blob/master/sway/sway-bar.5.scd) `mode` command and supports the same values: `dock`, `hide`, `invisible`, `overlay`.<br />Note: `hide` and `invisible` modes may be not as useful without Sway IPC.<br />Note: this option overrides `layer`, `exclusive` and `passthrough` options. |
| `start_hidden`    | bool  | `false` | Option to start the bar hidden.
| `modifier-reset`  | string  | `press` | 	Defines the timing of modifier key to reset the bar visibility. To reset the visibility of the bar with the press of the modifier key use `press`. Use `release` to reset the visibility upon the release of the modifier key and only if no other action happened while the key was pressed. This prevents hiding the bar when the modifier is used to switch a workspace, change binding mode or start a keybinding.
| `exclusive`       | bool | `true` | Option to request an exclusive zone from the compositor. Disable this to allow drawing application windows underneath or on top of the bar.<br/>Disabled by default for `overlay` layer. |
| `fixed-center`    | bool | `true` | Prefer fixed center position for the `modules-center` block. The center block will stay in the middle of the bar whenever possible. It can still be pushed around if other blocks need more space.<br/>When false, the center block is centered in the space between the left and right block. |
| `passthrough`     | bool | `false` | Option to pass any pointer events to the window under the bar.<br/>Intended to be used with either `top` or `overlay` layers and without exclusive zone.<br/>Enabled by default for `overlay` layer. |
| `ipc`     |  bool | `false` | Option to subscribe to the Sway IPC bar configuration and visibility events and control waybar with `swaymsg bar` commands.<br />Requires `bar_id` value from sway configuration to be either passed with the `-b` commandline argument or specified with the `id` option.<br />See [#1244](https://github.com/Alexays/Waybar/pull/1244) for the documentation and configuration examples. |
| `id`      | string|  | `bar_id` for the Sway IPC. Use this if you need to override the value passed with the `-b bar_id` commandline argument for the specific bar instance. |
| `include` | array |  | Paths to additional configuration files.<br/>Each file can contain a single object with any of the bar configuration options. In case of duplicate options, the first defined value takes precedence, i.e. including file -> first included file -> etc. Nested includes are permitted, but make sure to avoid circular imports.<br/>For a multi-bar config, the `include` directive affects only current bar configuration object. |
| `reload_style_on_change` | bool | `false` | Option to enable reloading the css style if a modification is detected on the style sheet file or any imported css files. |
| `on-sigusr1` | string | `toggle` | Action that is performed when receiving SIGUSR1 kill signal. Possible values: `show`, `hide`, `toggle`, `reload`, `noop`. |
| `on-sigusr2` | string | `reload` | Action that is performed when receiving SIGUSR2 kill signal. Possible values: `show`, `hide`, `toggle`, `reload`, `noop`.  |

## Module Config
It's suggested not to have multiple configurations for the same mouse button.
For example: `on-click`, `on-double-click`, `on-triple-click` are defined. When triple click is triggered the module will execute commands for `on-click`, `on-double-click`, `on-triple-click` sequentially because of Gdk provide such events. 

| option           | typeof  | default      | description |
| ---------------- | ------- | -------------| ----------- |
|`on-update` |string | | Command to execute when the module gets updated|
|`on-click` |string | | Command to execute when you left click on the module|
|`on-click-release` |string | | Command to execute when you release left button on module|
|`on-double-click` |string | | Command to execute when you double left click on the module|
|`on-triple-click` |string | | Command to execute when you triple left click on the module|
|`on-click-middle` |string | | Command to execute when you middle click on the module using mousewheel|
|`on-click-middle-release` |string | | Command to execute when you release mousewheel button on the module|
|`on-double-click-middle` |string | | Command to execute when you double middle click on the module using mousewheel|
|`on-triple-click-middle` |string | | Command to execute when you triple middle click on the module using mousewheel|
|`on-click-right` |string | | Command to execute when you right click on the module|
|`on-click-right-release` |string | | Command to execute when you release right button on the module|
|`on-double-click-right` |string | | Command to execute when you double right click on the module|
|`on-triple-click-right` |string | | Command to execute when you triple right click on the module|
|`on-click-backward` |string | | Command to execute when you click on the module using mouse backward button|
|`on-click-backward-release` |string | | Command to execute when you release mouse backward button on the module|
|`on-double-click-backward` |string | | Command to execute when you double click on the module using mouse backward button|
|`on-triple-click-backward` |string | | Command to execute when you triple click on the module using mouse backward button|
|`on-click-forward` |string | | Command to execute when you click on the module using mouse forward button|
|`on-click-forward-release` |string | | Command to execute when you release mouse forward button on the module using|
|`on-double-click-forward` |string | | Command to execute when you double click on the module using mouse forward button|
|`on-triple-click-forward` |string | | Command to execute when you triple click on the module using mouse forward button|
|`on-scroll-up` |string | | Command to execute when you scroll up on the module with the mouse wheel|
|`on-scroll-down` |string | | Command to execute when you scroll down on the module with the mouse wheel|
|`on-scroll-left` |string | | Command to execute when you tilt the mouse wheel left on the module|
|`on-scroll-right` |string | | Command to execute when you tilt the mouse wheel right on the module|

## Module actions config
It is possible to specify module actions (if the module supports them) under the "actions" block. Supported actions are described at the module definition pages.
Example:
```json
"clock": {
    "actions": {"on-click-right": "mode",
                "on-scroll-up": "shift_up",
                "on-scroll-down": "shift_down"
               }
}
```

## Module format

You can use [PangoMarkupFormat](https://docs.gtk.org/Pango/pango_markup.html#pango-markup).
e.g.
```jsonc
"format": "<span style=\"italic\">{}</span>"
```
If you use a unicode in the module format, you might encounter a scenario where Waybar displays information in the wrong direction. It's a unicode specification. Some of the ligatures can have "right-to-left" associated directional property. See [Bidi algorithm basics](https://www.w3.org/International/articles/inline-bidi-markup/uba-basics).
```jsonc
"format": "{icon} {capacity}%",
"format-icons": ["ﱉ","ﱊ","ﱌ","ﱍ","ﱋ"]
```
It can be handled by the using special attributes. In the example {icon} is wrapped by the left-to-right property.
```jsonc
"format": "&#x202b;{icon}&#x202c; {capacity}%",
"format-icons": ["ﱉ","ﱊ","ﱌ","ﱍ","ﱋ"]
```


## Multiple instances of a module

If you want to have a second instance of a module, you can suffix it by a '#' and a custom name.

For example if you want a second battery module, you can add `"battery#bat2"` to your modules.

To configure the newly added module, you then also add a module configuration with the same name. 

This could then look something like this *(this is an incomplete example)*:
```jsonc
"modules-right": ["battery", "battery#bat2"],
"battery": {
    "bat": "BAT1"
},
"battery#bat2": {
    "bat": "BAT2"
}
```
To style in ``style.css`` use :
```css
battery.bat2 {
    border-bottom: 2px solid #FFFFFF;
}
```

## Minimal config

A minimal `config` file could look like this:
```jsonc
{
    "layer": "top",
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["sway/window"],
    "modules-right": ["battery", "clock"],
    "sway/window": {
        "max-length": 50
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    "clock": {
        "format-alt": "{:%a, %d. %b  %H:%M}"
    }
}
```

## Multi output config
### Limit a configuration to some outputs
```jsonc
{
    "layer": "top",
    "output": "eDP-1",
    "modules-left": ["sway/workspaces", "sway/mode"],
    //...
}
```
```jsonc
{
    "layer": "top",
    "output": ["eDP-1", "VGA"],
    "modules-left": ["sway/workspaces", "sway/mode"],
    //...
}
```
### Configuration of multiple outputs
Don't specify an output to create multiple bars on the same screen
```jsonc
[{
    "layer": "top",
    "output": "eDP-1",
    "modules-left": ["sway/workspaces", "sway/mode"],
    //...
}, {
    "layer": "top",
    "output": "VGA",
    "modules-right": ["clock"],
    //...
}]
```
You can also exclude specific output(s) by using exclamation mark, for example:
```jsonc
[{
    "layer": "top",
    "output": "eDP-1",
    "modules-left": ["sway/workspaces", "sway/mode"],
    //...
}, {
    "layer": "top",
    "output": "!eDP-1",
    "modules-right": ["clock"],
    //...
}]
```
This will show the first bar on eDP-1, and the second bar on every output except eDP-1

### Rotating modules
When positioning Waybar on the left or right side of the screen, sometimes it's useful to be able to rotate the contents of a module so the text runs vertically. This can be done using the "rotate" property of the module. Example:
```jsonc
{
    "clock": {
        "rotate": 90
    }
}
```
Valid options for the "rotate" property are: 0, 90, 180 and 270.


### Share options for multiple bars
You probably want to share the same formatting and properties for repeated modules across bars. Put the shared configuration in another file, say, `default-modules.json`:
```jsonc
{
	"clock": {
		"tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
		"format": "{:%F %T}",
		"format-alt": "{:%F %T}",
		"interval": 1
	},

}
```
and just import it from `config`:
```jsonc
[{
	"layer": "top",
	"position": "bottom",
	"output": ["DP-1"],

	"include": [
		"~/.config/waybar/default-modules.json",
	],
	"modules-right": [
		"clock",
		"temperature",
	]
},
{
	"layer": "top",
	"position": "bottom",
	"output": ["HDMI-1"],

	"include": [
		"~/.config/waybar/default-modules.json",
	],
	"modules-right": [
		"clock",
	],

	"clock": {
		"on-click": "do_something",
	}
},
]
```

As you can see, you can add custom properties on top of the defaults. Local options get appended to the defaults. They override the default ones, if they already exist.

## Styling Multiple Bars
Using the "name" field, you can call it from the style.css file, like this:
(config file)
```css
{
  "name": "bar1"
   // desired settings
} 
```
(config2 file)
```css
{ 
 "name": "bar2"
 // desired settings
} 
``` 
In your style.css, you may want to call like this:
```css
.bar1 { 
  font-family: Arimo Nerd Font;
  font-size: 16px;
} 
.bar2 {
  font-family: Roboto;
  font-size: 16px;
} 
```

If your bars share the same modules, you can specify like this:
```css
window.bar1#waybar { 
  background-color: rgba(10, 9, 10, 0.87);
} 

window.bar2#waybar {
  background-color: transparent;
} 
```