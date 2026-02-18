The Cava GLSL frontend delegates the visualization of incoming audio data to the GPU via OpenGL.

There are some mandatory dependencies that need to be satisfied in order for Cava GLSL to be built and function properly:
1. epoxy library must be installed on the system
2. Vertex and fragment shaders from the original project must be used. They should be downloaded, and the file paths must be configured correctly in the Waybar Cava configuration:
   1. [cava shaders](https://github.com/karlstav/cava/tree/master/output/shaders)
   2. [libcava shaders](https://github.com/LukashonakV/cava/tree/master/output/shaders)
3. It is highly recommended to have a separate cava configuration for the Waybar Cava GLSL module and to use this as the `cava_config` in the Waybar configuration.
4. It is common for cava configurations to be placed in the `XDG_CONFIG_HOME` directory, including shaders as well. Consider keeping them in the `$XDG_CONFIG_HOME/cava/shaders` folder.

Key configuration options:
1. `bars`. The more values the parameter has, the more interesting the visualization becomes.
2. `method` in output section must be set to `sdl_glsl`
3. `sdl_width` and `sdl_height` manage the size of the module. Adjust them according to your needs.
4.  Shaders for sdl_glsl, located in $HOME/.config/cava/shaders. Example:
`vertex_shader = pass_through.vert
fragment_shader = spectrogram.frag`
5. Set `continuous_rendering` to 1 to enable smooth rendering; set it to 0 otherwise. It is recommended to keep it set to 1.
6. `background`, `foreground`, and `gradient_color_N` (where N is a number between 1 and 8) must be defined using hex code

#### Example 1
1. waybar module config
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#1.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. cava config for waybar -> 
[waybar_cava#1.conf.tar.gz](https://github.com/user-attachments/files/24260316/waybar_cava.1.conf.tar.gz)

https://github.com/user-attachments/assets/52ddd326-e254-4571-b1e9-72b19e57f0c7

#### Example 2
1. waybar module config
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#2.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. cava config for waybar -> 
[waybar_cava#2.conf.tar.gz](https://github.com/user-attachments/files/24260344/waybar_cava.2.conf.tar.gz)

https://github.com/user-attachments/assets/ee7a7b7e-2e02-4190-92d8-b9fd72414950

#### Example 3
1. waybar module config
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#3.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. cava config for waybar -> 
[waybar_cava#3.conf.tar.gz](https://github.com/user-attachments/files/24260349/waybar_cava.3.conf.tar.gz)

https://github.com/user-attachments/assets/303f5444-e4a0-43ac-83b3-5471b65edf3c

#### Example 4
1. waybar module config
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#4.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. cava config for waybar -> 
[waybar_cava#4.conf.tar.gz](https://github.com/user-attachments/files/24260354/waybar_cava.4.conf.tar.gz)

https://github.com/user-attachments/assets/9a9d3e3a-ddc6-4f32-b386-736a7e6059b8

#### Example 5
1. waybar module config
```jsonc
    "cava": {
        "cava_config": "$XDG_CONFIG_HOME/cava/waybar_cava#5.conf",
        "input_delay": 2,
        "actions": {
                   "on-click-right": "mode"
                   }
    },
```
2. cava config for waybar -> 
[waybar_cava#5.conf.tar.gz](https://github.com/user-attachments/files/24260359/waybar_cava.5.conf.tar.gz)

https://github.com/user-attachments/assets/ef4fcddc-47a6-4651-87c4-96907eb99f5c
