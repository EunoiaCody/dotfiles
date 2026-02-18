## 样式文件

样式使用 CSS 文件格式，文件名为 `style.css`。你也可以分别使用 `style-light.css` 和 `style-dark.css` 来跟随系统主题。

此文件的有效目录为：
- `~/.config/waybar/`
- `~/waybar/`
- `/etc/xdg/waybar/`

一个好的起点是[默认样式](https://github.com/Alexays/Waybar/blob/master/resources/style.css)。

如果你想要一些灵感：
 - https://www.reddit.com/r/unixporn/comments/9y9w0r/sway_first_rice_on_my_super_old_macbook_air/
 - https://www.reddit.com/r/unixporn/comments/a2c9kl/sway_in_the_wild/
 - https://www.reddit.com/r/unixporn/comments/a7nv6h/sway_getting_ready_for_production/
 - https://www.reddit.com/r/unixporn/comments/ac2pez/swaywaybarsway_with_kitty_awesome/
 - https://www.reddit.com/r/unixporn/comments/bmtfgd/sway_been_a_while/
 - https://www.reddit.com/r/unixporn/comments/crkjqm/sway_space_gruvbox/
 - https://www.reddit.com/r/unixporn/comments/crmfhl/swayrepost_due_to_a_privacy_issue_arch_linux_sway/
 - https://www.reddit.com/r/unixporn/comments/crzi3k/sway_my_setup_with_sway_and_waybar_incl_blood/
 - https://www.reddit.com/r/unixporn/comments/ct8gho/sway_not_gnome_shell/
 - https://www.reddit.com/r/unixporn/comments/cu0j26/sway_refined_green_99_xorg_free/
 - https://www.reddit.com/r/unixporn/comments/cyevtf/sway_my_new_rice/
 - https://www.reddit.com/r/unixporn/comments/cydh34/sway_update_base16dracula/
 - https://www.reddit.com/r/unixporn/comments/cz5vmp/sway_solarized_light_desktop/
 - https://www.reddit.com/r/unixporn/comments/d0fuc1/sway_mario_plays_the_blues/
 - https://www.reddit.com/r/unixporn/comments/d0lxbf/sway_symbolic_links_save_lives_pywal_mako/
 - https://www.reddit.com/r/unixporn/comments/1i9ft2h/sway_my_very_first_rice_on_asahi_linux/

此外，可以在[本页底部](#minimal-style)找到一个最小示例样式。

所有模块的有效 CSS 类名列在[模块页面](https://github.com/Alexays/Waybar/wiki/Modules)上。

## 栏样式

Waybar 主窗口可以使用以下方式进行样式设置：

- `window#waybar`
- `window#waybar.hidden`
- `window#waybar.<name>`
  - `<name>` 设置为_可选的_ `name` 配置属性的值。如果未设置，则此类不可用。更多信息请参阅 [Bar Config](https://github.com/Alexays/Waybar/wiki/Configuration#bar-config)
- `window#waybar.<position>`
  - `<position>` 设置为 `position` 配置属性的值。更多信息请参阅 [Bar Config](https://github.com/Alexays/Waybar/wiki/Configuration#bar-config)

### 模块组样式
每个模块组可以使用以下方式单独设置样式：

- `.modules-left`
- `.modules-center`
- `.modules-right`

### 通用模块样式

使用 `.module` 选择器的样式会影响所有模块。在实际使用中，你可能更倾向于使用更具体的 `label.module` 和 `box.module` 选择器。

```css
label.module {
    padding: 0 10px;
    box-shadow: inset 0 -3px;
}
box.module button:hover {
    box-shadow: inset 0 -3px #ffffff;
}
```

在覆盖特定模块的样式时，你需要注意[选择器优先级](https://www.w3.org/TR/selectors-3/#specificity)：

```css
/*
 * Show border for all simple text modules when the bar is in a top or bottom position.
 * a=1 b=2 c=2 -> specificity = 122
 */
window#waybar.top label.module {
    box-shadow: inset 0 -3px;
}
window#waybar.bottom label.module {
    box-shadow: inset 0 3px;
}
/*
 * But hide the border for sway/window (need to include `window#waybar` to increase specificity)
 * a=2 b=0 c=1 -> specificity = 201
 */
window#waybar #window {
    box-shadow: none;
}
```

## 按输出设置样式

Waybar 主窗口带有一个包含该窗口所在输出名称的 class 标签。这可以用于根据不同的输出应用不同的样式。例如，
```css
* { font-size: 13px; }
window.eDP-1 * { font-size: 10px; }
```
将把所有元素的默认字体大小设置为 13px（除非后续被覆盖），但对 eDP-1 输出（通常是笔记本电脑屏幕）上的所有元素应用 10px 的基本字体大小。请注意，只有顶层窗口容器在 class 标签中分配了输出名称，而非每个单独的对象。

## 交互式样式

GTK 用于应用样式，并且使用 [CSS 的有限子集](https://docs.gtk.org/gtk3/css-properties.html)。

你可以使用 `env GTK_DEBUG=interactive waybar` 来检查对象并查找其 CSS 类名、实验实时 CSS 样式以及查看 CSS 属性的当前值。

![交互式 CSS 编辑器](https://user-images.githubusercontent.com/1028741/60634665-a1525d00-9e07-11e9-8fcc-2ebb9d18b431.png)

更多信息请参阅 https://developer.gnome.org/documentation/tools/inspector.html。

## 查看组件树

与上述 GTK 检查器类似，Waybar 本身也可以告诉你哪些 GTK 组件及其类名可用于样式设置（自 [#927](https://github.com/Alexays/Waybar/pull/927) 起）。要获取此信息，只需在启用调试日志的情况下运行 Waybar：`waybar -l debug`。每个启用的栏的组件树将分别输出到控制台。示例：

```
[2020-11-30 12:38:51.141] [debug] GTK widget tree:
window#waybar.background.bottom.eDP-1.:dir(ltr)
  decoration:dir(ltr)
  box.horizontal:dir(ltr)
    box.horizontal.modules-left:dir(ltr)
      widget:dir(ltr)
        box#workspaces.horizontal:dir(ltr)
      widget:dir(ltr)
        label#mode:dir(ltr)
      widget:dir(ltr)
        box#window.horizontal.module:dir(ltr)
          image:dir(ltr)
          label:dir(ltr)
    box.horizontal.modules-center:dir(ltr)
    box.horizontal.modules-right:dir(ltr)
      widget:dir(ltr)
        box#tray.horizontal:dir(ltr)
      widget:dir(ltr)
        label#idle_inhibitor:dir(ltr)
      widget:dir(ltr)
        label#pulseaudio:dir(ltr)
      widget:dir(ltr)
        label#network:dir(ltr)
      widget:dir(ltr)
        label#cpu:dir(ltr)
      widget:dir(ltr)
        label#memory:dir(ltr)
      widget:dir(ltr)
        label#temperature:dir(ltr)
      widget:dir(ltr)
        label#backlight:dir(ltr)
      widget:dir(ltr)
        label#battery:dir(ltr)
      widget:dir(ltr)
        label#clock:dir(ltr)
```

## 最小样式

一个最小的 `style.css` 文件可以如下所示：
```css
* {
    border: none;
    border-radius: 0;
    font-family: Roboto, Helvetica, Arial, sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(43, 48, 59, 0.5);
    border-bottom: 3px solid rgba(100, 114, 125, 0.5);
    color: white;
}

tooltip {
  background: rgba(43, 48, 59, 0.5);
  border: 1px solid rgba(100, 114, 125, 0.5);
}
tooltip label {
  color: white;
}

#workspaces button {
    padding: 0 5px;
    background: transparent;
    color: white;
    border-bottom: 3px solid transparent;
}

#workspaces button.focused {
    background: #64727D;
    border-bottom: 3px solid white;
}

#mode, #clock, #battery {
    padding: 0 10px;
}

#mode {
    background: #64727D;
    border-bottom: 3px solid white;
}

#clock {
    background-color: #64727D;
}

#battery {
    background-color: #ffffff;
    color: black;
}

#battery.charging {
    color: white;
    background-color: #26A65B;
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: black;
    }
}

#battery.warning:not(.charging) {
    background: #f53c3c;
    color: white;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: steps(12);
    animation-iteration-count: infinite;
    animation-direction: alternate;
}
```

## 减少动画的 CPU 使用率

使用 CSS 属性 `animation-*` 的动画可能导致较高的 CPU 使用率。这并不取决于 Waybar，而是取决于 CSS 引擎，因为它会在元素每次状态变化时重新渲染。
可以使用 `animation-timing-function` 配合 `steps()` 代替 `linear` 来减少 CPU 使用率。如下所示：

```
    animation-timing-function: steps(12);
```

`steps()` 的值越大，动画越平滑，但 CPU 使用率也会增加。或者，可以通过增加持续时间来降低状态变化的频率。如下所示：

```
    animation-duration: 3.0s;
```

## 让 Waybar 跟随 Gtk 主题

Gtk CSS 有一些全局主题变量，通过使用这些变量而非硬编码的值，Waybar 将自动跟随你的 Gtk 主题。示例：

```css
window#waybar {
    font-family: inherit;
    background: @theme_base_color;
    border-bottom: 1px solid @unfocused_borders;
    color: @theme_text_color;
}
```

Gtk 主题变量可以通过使用 `shade`、`mix` 和/或 `alpha` 修饰符进一步调整。例如，如果你想让栏亮度增加 25% 并且透明度为 10%，你可以这样设置背景样式：

```css
window#waybar {
    background: shade(alpha(@borders, 0.9), 1.25);
}
```


有关有效的 Gtk 主题变量列表，请查看 [Gnome 在 Gitlab 上的样式表](https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gtk/theme/Adwaita/_colors-public.scss)。
