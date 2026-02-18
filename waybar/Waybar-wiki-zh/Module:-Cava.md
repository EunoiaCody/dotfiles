用于 [karlstav/cava](https://github.com/karlstav/cava) 的 `cava` 模块

从 0.15.0 版本开始，Waybar cava 模块支持两种不同的前端。使用哪种前端由 cava 配置文件 [output] 部分中的 `method` 参数管理。

### 配置

通过 `cava` 进行配置。重复并引用了原始 [cava 配置](https://github.com/karlstav/cava#configuration)。如有不清楚的选项，请查阅原始 cava 文档
| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `cava_config`            | string  |               | cava 配置文件的存放路径 |
| `method` [output]            | string  |               | 管理 Waybar cava 模块应使用哪种前端。值：raw、sdl_glsl |
| `framerate`            | integer  |    30           | 每秒帧数。用于替代 `interval` |
| `autosens`            | integer  |    1           | 当条形图达到峰值时将尝试降低灵敏度 |
| `sensitivity`            | integer  |    100           | 手动灵敏度百分比。如果启用了 autosens，这只是初始值。200 表示双倍高度。仅接受非负值 |
| `bars`            | integer  |    12           | 条形图的数量 |
| `lower_cutoff_freq`            | long integer  |    50           | 可视化器带宽中最低条形图的低截止频率 |
| `higher_cutoff_freq`            | long integer  |    10000           | 可视化器带宽中最高条形图的高截止频率 |
| `sleep_timer`            | integer  |    5           | 无输入多少秒后 cava 主线程进入休眠模式 |
| `hide_on_silence`  | bool  | false  | 当没有输入时隐藏组件（在 `sleep_timer` 时间过后）  |
| `format_silent`  | string |  | sleep_timer 时间过后组件的文本内容（`hide_on_silence` 必须为 false）  |
| `method` [input]          | string  |    pulse           | 音频捕获方法。可用方法有：pipewire、pulse、alsa、fifo、sndio 或 shmem |
| `source`            | string  |    auto           | 参见 cava 配置 |
| `sample_rate`            | long integer  |    44100           | 参见 cava 配置 |
| `sample_bits`            | integer  |    16           | 参见 cava 配置 |
| `stereo`            | bool  |    true           | 可视通道 |
| `reverse`            | bool  |    false           | 反向显示频率 |
| `bar_delimiter`            | integer  |    0           | 每个条形图之间用分隔符隔开。使用 ASCII 表中的十进制值（例如 59 = ";"）。0 表示无分隔符 |
| `monstercat`            | bool  |    false           | 启用或禁用所谓的"Monstercat 平滑"（带或不带"波浪"效果） |
| `waves`            | bool  |    false           | 启用或禁用所谓的"Monstercat 平滑"（带或不带"波浪"效果） |
| `noise_reduction`            | integer |    77           | 原始可视化效果噪音很大，此因子用于调整积分和重力滤波器以保持信号平滑。100 表示非常缓慢且平滑，0 表示快速但噪音大 |
| `input_delay`            | integer |    2           | 设置获取音频源线程开始工作前的延迟时间。在作者的机器上，Waybar 的启动速度比 pipewire 音频服务器快得多，没有小延迟的话 cava 模块会因为 pipewire 尚未就绪而失败 |
| `ascii_max_range`            | integer |    7           | 无法直接设置。该值由 `format-icons` 数组中的图标数量决定 |
| `data_format`            | string  |    asci           | 原始数据格式。可以是 'binary' 或 'ascii' |
| `raw_target`            | string  |    /dev/stdout           | 原始输出目标。如果目标不存在将创建一个 fifo |
| `menu`            |  string  |        |  弹出菜单的操作  |
| `menu-file`       |  string  |        |  菜单描述文件的位置。需要有一个类型为 GtkMenu 且 id 为 `menu` 的元素  |
| `menu-actions`    |  array   |        |  与菜单按钮对应的操作  |
| `bar_spacing`    |  integer   |        |  条形图之间的间距（字符数）  |
| `bar_width`    |  integer   |        |  条形图的宽度（字符数） |
| `bar_height`    |  integer   |        |  无用。bar_height 仅用于"noritake"格式的输出 |
| `background` | string | | GLSL 相关。仅支持十六进制颜色代码。必须用 '' 包裹 |
| `foreground` | string | | GLSL 相关。仅支持十六进制颜色代码。必须用 '' 包裹 |
| `gradient` | integer | 0 | GLSL 相关。渐变模式（0/1 - 开/关） |
| `gradient_count` | integer | 0 | GLSL 相关。渐变颜色的数量 |
| `gradient_color_N` | string | | GLSL 相关。N - 1 到 8 之间的渐变颜色编号。仅支持十六进制定义的颜色。必须用 '' 包裹 |
| `sdl_width` | integer | | GLSL 相关。管理 waybar cava GLSL 前端模块的宽度 |
| `sdl_height` | integer | | GLSL 相关。管理 waybar cava GLSL 前端模块的高度 |
| `continuous_rendering` | integer | 0 | GLSL 相关。即使没有音频也继续渲染。建议设置为 1 |



***
配置可以通过以下方式提供：
1. 仅通过 `cava_config` 提供 cava 配置文件。其余配置可以省略
2. 不使用 cava 配置文件。在这种情况下，cava 应通过提供的配置选项列表进行配置
3. 混合方式。同时提供 cava 配置文件和配置选项。在这种情况下，waybar 会先应用配置文件，然后用提供的配置选项列表覆盖特定选项

### 操作
| string           | action  |
| ---------------- | ------- |
| `mode`           | 将 cava 主线程和获取音频源线程在暂停/恢复之间切换 |

### 额外依赖

```
iniparser
fftw3
epoxy(for GLSL frontend)
```

### 问题排查
* 启动时 Waybar 抛出异常 "error while loading shared libraries: libcava.so: cannot open shared object file: No such file or directory"。
  - 可能是 libcava 由于某种原因未在系统中注册。`sudo ldconfig` 应该可以解决
  - 带有 cava 依赖的 Waybar 安装在 /usr/local 目录下。要解决此问题：
    1. 删除本地 cava 库。`sudo rm -rfv /usr/local/include/cava`、`sudo rm -rfv /usr/local/lib64/pkgconfig/cava.pc`、`sudo rm -rfv /usr/local/lib64/libcava.so`
    1. 设置 waybar 应安装的前缀。`meson configure build -Dprefix="/usr"`
    1. 构建 waybar。`make`
    1. 将 waybar 安装到系统中。`sudo meson install -C build`
* waybar 正在运行但 cava 模块对音乐没有反应。
  - 在这种情况下，首先需要确保普通 cava 应用程序正常工作
  - 如果正常，需要注释掉所有配置选项。取消注释 `cava_config` 并提供可用的 cava 配置文件路径
  - 你可能设置了过大或过小的 `input_delay`。尝试设置为 4 秒，重启 waybar 并在 4 秒后再次检查。通常即使在性能较弱的机器上也应该足够
  - 你可能不小心将 `mode` 操作切换到了暂停模式

### 提交问题
需要明确的是：此模块是 cava API 的使用者。因此，任何与 cava 引擎相关的 bug 应联系 [Cava 上游](https://github.com/karlstav/cava)，但有一个例外。Cava 上游不提供 cava 作为共享库。为此，本模块作者创建了一个分支 [libcava](https://github.com/LukashonakV/cava)。所以顺序是：1）cava 上游 2）libcava 上游。
如果 cava 发布了新版本且你希望获取它，应该向 [libcava](https://github.com/LukashonakV/cava) 提交一个标题为 [Bump]x.x.x 的 issue，其中 x.x.x 是 cava 的发布版本。

### 示例：
```jsonc
"cava": {
        // "cava_config": "$XDG_CONFIG_HOME/cava/cava.conf",
        "framerate": 30,
        "autosens": 1,
        "sensitivity": 100,
        "bars": 14,
        "lower_cutoff_freq": 50,
        "higher_cutoff_freq": 10000,
        "hide_on_silence": false,
        // "format_silent": "quiet",
        "method": "pulse",
        "source": "auto",
        "stereo": true,
        "reverse": false,
        "bar_delimiter": 0,
        "monstercat": false,
        "waves": false,
        "noise_reduction": 0.77,
        "input_delay": 2,
        "format-icons": ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" ],
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
https://user-images.githubusercontent.com/23121044/232342152-640171fc-8977-462d-ac0d-0f8fd7c69774.mp4

### 样式

- `#cava`
- `#cava.silent` 在没有检测到声音超过 sleep_timer 秒后应用
- `#cava.updated` 在显示新帧时应用
