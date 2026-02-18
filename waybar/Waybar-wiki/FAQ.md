- [How do I add multiple instances of a module?](#how-do-i-add-multiple-instances-of-a-module)
- [The Workspace-Buttons have a strange hover effect](#the-workspace-buttons-have-a-strange-hover-effect)
- [How can I generate a debug build?](#how-can-i-generate-a-debug-build)
- [The icons from the default configuration aren't rendered](#the-icons-from-the-default-configuration-arent-rendered)
- [How do I display text?](#how-do-i-display-text)
- [How can I prevent modules from changing size?](#how-can-i-prevent-modules-from-changing-size-aka-fixed-width-modules-and-monospace-fonts)
- [How to use with Sway?](#how-to-use-with-sway)
- [How can I temporarily hide the bars?](#how-can-I-temporarily-hide-the-bars)
- [How can I reload the configuration without restarting waybar?](#how-can-I-reload-the-configuration-without-restarting-waybar)
- [Workspace buttons are too wide with some GTK themes](#workspace-buttons-are-too-wide-with-some-gtk-themes)
- [My Slider doesn't show/looks small/doesn't work properly](#slider-looks-small)


***

## How do I add multiple instances of a module?

Have a look here: [Multiple instances of a module](https://github.com/Alexays/Waybar/wiki/Configuration#multiple-instances-of-a-module)

## The Workspace-Buttons have a strange hover effect

It's not a bug, the original issue [#60](https://github.com/Alexays/Waybar/issues/60).

But if you don't like the effect you can disable it by adding the following snippet to your `style.css`:
```css
#workspaces button:hover {
    box-shadow: inherit;
    text-shadow: inherit;
}
```

Additionally, to remove all hover effects from workspaces, add the following in addition to the above:
```css
#workspaces button:hover {
    background: <original-color>;
    border: <original-color>;
    padding: 0 3px;
}
```

## How can I generate a debug build?

A debug build can be helpful when fixing bugs, because it generates a backtrace with debugging symbols.

This can be done with:
```sh
make build-debug
```

## The icons from the default configuration aren't rendered

You need to install `otf-font-awesome`. See here on how to install the [Font Awesome OTF package](https://github.com/Alexays/Waybar/wiki/Installation#how-to-use-with-sway).

## How do I display text?

Create a [Custom](./Module:-Custom) module with the `format` field specified with your text.

## How can I prevent modules from changing size? (aka. fixed-width modules, and monospace fonts)

First make sure to set a monospace font:
```css
* {
    font-family: monospace;
}
```

Then change the module format so that it stays at a fixed width. Waybar uses [fmt](https://github.com/fmtlib/fmt) for formatting so the following syntax is an example of how to set the CPU percentage to be at least 2 characters wide:
```jsonc
"format": "{usage:2}%"
```

The fmt library has two issues. First it provides no way to set the _maximum_ length of a field, only the _minimum_ length. So expect width changes when the text becomes longer than the minimum width. This can be partially worked around with the `max-length`parameter. See https://github.com/Alexays/Waybar/issues/486.
 
The second issue concerns floating point numbers. Waybar comes with a custom formatter that enforces a fixed width for them (network bandwidth, disk usage, etc). You need to specify either `>`, `<`, or `=` as format modifier. This will align the number as requested and make it fixed width. See https://github.com/Alexays/Waybar/pull/472 for details, examples and limitations.

A last but painful issue arises with pango/cairo font rendering for custom glyphs (Font Awesome icons, most probably). Cairo keeps the font used for the last non-whitespace character to render the next whitespaces. This means that the two next lines, despite containing the same number of characters, will not render with the same width.
```
         10 spaces
  2 leading spaces
```

You can either move all your icons at the end of the module, so that they have no following spaces to alter, or use pango-specific markup around all the icons, like this: `<span font=\"Font Awesome 5 Free\"></span>`. This forces cairo to return to the default font when leaving the `<span>` and avoids using spaces of the wrong kind. You may experience improvements as https://gitlab.gnome.org/GNOME/pango/-/issues/249 seems to work against that.


## How to use with Sway?

You can use Waybar by defining in your Sway config file:
```
bar {
    swaybar_command waybar
}
```

or at the end of your sway config file

```
exec waybar
```

## How can I temporarily hide the bars?
You can toggle the visibility of the bars with:
```sh
killall -SIGUSR1 waybar
```

## How can I reload the configuration without restarting waybar?
***Only works on waybar after version v0.9.5***
```sh
killall -SIGUSR2 waybar
```

## Workspace buttons are too wide with some GTK themes

![](https://user-images.githubusercontent.com/27376783/47964799-26019700-e03f-11e8-8b0f-1dd4862b6241.png)

In certain GTK themes, the button.text-button.flat element's min-width property is assigned a large value. You can override it in waybar's `style.css`

```css
#workspaces button {
  min-width: 20px;
}
```
<a name="slider-looks-small"></a>

## My Slider doesn't show/looks small/doesn't work properly

Like all widgets in GTK, its width and height is determined in CSS. However, in a surprising turn, it's ever more important that you style your slider widget, otherwise its width and height will be *close to* 0, and it won't work properly when dragging around. It's worth noting that only the `trough` CSS Node actually requires any minimum height or width.

Try this if you're experiencing issues with sliders:

```css
#pulseaudio-slider trough, #backlight-slider trough {
    min-height: 10px;
    min-width: 80px;
}
```