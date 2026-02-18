The `temperature` module displays the current temperature from a thermal zone.

### Config

Addressed by `temperature`

| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `thermal-zone`   | integer  |               | The thermal zone, as in `/sys/class/thermal/`. |
| `hwmon-path`     | string/array  |          | The temperature path to use, e.g. `/sys/class/hwmon/hwmon2/temp1_input` instead of one in `/sys/class/thermal/`. |
| `hwmon-path-abs` | string/array  |          | The path of the hwmon-directory of the device, e.g. `/sys/devices/pci0000:00/0000:00:18.3/hwmon`. (Note that the subdirectory `hwmon/hwmon#`, where `#` is a number, is not part of the path!) Has to be used together with `input-filename`. |
| `input-filename` | string  |               | The temperature filename of your `hwmon-path-abs`, e.g. `temp1_input` |
| `warning-threshold` | integer |			 | The threshold before it is considered warning (Celsius). |
| `critical-threshold` | integer |			 | The threshold before it is considered critical (Celsius). |
| `interval`       | integer | 10            | The interval in which the information gets polled. |
| `format-critical` | string  |      | The format to use when temperature is considered critical |
| `format`         | string  | `{temperatureC}°C` | The format (Celsius/Farenheit) in which the temperature should be displayed. |
| `format-icons`   | array   |               | Based on the current temperature (Celsius) and `critical-threshold` if available, the corresponding icon gets selected.<br>The order is *low* to *high*. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `max-length`     | integer |               | The maximum length in characters the module should display. |
| `on-click`       | string  |               | Command to execute when you clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`   | string  |               | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |               | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |
| `tooltip-format` | string | `{temperatureC}°C` | The format for the tooltip
#### Format replacements:

| string       | replacement |
| ------------ | ----------- |
| `{temperatureC}` | Temperature in Celsius. |
| `{temperatureF}`     | Temperature in Fahrenheit. |
| `{temperatureK}` | Temperature in Kelvin. |
| `{icon}` | Icon, as defined in `format-icons`. |

#### Example:
```jsonc
 "temperature": {
    // "thermal-zone": 2,
    // "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
    // "critical-threshold": 80,
    // "format-critical": "{temperatureC}°C ",
    "format": "{temperatureC}°C "
}
```

### Style

- `#temperature`
- `#temperature.warning`
- `#temperature.critical`

### Debugging

#### Finding your thermal zone

 To list all the zone types, run 

```bash
 for i in /sys/class/thermal/thermal_zone*; do echo "$i: $(<$i/type)"; done
```

#### Finding hwmon path
If you don't have a thermal zone, another option is to use `sensors` to find preferred temperature source, then run

```bash
for i in /sys/class/hwmon/hwmon*/temp*_input; do echo "$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null || echo $(basename ${i%_*})) $(readlink -f $i)"; done
```

to find path to desired file. Then include it in `hwmon-path` variable.

