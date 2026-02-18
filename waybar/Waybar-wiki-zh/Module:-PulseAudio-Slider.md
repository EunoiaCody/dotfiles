`pulseaudio/slider` 模块以滑动条的形式显示和控制默认音频输出或输入的当前音量。

可以通过在滑动条上拖动或点击特定位置来控制音量。

## 配置

| option | typeof | default | description |
| --- | --- | --- | --- |
| `min` | int | 0 | 滑动条应显示和设置的最小音量值。 |
| `max` | int | 100 | 滑动条应显示和设置的最大音量值。 |
| `orientation` | string | `horizontal` | 滑动条的方向。可以是 `horizontal` 或 `vertical`。 |

> [!NOTE]
> 除了 JSON 配置外，滑动条模块的特殊之处在于它们**需要**样式设置才能正常工作。详情请阅读[此处](https://github.com/Alexays/Waybar/wiki/FAQ#slider-looks-small)。简而言之，你**需要**设置 `min-width` 和/或 `min-height`（取决于你的滑动条是否为垂直方向）才能正确显示。这是 GTK 的细节问题，而非 Waybar 的问题。

## 示例

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

## 样式

滑动条是一个包含多个 CSS 节点的组件，其中以下节点被公开：

- **#pulseaudio-slider**：
    控制滑动条和进度条*周围*的框样式。

- **#pulseaudio-slider slider**：
    控制滑动条手柄的样式。

- **#pulseaudio-slider trough**：
    控制进度条中未填充部分的样式。

- **#pulseaudio-slider highlight**：
    控制进度条中已填充部分的样式。

### 样式示例

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