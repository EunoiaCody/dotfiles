## Overview:
 - Some modules support 'states' which allows percentage values to be used as styling triggers to apply a class when the value matches the declared state value.

#### States:

- Every entry (*state*) consists of a `<name>` (typeof: `string`) and a `<value>` (typeof: `integer`).
  - The `<value>` determines the percentage value above which a state is applied, except for the battery and pulseaudio modules, for which it is activated *below* the given value.
  - The state can be addressed as a CSS class in the `style.css`. The name of the CSS class is the `<name>` of the state.
  - Also each state can have its own `format`.
    Those can be configured via `format-<name>`.
    Or if you want to differentiate a bit more even as `format-<status>-<state>`. For more information see [custom formats](https://github.com/Alexays/Waybar/wiki/Module:-Battery#module-battery-config-format-custom).

#### Example:
```
"battery": {
    "bat": "BAT2",
    "interval": 60,
    "states": {
        "warning": 30,
        "critical": 15
    },
    "format": "{capacity}% {icon}",
    "format-icons": ["", "", "", "", ""],
    "max-length": 25
}
```

### Styling States

- `#battery.<state>`
  - `<state>` can be defined in the `config`. For more information see [`states`](https://github.com/Alexays/Waybar/wiki/Module:-Battery#module-battery-config-states)

#### Example:

- `#battery.warning: { background: orange; }`
- `#battery.critical: { background: red; }`