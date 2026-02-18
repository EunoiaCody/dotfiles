- [Mode](#mode)
- [Tags](#tags)
- [Window](#window)
- [Layout](#layout)

***

## Mode

`mode` 模块显示 [river](https://github.com/ifreund/river) 的当前映射模式。

### 配置

通过 `river/mode` 进行配置

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | 信息的显示格式。`{}` 处会插入数据。 |
| `rotate`         | integer | 	       | 正值用于旋转文本标签。 |
| `max-length`     | integer |         | 模块应显示的最大字符长度。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-right` | string  |         | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |

#### 示例：
```json
"river/mode": {
    "format": "mode: {}"
}
```

### 样式

- `#mode`
- `#mode.<mode>`

***

## Tags

`tags` 模块显示 [river](https://github.com/ifreund/river) 的当前标签状态。

### 配置

通过 `river/tags` 进行配置

| option           | typeof   | default | description |
| ---------------- | -------  | ------- | ----------- |
| `num-tags`       | integer  | `9`     | 应显示的标签数量。最大为 32。
| `tag-labels`     | array    |         | 每个标签显示的标签名称。
| `disable-click`  | bool     | `false` | 如果设置为 false，你可以左键点击设置聚焦标签，右键点击切换标签聚焦。如果设置为 true，此行为将被禁用。
| `set-tags`       | array    |         | 左键点击对应标签时设置的标签。
| `toggle-tags`    | array    |         | 右键点击对应标签时切换的标签。
| `hide-vacant`    | bool     | `false` | 如果设置为 true，未启用的空标签将被隐藏

#### 示例：
此配置启用 5 个标签，并通过设置第 32 位为 true 来支持置顶标签（标签 32），使其始终被选中。
```json
"river/tags": {
    "num-tags": 5,
    "set-tags": [
      2147483649,
      2147483650,
      2147483652,
      2147483656,
      2147483664
    ]
}
```

### 样式

- `#tags button`
- `#tags button.occupied`
- `#tags button.focused`
- `#tags button.urgent`

请注意，occupied/focused/urgent 状态可以重叠。也就是说，一个标签可以同时处于 occupied 和 focused 状态。

***

## Window

`window` 模块显示 [river](https://github.com/ifreund/river) 中当前聚焦窗口的标题。

### 配置

通过 `river/window` 进行配置

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{}`    | 信息的显示格式。`{}` 处会插入数据。 |
| `rotate`         | integer | 	       | 正值用于旋转文本标签。 |
| `max-length`     | integer |         | 模块应显示的最大字符长度。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-right` | string  |         | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip`        | bool    | `true`  | 禁用悬停时显示工具提示的选项。 |

#### 示例：
```json
"river/window": {
    "format": "{}"
}
```

### 样式

- `#window`
- `#window.focused`

当与栏所在的相同输出被聚焦时，将应用 `.focused` 类。这可以用于创建输出聚焦指示器。

***

## Layout

`layout` 模块显示由布局生成器定义的当前 [river](https://github.com/ifreund/river) 布局。

### 配置

通过 `river/layout` 进行配置

| option            | typeof  | default | description |
| ----------------- | ------- | ------- | ----------- |
| `format`          | string  | `{}`    | 信息的显示格式。{} 处会插入数据。 |
| `rotate`          | integer | 	    | 正值用于旋转文本标签。 |
| `max-length`      | integer |         | 模块应显示的最大字符长度。 |
| `min-length`      | integer |         | 模块应接受的最小字符长度。 |
| `align`           | integer |         | 文本的对齐方式，其中 0 为左对齐，1 为右对齐。如果模块被旋转，将跟随文本流向。 |
| `on-click`        | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |         | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right`  | string  |         | 右键点击模块时执行的命令。 |

#### 示例：

```json
"river/layout": {
    "format": "{}",
    "min-length": 4,
    "align": "right"
}
```

### 样式

- `#layout`
- `#layout.focused` 当此模块栏所属的输出被聚焦时应用。
- `#layout.<layout>` 特定命名布局的样式