The `systemd-failed-units` module monitors and displays the number of failed systemd units.

### Config

Addressed by `systemd-failed-units`

| option            | typeof  | default             | description |
| ----------------- | ------- | ------------------- | ----------- |
| `format` | string | `{nr_failed} failed` | The format, how information should be displayed. This format is used when other formats aren't specified. |
| `format-ok` | string | | This format is used when there is no failing units. |
| `user` | bool | `true` | Option to count user systemd units. |
| `system` | bool | `true` | Option to count systemwide (PID=1) systemd units. |
| `hide-on-ok` | bool | `true` | Option to hide this module when there is no failing units. |

#### Format replacements

| string                | replacement |
| ----------------------| ----------- |
| `{nr_failed_system}` | Number of failed units from systemwide (PID=1) systemd. |
| `{nr_failed_user}` | Number of failed units from user systemd. |
| `{nr_failed}` | Number of total failed units. |


#### Examples:

```jsonc
"systemd-failed-units": {
	"hide-on-ok": false, // Do not hide if there is zero failed units.
	"format": "✗ {nr_failed}",
	"format-ok": "✓",
	"system": true, // Monitor failed systemwide units.
	"user": false // Ignore failed user units.
}
```

### Style

- `#systemd-failed-units`
- `#systemd-failed-units.ok`
- `#systemd-failed-units.degraded`