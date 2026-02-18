The `network` module displays information about the current network connections.

### Config

Addressed by `network`

| option                | typeof  | default    | description |
| --------------------- | ------- | ---------- | ----------- |
| `interface`           | string  |            | Use the defined interface instead of auto detection.<br>Accept wildcard. |
| `interval`			| integer | 60		   | The interval in which the network information gets polled (e.g. signal strength). |
| `family`              | string  | `ipv4`     | The address family that is used for the format replacement {ipaddr} and to determine if a network connection is present. Set it to ipv4_6 to display both. |
| `format`              | string  | `{ifname}` | The format, how information should be displayed.<br>This format is used when other formats aren't specified. |
| `format-ethernet`     | string  |            | This format is used when a ethernet interface is displayed. |
| `format-wifi`         | string  |            | This format is used when a wireless interface is displayed. |
| `format-linked`       | string  |            | This format is used when a linked interface with no ip address is displayed. |
| `format-disconnected` | string  |            | This format is used when the displayed interface is disconnected. |
| `format-disabled`     | string  |            | This format is used when the displayed interface is disabled. |
| `format-alt` | string  |            | On click, toggle to alternative format |
| `format-icons`        | array/object |       | Based on the current capacity, the corresponding icon gets selected.<br>The order is *low* to *high*.<br>Or by the state if it is an object. |
| `rotate`		   | integer | 				| Positive value to rotate the text label. |
| `max-length`          | integer |            | The maximum length in character the module should display. |
| `on-click`            | string  |            | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-scroll-up`        | string  |            | Command to execute when scrolling up on the module. |
| `on-scroll-down`      | string  |            | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool  | `true`              | Option to enable tooltip on hover. |
| `tooltip-format`      | string  |            | The format, how information should be displayed in the tooltip.<br>This format is used when other formats aren't specified. |
| `tooltip-format-ethernet`     | string  |            | This format is used when a ethernet interface is displayed. |
| `tooltip-format-wifi`         | string  |            | This format is used when a wireless interface is displayed. |
| `tooltip-format-disconnected` | string  |            | This format is used when the displayed interface is disconnected. |
| `tooltip-format-disabled`     | string  |            | This format is used when the displayed interface is disabled. |


#### Format replacements:

| string                | replacement |
| ----------------------| ----------- |
| `{ifname}`            | Name of the network interface. |
| `{ipaddr}`            | The first IP of the interface. |
| `{gwaddr}`            | The default gateway for the interface. |
| `{netmask}`           | The subnetmask corresponding to the IP(V4). |
| `{netmask6}`          | The subnetmask corresponding to the IP(V6). |
| `{cidr}`              | The subnetmask corresponding to the IP(V4) in CIDR notation. |
| `{cidr6}`              | The subnetmask corresponding to the IP(V6) in CIDR notation. |
| `{essid}`             | Name (SSID) of the wireless network. |
| `{signalStrength}`    | Signal strength of the wireless network. |
| `{signaldBm}`         | Signal strength of the wireless network in dBm. |
| `{frequency}`         | Frequency of the wireless network in GHz. |
| `{bandwidthUpBits}`     | Instant up speed in bits/seconds. |
| `{bandwidthDownBits}`   | Instant down speed in bits/seconds. |
| `{bandwidthTotalBits}`  | Instant total speed in bits/seconds. |
| `{bandwidthUpOctets}`   | Instant up speed in octets/seconds. |
| `{bandwidthDownOctets}` | Instant down speed in octets/seconds. |
| `{bandwidthTotalOctets}` | Instant total speed in octets/seconds. |
| `{bandwidthUpBytes}`  | Instant up speed in bytes/seconds.  |
| `{bandwidthDownBytes}`| Instant down speed in bytes/seconds.|
| `{bandwidthTotalBytes}`| Instant total speed in bytes/seconds.|
| `{icon}`              | Icon, as defined in `format-icons`. |

#### Example:
```jsonc
"network": {
    "interface": "wlp2s0",
    "format": "{ifname}",
    "format-wifi": "{essid} ({signalStrength}%) ",
    "format-ethernet": "{ipaddr}/{cidr} 󰊗",
    "format-disconnected": "", //An empty format will hide the module.
    "tooltip-format": "{ifname} via {gwaddr} 󰊗",
    "tooltip-format-wifi": "{essid} ({signalStrength}%) ",
    "tooltip-format-ethernet": "{ifname} ",
    "tooltip-format-disconnected": "Disconnected",
    "max-length": 50
}
```

### Style

- `#network`
- `#network.disabled`
- `#network.disconnected`
- `#network.linked`
- `#network.ethernet`
- `#network.wifi`
