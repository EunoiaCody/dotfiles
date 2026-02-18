The `cava` module for [karlstav/cava](https://github.com/karlstav/cava)

The Waybar cava module supports two different frontends starting from the 0.15.0 release. The frontend that will be used is managed by the `method` parameter in the [output] section of the cava configuration file.

### Config

Addressed by `cava`. Repeats and refers to the original [cava configuration](https://github.com/karlstav/cava#configuration). For any unclear option please check original cava documentation
| option           | typeof  | default       | description |
| ---------------- | ------- | ------------- | ----------- |
| `cava_config`            | string  |               | Path where cava configuration file is placed to |
| `method` [output]            | string  |               | Manages which frontend Waybar cava module should use. Values: raw, sdl_glsl |
| `framerate`            | integer  |    30           | Frames per second. Is used as a replacement for `interval` |
| `autosens`            | integer  |    1           | Will attempt to decrease sensitivity if the bars peak  |
| `sensitivity`            | integer  |    100           | Manual sensitivity in %. If autosens is enabled, this will only be the initial value. 200 means double height. Accepts only non-negative values |
| `bars`            | integer  |    12           | The number of bars |
| `lower_cutoff_freq`            | long integer  |    50           | Lower cutoff frequencies for lowest bars the bandwidth of the visualizer |
| `higher_cutoff_freq`            | long integer  |    10000           | Higher cutoff frequencies for highest bars the bandwidth of the visualizer |
| `sleep_timer`            | integer  |    5           | Seconds with no input before cava main thread goes to sleep mode |
| `hide_on_silence`  | bool  | false  | Hides the widget if no input is present (after `sleep_timer` elapsed)  |
| `format_silent`  | string |  | Widget's text after sleep_timer elapsed (`hide_on_silence` has to be false)  |
| `method` [input]          | string  |    pulse           | Audio capturing method. Possible methods are: pipewire, pulse, alsa, fifo, sndio or shmem |
| `source`            | string  |    auto           | See cava configuration |
| `sample_rate`            | long integer  |    44100           | See cava configuration |
| `sample_bits`            | integer  |    16           | See cava configuration |
| `stereo`            | bool  |    true           | Visual channels |
| `reverse`            | bool  |    false           | Displays frequencies the other way around |
| `bar_delimiter`            | integer  |    0           | Each bar is separated by a delimiter. Use decimal value in ascii table(i.e. 59 = ";"). 0 means no delimiter |
| `monstercat`            | bool  |    false           | Disables or enables the so-called "Monstercat smoothing" with of without "waves" |
| `waves`            | bool  |    false           | Disables or enables the so-called "Monstercat smoothing" with of without "waves" |
| `noise_reduction`            | integer |    77           | The raw visualization is very noisy, this factor adjusts the integral and gravity filters to keep the signal smooth. 100 will be very slow and smooth, 0 will be fast but noisy |
| `input_delay`            | integer |    2           | Sets the delay before fetching audio source thread start working. On author machine Waybar starts much faster then pipewire audio server, and without a little delay cava module fails due to pipewire is not ready |
| `ascii_max_range`            | integer |    7           | Impossible to set directly. The value is dictated by the number of icons in the array `format-icons`|
| `data_format`            | string  |    asci           | Raw data format. Can be 'binary' or 'ascii' |
| `raw_target`            | string  |    /dev/stdout           | Raw output target. A fifo will be created if target does not exist |
| `menu`            |  string  |        |  Action that popups the menu  |
| `menu-file`       |  string  |        |  Location  of  the  menu descriptor file. There need to be an element of type GtkMenu with id `menu`  |
| `menu-actions`    |  array   |        |  The actions corresponding to the buttons of the menu  |
| `bar_spacing`    |  integer   |        |  Bars' space between bars in number of characters  |
| `bar_width`    |  integer   |        |  Bars' width between bars in number of characters |
| `bar_height`    |  integer   |        |  Useless. bar_height is only used for output in "noritake" format |
| `background` | string | | GLSL actual. Support hex code colors only. Must be within '' |
| `foreground` | string | | GLSL actual. Support hex code colors only. Must be within '' |
| `gradient` | integer | 0 | GLSL actual. Gradient mode(0/1 - on/off) |
| `gradient_count` | integer | 0 | GLSL actual. The count of colors for the gradient |
| `gradient_color_N` | string | | GLSL actual. N - the number of the gradient color between 1 and 8. Only hex defined colors are supported. Must be within '' |
| `sdl_width` | integer | | GLSL actual. Manages the width of the waybar cava GLSL frontend module |
| `sdl_height` | integer | | GLSL actual. Manages the height of the waybar cava GLSL frontend module |
| `continuous_rendering` | integer | 0 | GLSL actual. Keep rendering even if no audio. Recommended to set to 1 |



***
Configuration can be provided as:
1. The only cava configuration file which is provided through `cava_config`. The rest configuration can be skipped
2. Without cava configuration file. In such case cava should be configured through provided list of the configuration option
3. Mix. When provided both And cava configuration file And configuration options. In such case waybar applies configuration file first then overrides particular options by the provided list of configuration options

### Actions
| string           | action  |
| ---------------- | ------- |
| `mode`           | Switch main cava thread and fetching audio source thread from/to pause/resume |

### Additional dependencies

```
iniparser
fftw3
epoxy(for GLSL frontend)
```

### Solving issues
* on start Waybar throws an exception "error while loading shared libraries: libcava.so: cannot open shared object file: No such file or directory".
  - It might happen when libcava for some reason hasn't been registered in the system. `sudo ldconfig` should help
  - Waybar with cava dependency is installed into /usr/local. In order to solve issue here:
    1. Drop local cava library. `sudo rm -rfv /usr/local/include/cava`, `sudo rm -rfv /usr/local/lib64/pkgconfig/cava.pc`, `sudo rm -rfv /usr/local/lib64/libcava.so`
    1. Setup prefix where waybar should be installed. `meson configure build -Dprefix="/usr"`
    1. Do build waybar. `make`
    1. Install waybar into the system. `sudo meson install -C build`
* waybar is starting but cava module doesn't react on the music.
  - In such case for at first need to make sure usual cava application is working as well
  - If so, need to comment all configuration options. Uncomment `cava_config` and provide the path to the working cava config
  - You might set too huge or too small `input_delay`. Try to setup to 4 seconds, restart waybar and check again 4 seconds past. Usual even on weak machines it should be enough
  - You might accidentally switched action `mode` to pause mode

### Raising issues
For clear understanding: this module is a cava API's consumer. So for any bugs related to cava engine you should contact to [Cava upstream](https://github.com/karlstav/cava) with the one Exception. Cava upstream doesn't provide cava as a shared library. For that this module author made a fork [libcava](https://github.com/LukashonakV/cava). So the order is 1) cava upstream 2)libcava upstream.
In case when cava releases new version and you're wanna get it, in such case it should be raised an issue to [libcava](https://github.com/LukashonakV/cava) with title [Bump]x.x.x where x.x.x is cava release version.

### Example:
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

### Style

- `#cava`
- `#cava.silent` Applied after no sound has been detected for sleep_timer seconds
- `#cava.updated` Applied when a new frame is shown

