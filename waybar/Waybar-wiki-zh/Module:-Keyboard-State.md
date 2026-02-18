`keyboard-state` 模块显示数字锁定键、大写锁定键和滚动锁定键的状态。

你必须是 input 组的成员才能使用此模块（以 root 身份运行 `usermod -a -G input [username]`，然后重启）。

### 配置
通过 `keyboard-state` 引用
| option         | typeof        | default                                          | description |
|----------------|---------------|--------------------------------------------------|-------------|
| `interval`     | integer       | `1`                                              | 已弃用，此模块现在使用事件循环，interval 不再生效。<br> 轮询键盘状态的间隔时间，单位为秒。 |
| `format`       | string/object | `"{name} {icon}"`                                | 信息的显示格式。如果是字符串，则所有键盘状态使用相同的格式。如果是对象，"numlock"、"capslock" 和 "scrolllock" 字段分别指定对应状态的格式。未指定的状态使用默认格式。 |
| `format-icons` | object        | `{"locked": "locked", "unlocked": "unlocked"}` | 根据键盘状态，选择对应的图标。数字锁定、大写锁定和滚动锁定使用相同的图标集，但每个锁定键独立从集合中选择图标。参见 `icons`。 |
| `numlock`      | bool          | `false`                                        | 显示数字锁定键状态。 |
| `capslock`     | bool          | `false`                                        | 显示大写锁定键状态。 |
| `scrolllock`   | bool          | `false`                                        | 显示滚动锁定键状态。 |
| `device-path`  | string        | chooses first valid input device               | 要显示状态的 libevdev 输入设备。Libevdev 设备可在 /dev/input 中找到。该设备应支持数字锁定、大写锁定和滚动锁定事件。 |
| `binding-keys` | array         | [58, 69, 70]                                   | 自定义触发此模块的按键，按键编号可在 `/usr/include/linux/input-event-codes.h` 中找到或通过运行 `sudo libinput debug-events --show-keycodes` 获取。 |

### 格式替换
| string   | replacement                         |
|----------|-------------------------------------|
| `{name}` | Caps、Num 或 Scroll。               |
| `{icon}` | 图标，在 `format-icons` 中定义。 |

### 名称替换示例
```
"keyboard-state": {
    "numlock": true,
    "capslock": true,
    "format": {
        "numlock": "N {icon}",
        "capslock": "C {icon}"                                                                                                                                                       
    },
    "format-icons": {
        "locked": "",
        "unlocked": ""
    }
}
```

### 图标
可以设置以下 format-icons。
| string   | note                                                                     |
|----------|--------------------------------------------------------------------------|
| locked   | 当键盘状态为锁定时显示。默认为 "locked"。       |
| unlocked | 当键盘状态未锁定时显示。默认为 "unlocked"。 |

### 示例
```
"keyboard-state": {
    "numlock": true,
    "capslock": true,
    "format": "{name} {icon}",
    "format-icons": {
        "locked": "",
        "unlocked": ""
    }
}
```

### 样式
- `#keyboard-state`
- `#keyboard-state label`
- `#keyboard-state label.locked`
