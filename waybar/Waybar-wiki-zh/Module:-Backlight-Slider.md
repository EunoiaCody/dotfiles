`backlight/slider` 模块用于显示和控制默认或首选设备的当前亮度。

可以通过在滑块上拖动或点击特定位置来控制亮度。

## 配置

| option | typeof | default | description |
| --- | --- | --- | --- |
| `min` | int | 0 | 滑块应显示和设置的最小值。 |
| `max` | int | 100 | 滑块应显示和设置的最大值。 |
| `orientation` | string | `horizontal` | 滑块的方向。可以是 `horizontal` 或 `vertical`。 |
| `device` | string | | 要控制的首选设备名称。如果留空，将自动选择一个设备。 |

> [!NOTE]
> 除了 JSON 配置之外，滑块模块比较特殊，它们**需要**样式才能正常工作。更多信息请阅读[这里](https://github.com/Alexays/Waybar/wiki/FAQ#slider-looks-small)。简而言之，你**需要**设置 `min-width` 和/或 `min-height`（取决于滑块是否为垂直方向）才能正确显示。这是 GTK 的细节问题，并非 Waybar 的问题。

> [!WARNING]
> 如果 `min` 设置为 `0`（默认值），滑块可以将亮度设置为 `0`，这可能会完全关闭某些设备的背光。
> 这会导致屏幕完全变黑。建议设置一个较小的最小值（例如 `10`），或配置亮度快捷键作为备用方案。

## 示例

```json
"modules-right": [
    "backlight/slider",
],
"backlight/slider": {
    "min": 0,
    "max": 100,
    "orientation": "horizontal",
    "device": "intel_backlight"
}
```

## 样式

滑块是一个包含多个 CSS 节点的组件，其中以下节点是公开的：

- **#backlight-slider**：
    控制滑块和进度条*周围*方框的样式。

- **#backlight-slider slider**：
    控制滑块手柄的样式。

- **#backlight-slider trough**：
    控制进度条中未填充部分的样式。

- **#backlight-slider highlight**：
    控制进度条中已填充部分的样式。

### 样式示例

```css
#backlight-slider slider {
    min-height: 0px;
    min-width: 0px;
    opacity: 0;
    background-image: none;
    border: none;
    box-shadow: none;
    background: none;
}
#backlight-slider trough {
    min-height: 10px;
    min-width: 80px;
    border-radius: 5px;
    background: black;
}
#backlight-slider highlight {
    min-width: 10px;
    border-radius: 5px;
    background: red;
}
```
