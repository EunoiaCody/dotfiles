你使用的是哪个发行版？

- [Alpine](#alpine)
- [Arch](#arch)
- [Fedora](#fedora)
- [Fedora Silverblue](#fedora-silverblue)
- [FreeBSD](#freebsd)
- [Gentoo](#gentoo)
- [openSUSE](#opensuse)
- [NixOS](#nixos)
- [Ubuntu 和 Debian](#ubuntu-and-debian)
- [Void](#void)
- [其他](#other)

## Alpine

从 Alpine v3.11 开始，你可以从 `community` 仓库安装 [`waybar` 软件包](https://pkgs.alpinelinux.org/packages?name=waybar&branch=edge&repo=&arch=&maintainer=)。以超级用户身份输入：

```sh
apk add waybar
```

## Arch

在 Arch 上，你可以直接从 extra 仓库安装 [waybar](https://www.archlinux.org/packages/extra/x86_64/waybar/)。你也可以从 AUR 安装 [waybar-git](https://aur.archlinux.org/packages/waybar-git/)。

另一个选择是使用 [Omarchy](https://github.com/basecamp/omarchy)，这是一个基于 Arch 的定制发行版，已经预配置了 Waybar 和 Hyprland。如果你更喜欢使用现成的默认配置，而不是从头手动配置 Waybar，这种方式可以节省时间。

## Fedora

在 Fedora 上，Waybar 也在官方仓库中。使用 `dnf install waybar` 安装。

### Fedora Silverblue

Fedora Silverblue 使用不可变的基于 ostree 的文件系统，这意味着通常你不能直接安装软件包。安装 Waybar 有三种主要方法。

#### 软件包叠加（最简单）
你可以使用[软件包叠加](https://docs.fedoraproject.org/en-US/fedora-silverblue/getting-started/#package-layering)从官方仓库安装 Waybar：
```sh
rpm-ostree install waybar
```
这与使用 `dnf` 安装的软件包功能类似，需要重启才能生效。`rpm-ostree update` 将正常工作。

#### Flatpak
[Flatpak](https://flatpak.org/) 是在 Silverblue 上安装软件的常用方法。目前没有官方的 Waybar Flatpak 软件包。

#### 自定义 ostree 镜像
可以准备一个已包含 Waybar 的自定义 ostree 镜像。你可以通过修改 [workstation-ostree-config](https://pagure.io/workstation-ostree-config) 来实现。相关指导可在[这里](https://discussion.fedoraproject.org/t/minimal-or-custom-silverblue-ostree-images/1574)找到。
## Gentoo

在 Gentoo 上，该软件包在官方仓库中。使用 `emerge -a waybar` 安装。请注意，目前所有版本都是不稳定的，因此你需要接受相应的关键字。

## FreeBSD
如果尚未安装音量控制，你可能还需要运行 `pkg install pavucontrol`。
```sh
pkg install waybar
```

## openSUSE

在 openSUSE 上，Waybar 在官方仓库中。使用 `zypper in waybar` 安装。参见[开发项目](https://build.opensuse.org/package/show/X11:Wayland/waybar)。

## NixOS

在 NixOS 上，你可以通过以下命令试用 Waybar：`nix-shell -p waybar`，然后在进入 shell 后运行 `waybar`。这将立即以命令式方式启动一个默认的 waybar。

你可以使用 [NixOS](https://search.nixos.org/options?channel=unstable&query=waybar) 或 [Home-Manager](https://home-manager-options.extranix.com/?query=waybar) 选项将其永久添加到你的配置中。

注意：它们听起来可能相似，但作用域完全不同，这些选项不能混合使用。NixOS 选项仅在系统配置中使用，Home-Manager 选项仅在用户配置中使用。你可以将用户配置添加到系统配置中，更多信息请参阅 Home-Manager 文档。

在 NixOS 中：

```nix
  programs.waybar.enable = true;
```
这将安装状态栏，你可以像在其他发行版上一样通过传统的 dotfiles 进行配置。


Home-Manager 允许在你的配置中对 waybar 本身进行更声明式的配置。请查看相关选项以获取最新的操作方法。


## Ubuntu 和 Debian

在 Ubuntu 上，从 20.04 LTS（"Focal Fossa"）版本开始，Waybar 以 `waybar` 的名称在 `universe` 仓库中可用。使用 `apt-get install waybar` 安装。参见 [Ubuntu 软件包页面](https://packages.ubuntu.com/search?keywords=waybar&searchon=names&suite=all&section=all)。

所需的字体从 22.04 LTS（"Jammy Jellyfish"）开始已作为软件包提供，使用 `apt-get install fonts-font-awesome fonts-fork-awesome` 安装。

Debian 从 1.2.0（"bookworm"）版本开始提供相同的软件包。

## Void

在 Void 上，该软件包以 `Waybar` 的名称提供。使用 `xbps-install -S Waybar` 安装。

## 其他

要构建和安装 Waybar，只需运行：

```sh
git clone https://github.com/Alexays/Waybar && cd Waybar && sudo make install
```

-----

## 如何与 Sway 一起使用？

首先，确保你已安装 `otf-font-awesome` 软件包。这些是由 Font Awesome 提供的免费字体，在 Waybar 配置中常用。你也可以从[此链接](https://fontawesome.com/how-to-use/on-the-desktop/setup/getting-started)下载 OTF 字体包。

你可以通过在 Sway 配置文件中定义来使用 Waybar：
```
bar swaybar_command waybar
```

或者在 Sway 配置文件的末尾添加

```
exec waybar
```
