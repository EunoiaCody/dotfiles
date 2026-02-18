### Config

Addressed by `upower`

| option            | typeof  | default             | description |
| ----------------- | ------- | ------------------- | ----------- |
| `native-path`     | string  |                     |  The battery to monitor. Refer to the [Upower native-path](https://upower.freedesktop.org/docs/UpDevice.html#UpDevice--native-path). Can be obtained using `upower --dump`|
| `icon-size`       | integer | 20                  | Defines the size of the icons. |
| `format`          | string  | {percentage}        | The text format. |
| `format-alt`      | string  | {percentage} {time} | The text format when toggled. |
| `hide-if-empty`   | bool    | true                | Defines visibility of the module if no devices can be found. |
| `on-click`        | string  |                     | Command to execute when clicked on the module. |
| `tooltip`         | bool    | true                | Option to disable tooltip on hover. |
| `tooltip-spacing` | integer | 4                   | Defines the spacing between the tooltip device name and device battery status. |
| `tooltip-padding` | integer | 4                   | Defines the spacing between the tooltip window edge and the tooltip content. |
| `show-icon`       | bool    | true                | Option to disable battery icon. |

#### Format replacements:

| string                | replacement |
| ----------------------| ----------- |
| `{percentage}`        | The battery capacity in percentage. |
| `{time}`              | An estimated time either until empty or until fully charged depending on the charging state. |

#### Example:

```jsonc
"upower": {
     "icon-size": 20,
     "hide-if-empty": true,
     "tooltip": true,
     "tooltip-spacing": 20
}

"upower": {
     "native-path": "/org/bluez/hci0/dev_D4_AE_41_38_D0_EF",
     "icon-size": 20,
     "hide-if-empty": true,
     "tooltip": true,
     "tooltip-spacing": 20
}

"upower": {
     "native-path": "battery_sony_controller_battery_d0o27o88o32ofcoee",
     "icon-size": 20,
     "hide-if-empty": true,
     "tooltip": true,
     "tooltip-spacing": 20
}

"upower": {
     "show-icon": false,
     "hide-if-empty": true,
     "tooltip": true,
     "tooltip-spacing": 20
}
```

### Style

- `#upower`
- `#upower.charging`
- `#upower.discharging`
- `#upower.unknown-status`
