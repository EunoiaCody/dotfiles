- [如何添加一个模块的多个实例？](#how-do-i-add-multiple-instances-of-a-module)
- [工作区按钮有奇怪的悬停效果](#the-workspace-buttons-have-a-strange-hover-effect)
- [如何生成调试构建？](#how-can-i-generate-a-debug-build)
- [默认配置中的图标无法渲染](#the-icons-from-the-default-configuration-arent-rendered)
- [如何显示文本？](#how-do-i-display-text)
- [如何防止模块改变大小？](#how-can-i-prevent-modules-from-changing-size-aka-fixed-width-modules-and-monospace-fonts)
- [如何与 Sway 一起使用？](#how-to-use-with-sway)
- [如何临时隐藏状态栏？](#how-can-I-temporarily-hide-the-bars)
- [如何在不重启 waybar 的情况下重新加载配置？](#how-can-I-reload-the-configuration-without-restarting-waybar)
- [某些 GTK 主题下工作区按钮过宽](#workspace-buttons-are-too-wide-with-some-gtk-themes)
- [我的滑块不显示/看起来很小/无法正常工作](#slider-looks-small)


***

## 如何添加一个模块的多个实例？

请参阅：[Multiple instances of a module](https://github.com/Alexays/Waybar/wiki/Configuration#multiple-instances-of-a-module)

## 工作区按钮有奇怪的悬停效果

这不是一个 bug，原始 issue [#60](https://github.com/Alexays/Waybar/issues/60)。

但如果你不喜欢这个效果，可以通过在 `style.css` 中添加以下代码片段来禁用它：
```css
#workspaces button:hover {
    box-shadow: inherit;
    text-shadow: inherit;
}
```

此外，要移除工作区的所有悬停效果，请在上述基础上添加以下内容：
```css
#workspaces button:hover {
    background: <original-color>;
    border: <original-color>;
    padding: 0 3px;
}
```

## 如何生成调试构建？

调试构建在修复 bug 时很有帮助，因为它会生成带有调试符号的回溯信息。

可以通过以下命令完成：
```sh
make build-debug
```

## 默认配置中的图标无法渲染

你需要安装 `otf-font-awesome`。请参阅此处了解如何安装 [Font Awesome OTF 软件包](https://github.com/Alexays/Waybar/wiki/Installation#how-to-use-with-sway)。

## 如何显示文本？

创建一个 [Custom](./Module:-Custom) 模块，并在 `format` 字段中指定你的文本。

## 如何防止模块改变大小？（即固定宽度模块和等宽字体）

首先确保设置了等宽字体：
```css
* {
    font-family: monospace;
}
```

然后更改模块格式使其保持固定宽度。Waybar 使用 [fmt](https://github.com/fmtlib/fmt) 进行格式化，以下语法是将 CPU 百分比设置为至少 2 个字符宽的示例：
```jsonc
"format": "{usage:2}%"
```

fmt 库有两个问题。首先，它没有提供设置字段_最大_长度的方法，只能设置_最小_长度。因此，当文本超过最小宽度时，宽度会发生变化。这可以通过 `max-length` 参数部分解决。参见 https://github.com/Alexays/Waybar/issues/486。

第二个问题涉及浮点数。Waybar 附带了一个自定义格式化程序，可以为浮点数（网络带宽、磁盘使用量等）强制固定宽度。你需要指定 `>`、`<` 或 `=` 作为格式修饰符。这将按要求对齐数字并使其固定宽度。详情、示例和限制请参见 https://github.com/Alexays/Waybar/pull/472。

最后一个棘手的问题与 pango/cairo 对自定义字形（很可能是 Font Awesome 图标）的字体渲染有关。Cairo 会保留最后一个非空白字符使用的字体来渲染后续的空白字符。这意味着以下两行尽管包含相同数量的字符，但渲染的宽度不同。
```
         10 spaces
  2 leading spaces
```

你可以将所有图标移到模块末尾，这样它们后面就没有空格可以影响；或者在所有图标周围使用 pango 特定的标记，如：`<span font=\"Font Awesome 5 Free\"></span>`。这会强制 cairo 在离开 `<span>` 时返回默认字体，避免使用错误类型的空格。随着 https://gitlab.gnome.org/GNOME/pango/-/issues/249 的进展，你可能会体验到改进。


## 如何与 Sway 一起使用？

你可以通过在 Sway 配置文件中定义来使用 Waybar：
```
bar {
    swaybar_command waybar
}
```

或者在 Sway 配置文件的末尾添加

```
exec waybar
```

## 如何临时隐藏状态栏？
你可以通过以下命令切换状态栏的可见性：
```sh
killall -SIGUSR1 waybar
```

## 如何在不重启 waybar 的情况下重新加载配置？
***仅适用于 v0.9.5 之后版本的 waybar***
```sh
killall -SIGUSR2 waybar
```

## 某些 GTK 主题下工作区按钮过宽

![](https://user-images.githubusercontent.com/27376783/47964799-26019700-e03f-11e8-8b0f-1dd4862b6241.png)

在某些 GTK 主题中，button.text-button.flat 元素的 min-width 属性被设置了一个较大的值。你可以在 waybar 的 `style.css` 中覆盖它

```css
#workspaces button {
  min-width: 20px;
}
```
<a name="slider-looks-small"></a>

## 我的滑块不显示/看起来很小/无法正常工作

与 GTK 中的所有组件一样，滑块的宽度和高度由 CSS 决定。然而，令人意外的是，为滑块组件设置样式更加重要，否则它的宽度和高度将*接近* 0，拖动时也无法正常工作。值得注意的是，只有 `trough` CSS 节点实际上需要设置最小高度或宽度。

如果你遇到滑块问题，请尝试以下方法：

```css
#pulseaudio-slider trough, #backlight-slider trough {
    min-height: 10px;
    min-width: 80px;
}
```
