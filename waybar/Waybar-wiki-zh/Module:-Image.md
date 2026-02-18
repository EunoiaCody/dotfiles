`image` 模块从路径显示图像。

### 配置

通过 `image` 引用

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `path` | string | | 图像的绝对路径 |
| `exec` | string | | 脚本的路径，该脚本应返回图像路径文件。仅在未设置 path 时执行。 | 
| `size` | integer | | 渲染图像的宽度/高度 |
| `interval`       | integer |         | 信息轮询的间隔时间（秒） |
| `signal`         | integer |         | 用于更新模块的信号编号。该编号在 1 到 N 之间有效，其中 `SIGRTMIN+N` = `SIGRTMAX`。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-middle` | string  |              | 使用鼠标滚轮中键点击模块时执行的命令。 |
| `on-click-right` | string  |               | 右键点击模块时执行的命令。 |
| `on-update` | string  |              | 模块更新时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip` | bool | `true` | 启用悬停提示的选项。 |

#### 脚本输出

与 **custom** 模块类似，脚本的输出值以**换行符**分隔。
以下是输出格式：

```
$path\n$tooltip
```

#### 示例：

```
"image#album-art": {
	"path": "/tmp/mpd_art",
	"size": 32,
	"interval": 5,
	"on-click": "mpc toggle"
}
```
#### 使用 exec 的示例
```
"image/album-art": {
     "exec":"~/.config/waybar/custom/spotify/album_art.sh",
     "size": 32,
     "interval": 30,  
}
```
#### 脚本 album_art.sh
```
#!/bin/bash
album_art=$(playerctl -p spotify metadata mpris:artUrl)
if [[ -z $album_art ]] 
then
   # spotify is dead, we should die too.
   exit
fi
curl -s  "${album_art}" --output "/tmp/cover.jpeg"
echo "/tmp/cover.jpeg"
```

### 样式

- `#image`
- `#image.empty`
