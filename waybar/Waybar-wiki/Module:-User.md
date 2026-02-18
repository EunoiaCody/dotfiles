The `user` module displays the current user name with avatar and system uptime.

### Config

Addressed by `user`

| option                | typeof  | default                    | description                                          |
| --------------------- | ------- | -------------------------- | ---------------------------------------------------- |
| `interval`            | integer | 60                         | The interval in which the information gets polled.   |
| `format`              | string  | `{user} {work_H}:{work_M}` | The format, how the information should be displayed. |
| `avatar`              | string  | `$HOME/.face`              | Path to custom image                                 |
| `height`              | integer | 30                         | Avatar height                                        |
| `width`               | integer | 30                         | Avatar width                                         |
| `icon`                | bool    | false                      | Option to enable avatar icon                         |
| `open-on-click`       | bool    | true                       | Option to enable path opening                        |
| `open-path`           | string  | `$HOME`                    | folder path                                          |
#### Format replacements:

| string                | replacement                  |
| ----------------------| -----------                  |
| `{up_H}`              | System startup time          |
| `{up_M}`              | System startup minute        |
| `{up_d}`              | System startup day           |
| `{up_m}`              | System startup month         |
| `{up_Y}`              | System startup year          |
| `{work_H}`            | System uptime hours by day   |
| `{work_M}`            | System uptime minutes        |
| `{work_S}`            | System uptime seconds        |
| `{work_d}`            | System startup days          |
| `{user}`              | Username                     |

#### Example:
```jsonc
"user": {
        "format": "{user} (up {work_d} days ↑)",
        "interval": 60,
        "height": 30,
        "width": 30,
        "icon": true,
}
```
