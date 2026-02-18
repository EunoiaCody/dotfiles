- [标签](#tags)
- [窗口](#window)

重要提示：使用这些模块需要为 dwl 打上 [IPC](https://codeberg.org/dwl/dwl-patches/wiki/ipc) 补丁。

***

## 标签

`tags` 模块显示 [dwl](https://codeberg.org/dwl/dwl) 的当前标签状态。

### 配置

通过 `dwl/tags` 寻址

| option           | typeof   | default | description |
| ---------------- | -------  | ------- | ----------- |
| `num-tags`       | integer  | `9`     | dwl 中配置的标签数量。（必须匹配！）
| `tag-labels`     | array    |         | 每个标签显示的标签名。
| `disable-click`  | bool     | `false` | 如果设置为 false，可以左键点击设置焦点标签。右键点击切换标签焦点。如果设置为 true，此行为将被禁用。

### 样式

- `#tags button`
- `#tags button.occupied`
- `#tags button.focused`
- `#tags button.urgent`

注意 occupied/focused/urgent 状态可能重叠。也就是说，一个标签可能同时处于 occupied 和 focused 状态。

## 窗口

通过 *dwl/window* 寻址

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `format`         | string  | `{title}`    | 信息的显示格式。 |
| `rotate`         | integer | 	       | 正值用于旋转文本标签。 |
| `max-length`     | integer |         | 模块应显示的最大字符长度。 |
| `on-click`       | string  |         | 点击模块时执行的命令。 |
| `on-click-right` | string  |         | 右键点击模块时执行的命令。 |
| `on-scroll-up`   | string  |         | 在模块上向上滚动时执行的命令。 |
| `on-scroll-down` | string  |         | 在模块上向下滚动时执行的命令。 |
| `smooth-scrolling-threshold` | double  |              | 滚动时使用的阈值。 |
| `tooltip`        | bool    | `true`  | 禁用悬停提示的选项。 |
| `rewrite`        | object  | `{}`    | 重写模块格式输出的规则。参见**重写规则**。 |
| `icon`           | bool    | `false`  | 禁用应用程序图标的选项。 |
| `icon-size`           | integer    | `24`  | 设置应用程序图标的大小。 |

#### 格式替换：

| string     | replacement                       |
| ---------- | --------------------------------- |
| `{title}`  | 焦点窗口的标题。  |
| `{app_id}` | 焦点窗口的 app_id。 |
| `{layout}`  | 焦点窗口的布局。 ||

`title`：焦点窗口的标题。

`app_id`：焦点窗口的 app_id。

`layout`：焦点窗口的布局。

#### 重写规则：

`rewrite` 是一个对象，其中键是正则表达式，值是表达式匹配时的重写规则。规则可以包含对表达式捕获组的引用。

正则表达式和替换遵循 [ECMAScript 规则](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Cheatsheet)（[正式定义](https://tc39.es/ecma262/#sec-regexp-regular-expression-objects)）。

表达式必须完全匹配才能触发替换；如果没有表达式匹配，格式输出保持不变。

无效的表达式（例如，括号不匹配）将被忽略。

#### 示例 1：
```jsonc
"dwl/window": {
    "format": "{title}",
    "max-length": 50,
    "rewrite": {
       "(.*) - Mozilla Firefox": "🌎 $1",
       "(.*) - vim": " $1",
       "(.*) - zsh": " [$1]"
    }
}
```
