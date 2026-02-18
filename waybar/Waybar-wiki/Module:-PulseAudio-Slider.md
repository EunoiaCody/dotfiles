The `pulseaudio/slider` module displays and controls the current volume of the default sink or source as a bar.

The volume can be controlled by dragging the slider across the bar, or clicking on a specific position.

## CONFIGURATION

| option | typeof | default | description |
| --- | --- | --- | --- |
| `min` | int | 0 | The minimum volume value the slider should display and set. |
| `max` | int | 100 | The maximum volume value the slider should display and set. |
| `orientation` | string | `horizontal` | The orientation of the slider. Can be either `horizontal` or `vertical`. |

> [!NOTE]
> As well as the JSON configuration, the slider modules are special in the sense that they **require** styling to work. Read more about it [here](https://github.com/Alexays/Waybar/wiki/FAQ#slider-looks-small). The TL;DR is that you **need** to set `min-width` and/or `min-height` (depending on whether your slider is vertical or not) for it to display correctly. That's a GTK detail, not an issue with Waybar.

## EXAMPLES

```json
"modules-right": [
    "pulseaudio/slider",
],
"pulseaudio/slider": {
    "min": 0,
    "max": 100,
    "orientation": "horizontal"
}
```

## STYLE

The slider is a component with multiple CSS Nodes, of which the following are exposed:

- **#pulseaudio-slider**:
    Controls the style of the box *around* the slider and bar.

- **#pulseaudio-slider slider**:
    Controls the style of the slider handle.

- **#pulseaudio-slider trough**:
    Controls the style of the part of the bar that has not been filled.

- **#pulseaudio-slider highlight**:
    Controls the style of the part of the bar that has been filled.

### STYLE EXAMPLE

```css
#pulseaudio-slider {
    padding: 0;
    margin: 0;
}
#pulseaudio-slider slider {
    min-height: 0px;
    min-width: 0px;
    opacity: 0;
    background-image: none;
    border: none;
    box-shadow: none;
}
#pulseaudio-slider trough {
    min-height: 10px;
    min-width: 80px;
    border-radius: 5px;
    background: black;
}
#pulseaudio-slider highlight {
    min-width: 10px;
    border-radius: 5px;
    background: green;
}
```