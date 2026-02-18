Here is a list of known working tray applets.

### NetworkManager

NetworkManager is a program for providing detection and configuration for systems to automatically connect to networks. NetworkManager's functionality can be useful for both wireless and wired networks. For wireless networks, NetworkManager prefers known wireless networks and has the ability to switch to the most reliable network. NetworkManager-aware applications can switch from online and offline mode. NetworkManager also prefers wired connections over wireless ones, has support for modem connections and certain types of VPN.

To use this applet install networkmanager, enable `systemctl enable NetworkManager.service`, and add this to your sway config

```shell
exec --no-startup-id 'nm-applet --indicator'
```

### Blueman

Blueman is a full featured Bluetooth manager written in GTK.

To use this applet enable the [bluetooth daemon](https://wiki.archlinux.org/index.php/Bluetooth), install blueman, and add this to your sway config. 

```shell
exec --no-startup-id 'blueman-applet'
```

### Electron Apps

Apps like slack, telegram, [caprine](https://github.com/sindresorhus/caprine), and discord should just work.