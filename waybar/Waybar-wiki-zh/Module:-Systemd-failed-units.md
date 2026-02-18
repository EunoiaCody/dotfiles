`systemd-failed-units` 模块监控并显示失败的 systemd 单元数量。

### 配置

通过 `systemd-failed-units` 进行配置

| option            | typeof  | default             | description |
| ----------------- | ------- | ------------------- | ----------- |
| `format` | string | `{nr_failed} failed` | 信息的显示格式。当未指定其他格式时使用此格式。 |
| `format-ok` | string | | 没有失败单元时使用此格式。 |
| `user` | bool | `true` | 计算用户 systemd 单元的选项。 |
| `system` | bool | `true` | 计算系统级（PID=1）systemd 单元的选项。 |
| `hide-on-ok` | bool | `true` | 没有失败单元时隐藏此模块的选项。 |

#### 格式替换

| string                | replacement |
| ----------------------| ----------- |
| `{nr_failed_system}` | 系统级（PID=1）systemd 的失败单元数量。 |
| `{nr_failed_user}` | 用户 systemd 的失败单元数量。 |
| `{nr_failed}` | 总失败单元数量。 |


#### 示例：

```jsonc
"systemd-failed-units": {
	"hide-on-ok": false, // Do not hide if there is zero failed units.
	"format": "✗ {nr_failed}",
	"format-ok": "✓",
	"system": true, // Monitor failed systemwide units.
	"user": false // Ignore failed user units.
}
```

### 样式

- `#systemd-failed-units`
- `#systemd-failed-units.ok`
- `#systemd-failed-units.degraded`