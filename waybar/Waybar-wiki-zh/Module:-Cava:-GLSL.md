Cava GLSL 前端通过 OpenGL 将传入音频数据的可视化委托给 GPU。

要成功构建和正常运行 Cava GLSL，需要满足一些必要的依赖：
1. 系统上必须安装 epoxy 库
2. 必须使用原始项目中的顶点着色器和片段着色器。应下载它们，并在 Waybar Cava 配置中正确设置文件路径：
   1. [cava shaders](https://github.com/karlstav/cava/tree/master/output/shaders)
   2. [libcava shaders](https://github.com/LukashonakV/cava/tree/master/output/shaders)
3. 强烈建议为 Waybar Cava GLSL 模块使用单独的 cava 配置，并将其作为 Waybar 配置中的 `cava_config` 使用。
4. 通常 cava 配置放在 `XDG_CONFIG_HOME` 目录中，着色器也是如此。建议将它们放在 `$XDG_CONFIG_HOME/cava/shaders` 文件夹中。

关键配置选项：
1. `bars`。该参数的值越多，可视化效果越有趣。
2. output 部分的 `method` 必须设置为 `sdl_glsl`
3. `sdl_width` 和 `sdl_height` 管理模块的大小。根据需要进行调整。
4.  sdl_glsl 的着色器，位于 $HOME/.config/cava/shaders。示例：
`vertex_shader = pass_through.vert
fragment_shader = spectrogram.frag`
5. 将 `continuous_rendering` 设置为 1 以启用平滑渲染；否则设置为 0。建议保持设置为 1。
6. `background`、`foreground` 和 `gradient_color_N`（其中 N 是 1 到 8 之间的数字）必须使用十六进制颜色代码定义

#### 示例 1
1. waybar 模块配置
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#1.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. 用于 waybar 的 cava 配置 -> 
[waybar_cava#1.conf.tar.gz](https://github.com/user-attachments/files/24260316/waybar_cava.1.conf.tar.gz)

https://github.com/user-attachments/assets/52ddd326-e254-4571-b1e9-72b19e57f0c7

#### 示例 2
1. waybar 模块配置
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#2.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. 用于 waybar 的 cava 配置 -> 
[waybar_cava#2.conf.tar.gz](https://github.com/user-attachments/files/24260344/waybar_cava.2.conf.tar.gz)

https://github.com/user-attachments/assets/ee7a7b7e-2e02-4190-92d8-b9fd72414950

#### 示例 3
1. waybar 模块配置
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#3.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. 用于 waybar 的 cava 配置 -> 
[waybar_cava#3.conf.tar.gz](https://github.com/user-attachments/files/24260349/waybar_cava.3.conf.tar.gz)

https://github.com/user-attachments/assets/303f5444-e4a0-43ac-83b3-5471b65edf3c

#### 示例 4
1. waybar 模块配置
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#4.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. 用于 waybar 的 cava 配置 -> 
[waybar_cava#4.conf.tar.gz](https://github.com/user-attachments/files/24260354/waybar_cava.4.conf.tar.gz)

https://github.com/user-attachments/assets/9a9d3e3a-ddc6-4f32-b386-736a7e6059b8

#### 示例 5
1. waybar 模块配置
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#5.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. 用于 waybar 的 cava 配置 -> 
[waybar_cava#5.conf.tar.gz](https://github.com/user-attachments/files/24260359/waybar_cava.5.conf.tar.gz)

https://github.com/user-attachments/assets/ef4fcddc-47a6-4651-87c4-96907eb99f5c
