## 概述：
 - 一些模块支持"states"（状态），允许使用百分比值作为样式触发器，在值匹配声明的状态值时应用一个类。

#### States：

- 每个条目（*state*）由一个 `<name>`（类型：`string`）和一个 `<value>`（类型：`integer`）组成。
  - `<value>` 决定了应用状态的百分比阈值，超过该值时状态生效，但 battery 和 pulseaudio 模块除外，这两个模块在*低于*给定值时激活。
  - 状态可以在 `style.css` 中作为 CSS 类引用。CSS 类的名称就是状态的 `<name>`。
  - 每个状态还可以有自己的 `format`。
    可以通过 `format-<name>` 进行配置。
    或者如果你想要更细致的区分，还可以使用 `format-<status>-<state>`。更多信息请参见[自定义格式](https://github.com/Alexays/Waybar/wiki/Module:-Battery#module-battery-config-format-custom)。

#### 示例：
```
"battery": {
    "bat": "BAT2",
    "interval": 60,
    "states": {
        "warning": 30,
        "critical": 15
    },
    "format": "{capacity}% {icon}",
    "format-icons": ["", "", "", "", ""],
    "max-length": 25
}
```

### 状态样式

- `#battery.<state>`
  - `<state>` 可以在 `config` 中定义。更多信息请参见 [`states`](https://github.com/Alexays/Waybar/wiki/Module:-Battery#module-battery-config-states)

#### 示例：

- `#battery.warning: { background: orange; }`
- `#battery.critical: { background: red; }`
