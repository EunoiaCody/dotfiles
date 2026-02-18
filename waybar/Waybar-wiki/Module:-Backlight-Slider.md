The `backlight/slider` module displays and controls the current brightness of the default or preferred device.

The brightness can be controlled by dragging the slider across the bar, or clicking on a specific position.

## CONFIGURATION

| option | typeof | default | description |
| --- | --- | --- | --- |
| `min` | int | 0 | The minimum value the slider should display and set. |
| `max` | int | 100 | The maximum value the slider should display and set. |
| `orientation` | string | `horizontal` | The orientation of the slider. Can be either `horizontal` or `vertical`. |
| `device` | string | | The name of the preferred device to control. If left empty, a device will be chosen automatically. |

> [!NOTE]
> As well as the JSON configuration, the slider modules are special in the sense that they **require** styling to work. Read more about it [here](https://github.com/Alexays/Waybar/wiki/FAQ#slider-looks-small). The TL;DR is that you **need** to set `min-width` and/or `min-height` (depending on whether your slider is vertical or not) for it to display correctly. That's a GTK detail, not an issue with Waybar.

> [!WARNING]
> If `min` is set to `0` (default), the slider can set brightness to `0`, which may completely disable the backlight on some devices.
> This can make the screen fully black. Consider setting a small minimum value (e.g. `10`) or configuring brightness keybinds as a fallback.

## EXAMPLES

```json
"modules-right": [
    "backlight/slider",
],
"backlight/slider": {
    "min": 0,
    "max": 100,
    "orientation": "horizontal",
    "device": "intel_backlight"
}
```

## STYLE

The slider is a component with multiple CSS Nodes, of which the following are exposed:

- **#backlight-slider**:
    Controls the style of the box *around* the slider and bar.

- **#backlight-slider slider**:
    Controls the style of the slider handle.

- **#backlight-slider trough**:
    Controls the style of the part of the bar that has not been filled.

- **#backlight-slider highlight**:
    Controls the style of the part of the bar that has been filled.

### STYLE EXAMPLE

```css
#backlight-slider slider {
    min-height: 0px;
    min-width: 0px;
    opacity: 0;
    background-image: none;
    border: none;
    box-shadow: none;
    background: none;
}
#backlight-slider trough {
    min-height: 10px;
    min-width: 80px;
    border-radius: 5px;
    background: black;
}
#backlight-slider highlight {
    min-width: 10px;
    border-radius: 5px;
    background: red;
}
```