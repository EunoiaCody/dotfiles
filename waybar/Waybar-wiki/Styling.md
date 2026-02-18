## Style file

Styling is done using the CSS file format and with a file named `style.css`. You can also use `style-light.css` and `style-dark.css` respectively to follow the system theme.

Valid directories for this file are: 
- `~/.config/waybar/`
- `~/waybar/`
- `/etc/xdg/waybar/`

A good starting point is the [default style](https://github.com/Alexays/Waybar/blob/master/resources/style.css).

If you want some ideas:
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

Also a minimal example style can be found on the [bottom of this page](#minimal-style).

All valid CSS classes for the modules are listed on the [modules page](https://github.com/Alexays/Waybar/wiki/Modules).

## Bar styling

The main waybar window can be styled with the following:

- `window#waybar`
- `window#waybar.hidden`
- `window#waybar.<name>`
  - `<name>` is set to the value of the _optional_ `name` configuration property. If not set, this class is not available. For more information see [Bar Config](https://github.com/Alexays/Waybar/wiki/Configuration#bar-config)
- `window#waybar.<position>`
  - `<position>` is set to the value of the `position` configuration property. For more information see [Bar Config](https://github.com/Alexays/Waybar/wiki/Configuration#bar-config)

### Module Group Styling
Each module group can be styled individually with the following:

- `.modules-left`
- `.modules-center`
- `.modules-right`

### Generic module style

A style with the `.module` selector would affect all the modules. In practice, you may prefer to use more specific `label.module` and `box.module` selectors.

```css
label.module {
    padding: 0 10px;
    box-shadow: inset 0 -3px;
}
box.module button:hover {
    box-shadow: inset 0 -3px #ffffff;
}
```

You need to remember about [selector specificity](https://www.w3.org/TR/selectors-3/#specificity) when overriding the style for a specific module:

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

## Per-output styling

The main waybar windows carry a class tag with the name of the output this window is shown on. This can be used to apply different styles depending on the output. E.g.,
```css
* { font-size: 13px; }
window.eDP-1 * { font-size: 10px; }
```
will set the default font size of all elements to 13px unless overridden later on, but apply a base font size of 10px to all elements on the eDP-1 output (typically, the laptop screen). Note that only the top-level window container has the output assigned in the class tags, not each individual object.

## Interactive styling

GTK is used to apply styles and works with [a limited subset of CSS](https://docs.gtk.org/gtk3/css-properties.html).

You can use `env GTK_DEBUG=interactive waybar` to inspect objects and find their CSS classes, experiment with live CSS styles, and lookup the current value of CSS properties.

![Interactive CSS Editor](https://user-images.githubusercontent.com/1028741/60634665-a1525d00-9e07-11e9-8fcc-2ebb9d18b431.png)

See https://developer.gnome.org/documentation/tools/inspector.html for more information.

## Viewing the widget tree

Like the GTK inspector above, Waybar itself can also tell you what GTK widgets with what classes are available for styling (since [#927](https://github.com/Alexays/Waybar/pull/927)). To get this information, simply run Waybar with debug logging enabled: `waybar -l debug`. Each enabled bar's widget tree will be separately logged to the console. Example:

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

## Minimal style

A minimal `style.css` file could look like this:
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

## Reduce CPU usage in animation

Animations using the CSS properties `animation-*` may lead to high CPU usage. This does not depend on Waybar, rather on the CSS engine that will render the element everytime it changes state.
`animation-timing-function` can be used with `steps()` instead of `linear` to reduce CPU usage. Like this:

```
    animation-timing-function: steps(12);
```

The higher the value of `steps()`, the smoother the animation will be, but also CPU usage will increase. Alternatively decrease the frequency of state changes by increasing their duration. Like this:

```
    animation-duration: 3.0s;
```

## Making Waybar follow the Gtk theme

Gtk CSS has some global theme variables, and by using these instead of hardcoded values, Waybar will automatically follow your Gtk theme. An example:

```css
window#waybar {
    font-family: inherit;
    background: @theme_base_color;
    border-bottom: 1px solid @unfocused_borders;
    color: @theme_text_color;
}
```

The Gtk theme variables can be further refined by using the `shade`, `mix`, and/or `alpha` modifiers. For example, if you want to make the bar 25 % lighter and 10 % transparent, you can style the background like this:

```css
window#waybar {
    background: shade(alpha(@borders, 0.9), 1.25);
}
```


For a list of valid Gtk theme variables, check out [Gnome's stylesheet on Gitlab](https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gtk/theme/Adwaita/_colors-public.scss).
