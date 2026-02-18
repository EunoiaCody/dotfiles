# 编写模块

Waybar 模块通常是从 `waybar::ALabel` 类派生的类，而 `waybar::ALabel`
本身派生自 `waybar::AModule`。模块也可以直接从 `waybar::AModule` 派生。

模块源文件应放在 `src/modules/` 目录中，头文件应放在
`include/modules/` 目录中。源文件应按照相应的功能标志添加到
`meson.build` 中的 `src_files`，功能标志应在
`meson_options.txt` 中列出。模块的实例化应添加在
`src/factory.cpp` 中，而模块的头文件应包含在
`include/factory.hpp` 中。

一个基本模块会使用 `set_markup()` 方法将文本写入其 `label_` 成员
（继承自 `ALabel`）。通常你需要某种方式来更改标签中的文本以响应外部事件，
这可以通过为你的类定义 `ALabel` 的虚方法 `auto update() -> void` 来实现。
每当调用 `dp` 成员（继承自 `AModule`）的 `emit()` 方法时，该函数就会被调用。
`update()` 方法还应调用其父类的 `update()` 方法：`ALabel::update();`。

响应外部事件的最简单方式是创建一个轮询模块。可以通过在初始化 `ALabel` 时为
`interval` 参数设置某个值，并在你的类中添加一个 `util::Sleeper_Thread`
变量来实现，这需要包含 `util/sleeper_thread.hpp` 头文件。然后应按照
`src/modules/clock.cpp` 中类似的方式配置睡眠线程。
