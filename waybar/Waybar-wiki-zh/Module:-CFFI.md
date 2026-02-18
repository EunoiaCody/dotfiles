`cffi` 模块将 GTK 组件的完全控制权交给第三方动态库，以便使用不同的编程语言创建更复杂的模块。

### 配置

通过 `cffi/<name>` 进行配置

|     option    | typeof | default |                          description                           |
|---------------|--------|---------|----------------------------------------------------------------|
| `module_path` | string |         | 要加载以控制组件的动态库路径。 |

根据使用的 cffi 动态库，可能需要一些额外的配置。

### 样式

CSS 类和 ID 由 cffi 动态库管理。


#### 示例：

##### C 语言示例：

`~/.config/waybar/config`
```jsonc
"cffi/c_example": {
    "module_path": ".config/waybar/cffi/wb_cffi_example.so"
}
```

#### 开发新的 CFFI 模块

CFFI 模块需要定义一些具有 C 链接的函数和常量。实现方式取决于所使用的编程语言（搜索 FFI / Foreign Function Interface）。

一个用 C 编写的示例可以在 [resources/custom_modules/cffi_example/](https://github.com/Alexays/Waybar/tree/master/resources/custom_modules/cffi_example/) 中找到

需要定义的符号列表可以在 [resources/custom_modules/cffi_example/waybar_cffi_module.h](https://github.com/Alexays/Waybar/tree/master/resources/custom_modules/cffi_example/waybar_cffi_module.h) 中找到


##### 已知的 CFFI 模块

- [waylyrics](https://github.com/PandeCode/waylyrics) - 用于显示 Spotify 当前播放歌曲同步歌词的模块。

- [libwaybar_cffi_lyrics](https://github.com/switchToLinux/libwaybar_cffi_lyrics) , 一个歌词显示插件，支持 musicfox 和支持mpris协议的播放器。


如果你开发了自己的模块，请添加到这里。

##### 已知的 CFFI 语言绑定

- [Rust](https://crates.io/crates/waybar-cffi)

