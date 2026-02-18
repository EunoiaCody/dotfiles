The `image` module displays an image from a path.

### Config

Addressed by `image`

| option           | typeof  | default | description |
| ---------------- | ------- | ------- | ----------- |
| `path` | string | | The absolute path to the image |
| `exec` | string | | The path to the script, which should return image path file. It will only execute if the path is not set | 
| `size` | integer | | The width/height to render the image |
| `interval`       | integer |         | The interval (in seconds) in which the information gets polled |
| `signal`         | integer |         | The signal number used to update the module. The number is valid between 1 and  N,  where  `SIGRTMIN+N` = `SIGRTMAX`. |
| `on-click`       | string  |         | Command to execute when clicked on the module. |
| `on-click-middle` | string  |              | Command to execute when you middle clicked on the module using mousewheel. |
| `on-click-right` | string  |               | Command to execute when you right clicked on the module. |
| `on-update` | string  |              | Command to execute when the module is updated. |
| `on-scroll-up`   | string  |         | Command to execute when scrolling up on the module. |
| `on-scroll-down` | string  |         | Command to execute when scrolling down on the module. |
| `smooth-scrolling-threshold` | double  |              | Threshold to be used when scrolling. |
| `tooltip` | bool | `true` | Option to enable tooltip on hover. |

#### Script Output

Similar to the **custom** module, output values of the script is **newline** separated.
The following is the output format:

```
$path\n$tooltip
```

#### Examples:

```
"image#album-art": {
	"path": "/tmp/mpd_art",
	"size": 32,
	"interval": 5,
	"on-click": "mpc toggle"
}
```
#### Example with exec
```
"image/album-art": {
     "exec":"~/.config/waybar/custom/spotify/album_art.sh",
     "size": 32,
     "interval": 30,  
}
```
#### Script album_art.sh
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

### Style

- `#image`
- `#image.empty`

