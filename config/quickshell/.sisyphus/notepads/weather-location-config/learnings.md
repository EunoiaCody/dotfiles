
## 2026-07-09: WeatherContent.qml 集成设置按钮、弹窗和视觉提示

### 修改内容
1. **添加 `import QtQuick.Layouts`** — 确保弹窗组件依赖可用。
2. **设置图标按钮** — 在 `infoSection` 的 `Row` 中，刷新按钮右侧插入 24×24 的 `edit_location` 图标按钮，样式与刷新按钮一致（transparent 背景、hover 变 colPrimary、pressed 变 colLayer2Hover）。点击时调用 `locationDialog.open()`。
3. **WeatherLocationDialog 实例** — 在根 `Item` 下、`fetchData` 之后实例化，绑定 `initialCity/Lat/Lon` 和 `hasManualLocation` 到 `WeatherPlugin`。`onSaved` 写入 JSON + 设置手动位置 + 刷新天气；`onCleared` 清空 JSON + 清除手动位置 + 刷新天气。
4. **hasManualLocation 视觉提示** — 将地址名 `Text` 改为 `Row` 包裹，在其后添加 10px 的 `edit_location` 小图标，通过 `opacity: WeatherPlugin.hasManualLocation ? 0.7 : 0` 控制显示。

### 验证结果
grep 确认以下关键字均存在于 `WeatherContent.qml`：
- `QtQuick.Layouts` (line 2)
- `WeatherLocationDialog` / `locationDialog` (lines 117-118)
- `hasManualLocation` (line 123, 239)
- `settingsMouseArea` / `settingsIcon` (lines 302-315)
- `edit_location` (lines 234, 308)
- `locationDialog.open()` (line 320)

### 注意事项
- `WeatherLocationDialog` 使用 `open()` 方法（设置 `shouldBeVisible = true` 并强制焦点），父组件只需检查 `!locationDialog.shouldBeVisible` 避免重复打开。
- 视觉提示图标使用 `opacity` + `visible: opacity > 0` 实现平滑显隐，避免布局跳动。
