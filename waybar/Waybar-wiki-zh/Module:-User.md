`user` 模块显示当前用户名、头像和系统运行时间。

### 配置

通过 `user` 进行配置

| option | typeof | default | description |
| --------------------- | ------- | -------------------------- | ---------------------------------------------------- |
| `interval`            | integer | 60                         | 信息轮询的时间间隔。   |
| `format`              | string  | `{user} {work_H}:{work_M}` | 信息的显示格式。 |
| `avatar`              | string  | `$HOME/.face`              | 自定义图片的路径                                 |
| `height`              | integer | 30                         | 头像高度                                        |
| `width`               | integer | 30                         | 头像宽度                                         |
| `icon`                | bool    | false                      | 启用头像图标的选项                         |
| `open-on-click`       | bool    | true                       | 启用路径打开的选项                        |
| `open-path`           | string  | `$HOME`                    | 文件夹路径                                          |
#### 格式替换：

| string | replacement |
| ----------------------| -----------                  |
| `{up_H}`              | 系统启动时间          |
| `{up_M}`              | 系统启动分钟        |
| `{up_d}`              | 系统启动天数           |
| `{up_m}`              | 系统启动月份         |
| `{up_Y}`              | 系统启动年份          |
| `{work_H}`            | 当天系统运行小时数   |
| `{work_M}`            | 系统运行分钟数        |
| `{work_S}`            | 系统运行秒数        |
| `{work_d}`            | 系统运行天数          |
| `{user}`              | 用户名                     |

#### 示例：
```jsonc
"user": {
        "format": "{user} (up {work_d} days ↑)",
        "interval": 60,
        "height": 30,
        "width": 30,
        "icon": true,
}
```
