`custom` 模块显示脚本的输出或静态文本。要显示静态文本，只需指定 `format` 字段。

### 配置

通过 `custom/<name>` 寻址

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `exec`           | string  |                    |         | 应执行的脚本路径。 |
| `exec-if`        | string  |         | 用于判断是否执行 `exec` 中脚本的脚本路径。<br>当 `exec-if` 的退出码为 0 时将执行 `exec`。 |
| `exec-on-event`  | bool    | `true`  | 如果设置了事件命令（例如 `on-click` 或 `on-scroll-up`），则重新执行脚本。不保证 `exec` 会在 `on-*` 事件命令完成后执行。参见 https://github.com/Alexays/Waybar/pull/1784 了解可能的补丁。 |
| `hide-empty-text`| bool    | `false` | （0.10.3 之后的选项）当输出为空时禁用模块，但 format 可能包含额外的静态内容。 |
| `return-type`    | string  |         | 参见 [`return-type`](#module-custom-config-return-type) |
| `interval`       | integer |         | 信息轮询的时间间隔（秒）。<br>如果只想在启动时执行模块，请使用 `once`。可以通过信号手动更新。如果未定义 `interval`，则假定输出脚本自行循环。 |
| `restart-interval`       | integer |         | 重启间隔（秒）。<br>不能与 *interval* 选项一起使用，因此仅适用于持续运行的脚本。<br>脚本退出后，将在 *restart-interval* 后重新执行。 |
| `signal`         | integer |         | 用于更新模块的信号编号。编号在 1 到 N 之间有效，其中 `SIGRTMIN+N` = `SIGRTMAX`。 |
| `format`         | string  | `{}`    | 信息的显示格式。数据将插入到 `{}` 处。 |
| `format-icons`   | array/object/string   |         | 如果类型为数组，则根据设定的百分比选择对应的图标（从*低*到*高*）。<br>如果类型为对象，则根据输出中的 `alt` 字符串选择图标。<br>如果类型为字符串，则原样粘贴。<br>**注意**：数组可以嵌套在对象中。图标将先根据 `alt` 然后根据百分比进行选择。 |
| `rotate`		   | integer | 				| 正值用于旋转文本标签。 |
| `max-length`     | integer |         | 模块应显示的最大字符长度。 |
| `min-length`     | integer |         | 模块应显示的最小字符长度。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool  | `true`              | 启用悬停提示的选项。 |
| `tooltip-format` | string  |             | 提示信息的格式。 |
| `escape` 	| bool  | `false` | 启用脚本输出转义的选项 |

<a name="module-custom-config-return-type"></a>

#### Return-Type：

- 当 `return-type` 设置为 `json` 时，Waybar 期望 `exec` 脚本以 JSON 格式输出数据。
  格式应如下：`{"text": "$text", "alt": "$alt", "tooltip": "$tooltip", "class": "$class", "percentage": $percentage }`。这意味着输出也应在单行上。可以通过将脚本输出管道传递给 `jq --unbuffered --compact-output` 来实现。`class` 参数也接受字符串数组。
- 如果要使用多行提示信息，请在脚本中使用 `\r`
    - 如果使用 PowerShell 编写脚本，请在双引号中使用标准换行符运算符 "\`n"；`\r` 和 `\n` 将不起作用。
- 如果未指定或指定了无效选项，Waybar 期望 i3blocks 风格的输出，其中值以 `newline` 分隔。
  格式应如下：`$text\n$tooltip\n$class`

`class` 是一个 CSS 类，用于在 `style.css` 中应用不同的样式

#### 持续运行的脚本：

`exec` 脚本可以是持续运行的（即包含某种无限循环）。每当标准输出上有新行数据时（遵循所选的 [`return-type`](#module-custom-config-return-type)），显示将会更新。

`interval` 选项不适用于持续运行的脚本（无需多次调用……因为它会持续运行）。但是，如果脚本在一段时间后停止运行，您可能需要设置 `restart-interval` 以重新启动脚本。

请注意，某些技术会对其输出使用缓冲区。如果您的模块即使脚本按预期工作也不显示任何内容，输出可能暂时保存在缓冲区中。请查找您所使用语言的正确刷新输出缓冲区的方法。

例如，在 ruby 中可以这样做：

```ruby
loop do
  puts { text: 'My module text', class: 'class', … }.to_json
  $stdout.flush
  sleep 5
end
```

#### 格式替换：

| string             | replacement |
| ------------------ | ----------- |
| `{}` | 脚本的输出。 |
| `{percentage}` | 可以通过 json return-type 设置的百分比。 |
| `{icon}` | 根据百分比从 'format-icons' 中选择的图标。 |
| `{text}` | 可以通过 json return-type 设置的文本。 |
| `{alt}` | 可以通过 json return-type 设置的 alt。 |

`{}` 占位符是特殊的：它会自动显示脚本的文本输出。
但是，`{}` 不能与格式字符串中的其他占位符（如 `{icon}`）组合使用——同时使用两者将无法按预期工作。

例如，如果您想同时显示 `format-icons` 中的图标和一些文本，应明确使用 `{icon}` 和 `{text}`：
```json
"custom/media": {
    "exec": "/path/to/your/awesome/script",
    "format": "{icon} {text}",
    "format-icons": {
      "spotify": "",
      "default": "🎵"
    }
}
```
在此示例中：
- `{icon}` 根据脚本返回的 "alt" 字段显示图标
- `{text}` 显示脚本 JSON 输出中 "text" 字段的值

### 提示信息格式
`tooltip-format` 可以接收上述任何格式替换。

如果自定义脚本的输出在 `tooltip` 字段中指定了值，则该值为默认值。否则，默认值为 `{}`。

### 样式

- `#custom-<name>`
- `#custom-<name>.<class>`
  - `<class>` 可以由脚本设置。更多信息参见 [`return-type`](#module-custom-config-return-type)

### 输出名称

`exec` 脚本将设置 `WAYBAR_OUTPUT_NAME` 环境变量为栏所在输出的名称。

### 故障排除

#### 自循环模块不显示

如果您的模块是自循环的，且它甚至没有出现在栏中，请检查：

1. 其配置中__没有__包含 `interval` 参数
2. 标准输出没有被缓冲（参见 [#2358](https://github.com/Alexays/Waybar/discussions/2358)）

#### 自定义 json class 未显示

如果您的自定义脚本中有 json class，但 styles.css 未显示它，则必须先显示包含更多变量的 json（参见 [#3234](https://github.com/Alexays/Waybar/issues/3234)）
