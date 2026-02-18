The `keyboard-state` module displays the state of number lock, caps lock, and scroll lock.

You must be a member of the input group to use this module (run `usermod -a -G input [username]` as root, then reboot).

### Config
Addressed by `keyboard-state`
| option         | typeof        | default                                          | description |
|----------------|---------------|--------------------------------------------------|-------------|
| `interval`     | integer       | `1`                                              | Deprecated, this module uses event loop now, the interval has no effect. <br> The interval, in seconds, to poll the keyboard state. |
| `format`       | string/object | `"{name} {icon}"`                                | The format, how information should be displayed. If a string, the same format is used for all keyboard states. If an object, the fields "numlock", "capslock", and "scrolllock" each specify the format for the corresponding state. Any unspecified states use the default format. |
| `format-icons` | object        | `{"locked": "locked", "unlocked": "unlocked"}` | Based on the keyboard state, the corresponding icon gets selected. The same set of icons is used for number, caps, and scroll lock, but the icon is selected from the set independently for each. See `icons`. |
| `numlock`      | bool          | `false`                                        | Display the number lock state. |
| `capslock`     | bool          | `false`                                        | Display the caps lock state. |
| `scrolllock`   | bool          | `false`                                        | Display the scroll lock state. |
| `device-path`  | string        | chooses first valid input device               | Which libevdev input device to show the state of. Libevdev devices can be found in /dev/input. The device should support number lock, caps lock, and scroll lock events. |
| `binding-keys` | array         | [58, 69, 70]                                   | Customize the key to trigger this module, the key number can be find in `/usr/include/linux/input-event-codes.h` or running `sudo libinput debug-events --show-keycodes`. |

### Format replacements
| string   | replacement                         |
|----------|-------------------------------------|
| `{name}` | Caps, Num, or Scroll.               |
| `{icon}` | Icon, as defined in `format-icons`. |

### Name replacements example
```
"keyboard-state": {
    "numlock": true,
    "capslock": true,
    "format": {
        "numlock": "N {icon}",
        "capslock": "C {icon}"                                                                                                                                                       
    },
    "format-icons": {
        "locked": "",
        "unlocked": ""
    }
}
```

### Icons
The following format-icons can be set.
| string   | note                                                                     |
|----------|--------------------------------------------------------------------------|
| locked   | Will be shown when the keyboard state is locked. Default "locked".       |
| unlocked | Will be shown when the keyboard state is not locked. Default "unlocked". |

### Example
```
"keyboard-state": {
    "numlock": true,
    "capslock": true,
    "format": "{name} {icon}",
    "format-icons": {
        "locked": "",
        "unlocked": ""
    }
}
```

### Style
- `#keyboard-state`
- `#keyboard-state label`
- `#keyboard-state label.locked`