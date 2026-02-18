以下是已知可用的托盘小程序列表。

### NetworkManager

NetworkManager 是一个为系统提供自动连接网络的检测和配置功能的程序。NetworkManager 的功能对无线和有线网络都很有用。对于无线网络，NetworkManager 优先选择已知的无线网络，并能够切换到最可靠的网络。支持 NetworkManager 的应用程序可以在在线和离线模式之间切换。NetworkManager 还优先选择有线连接而非无线连接，并支持调制解调器连接和某些类型的 VPN。

要使用此小程序，请安装 networkmanager，启用 `systemctl enable NetworkManager.service`，并将以下内容添加到你的 sway 配置中

```shell
exec --no-startup-id 'nm-applet --indicator'
```

### Blueman

Blueman 是一个用 GTK 编写的功能齐全的蓝牙管理器。

要使用此小程序，请启用 [bluetooth daemon](https://wiki.archlinux.org/index.php/Bluetooth)，安装 blueman，并将以下内容添加到你的 sway 配置中。

```shell
exec --no-startup-id 'blueman-applet'
```

### Electron 应用

像 slack、telegram、[caprine](https://github.com/sindresorhus/caprine) 和 discord 这样的应用应该可以直接使用。
