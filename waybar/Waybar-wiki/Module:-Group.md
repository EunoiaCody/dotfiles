Module groups allow stacking modules in the direction orthogonal to the bar direction. When the bar is positioned on the top or bottom of the screen, modules in a group are stacked vertically. Likewise, when positioned on the left or right, modules in a group are stacked horizontally.

### Config
Adressed by `group/<name>`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `orientation`    | string  |`"orthogonal"`| Sets the orientation of the group. Valid options are: `"horizontal"`, `"vertical"`, `"inherit"`, and `"orthogonal"`. |
|`modules`|array||List of modules to include in the group.|
|`drawer`|object||If left empty, the drawer is disabled. Otherwise, it's enabled and some additional configuration is made available. See [drawer](#drawer) for more info.

<a name="drawer"></a>

### Drawer

The drawer configuration makes the group show only the first module by default, hiding the rest until the mouse hovers over the group. Check the GIF to see an example of its interactivity.

<img src="https://github.com/Alexays/Waybar/assets/25804378/66139544-b075-4b49-85fb-ebba6dcf0556" height="200">

<details>

<summary>Config used in GIF</summary>

```jsonc
"group/group-power": {
    "orientation": "inherit",
    "drawer": {
        "transition-duration": 500,
        "children-class": "not-power",
        "transition-left-to-right": false,
    },
    "modules": [
        "custom/power", // First element is the "group leader" and won't ever be hidden
        "custom/quit",
        "custom/lock",
        "custom/reboot",
    ]
},
"custom/quit": {
    "format": "󰗼",
    "tooltip": false,
    "on-click": "hyprctl dispatch exit"
},
"custom/lock": {
    "format": "󰍁",
    "tooltip": false,
    "on-click": "swaylock"
},
"custom/reboot": {
    "format": "󰜉",
    "tooltip": false,
    "on-click": "reboot"
},
"custom/power": {
    "format": "",
    "tooltip": false,
    "on-click": "shutdown now"
}
```

</details>

When the drawer is enabled, the first module of the group is chosen as the "group leader", while the rest of the elements are the "drawer children". The "group leader" is always shown and will reveal the "drawer children" when hovered over.

#### Drawer Config

| option | typeof | default | description |
| --- | --- | --- | --- |
| `transition-duration` | int | 500 | The duration of the transition, in milliseconds. |
| `transition-left-to-right` | bool | `true` | Whether the transition goes from left-to-right or right-to-left. If the group is vertical, then this configuration is read as "top-to-bottom". |
| `children-class` | string | `"drawer-child"` | The CSS class to add to the children of the drawer, excluding the "group leader". Its purpose is simply to help with styling. |
|`click-to-reveal`|bool|false|Allows to reveal the hidden modules by clicking rather than mouse over.|

### Styling

To style a group use group's ID.

### Example
```
{
	"modules-right": ["group/hardware", "clock"],

	"group/hardware": {
		"orientation": "vertical",
		"modules": [
			"cpu",
			"memory",
			"battery"
		]
	},

	...
}
```
```
#hardware {
    background-color: #333333;
}
```
