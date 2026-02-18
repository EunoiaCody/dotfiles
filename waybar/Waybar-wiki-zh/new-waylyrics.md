## waylyrics

新版 [waylyrics](https://github.com/switchToLinux/waylyrics)，使用 sdbus-cpp。

支持：
- 所有 mpris 播放器
- 自定义 class/id 标签；
- 更快速且更少的 dbus 开销！


一个更高效的 [waylyrics](https://github.com/switchToLinux/waylyrics) 动态库。

优点：
- 参考了 waylyrics ，并且重新实现了大部分功能。
- 减少了对 dbus 通信请求，使用了 signal 订阅模式。
- 更新歌词更加快速（1秒）。
