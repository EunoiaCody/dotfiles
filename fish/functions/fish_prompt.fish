function fish_prompt
    set -l last_status $status
    set -l cwd (prompt_pwd)

    # --- Catppuccin 颜色定义 ---
    set -l ctp_mauve cba6f7 # 路径颜色 (Purple)
    set -l ctp_pink f5c2e7 # Git 颜色 (Pink)
    set -l ctp_mauve_status cba6f7 # 成功状态颜色 (Mauve)
    set -l ctp_red f38ba8 # 失败状态颜色 (Red)
    set -l ctp_subtext1 6c7086 # 连接线颜色
    set -l ctp_mantle 45475a # 装饰线颜色

    # --- 1. 定义系统图标 ---
    set -l os_icon "" # 默认图标
    set -l system_name (uname -s)

    if test "$system_name" = Linux
        # 优先检查是否是 Termux
        if set -q TERMUX_VERSION
            set os_icon "󰀲" # Android
        else
            # 区分 Linux 发行版
            set -l distro_id (cat /etc/os-release 2>/dev/null | grep '^ID=' | string replace --regex '^ID="?([a-z0-9-]+)"?$' '\1')

            switch $distro_id
                case ubuntu "ubuntu*"
                    set os_icon "" # Ubuntu
                    # 🛠️ Arch 系拆分
                case arch archarm "*arch"
                    set os_icon "" # Arch Linux
                case manjaro
                    set os_icon "" # Manjaro 专用图标
                case fedora "fedora*"
                    set os_icon "" # Fedora
                case debian
                    set os_icon "" # Debian
                case pop pop-os
                    set os_icon "" # Pop!_OS
                case centos "centos*"
                    set os_icon "" # CentOS
                case rhel "rhel*"
                    set os_icon "" # RHEL
                case void
                    set os_icon "" # Void Linux
                case alpine
                    set os_icon "" # Alpine Linux
                case kali
                    set os_icon "" # Kali Linux
                case linuxmint
                    set os_icon "" # Linux Mint
                case nixos "nixos*"
                    set os_icon "" # NixOS
                case raspbian "raspbian*"
                    set os_icon "" # Raspberry Pi OS
                case "*" # 默认 Linux
                    set os_icon "" # Tux 企鹅
            end
        end
    else if test "$system_name" = Darwin
        set os_icon "" # macOS (Apple)
    else if test "$system_name" = CYGWIN_NT
        set os_icon "" # Windows
    end

    # ----------------------------------

    echo "" # 上方空一行

    # --- 第二部分：Prompt 结构 ---
    set_color $ctp_mantle # 灰色连接线
    echo -n "┌──"

    set_color $ctp_mauve --bold # 路径颜色
    echo -n " $os_icon  $cwd "

    if fish_git_prompt >/dev/null
        set_color $ctp_pink # Git 颜色
        set -l git_info (fish_git_prompt | string trim -c ' ()')
        echo -n "─  $git_info"
    end

    set_color normal
    echo "" # 换行

    set_color $ctp_subtext1 # 灰色连接线
    echo -n "└─"

    if test $last_status -eq 0
        set_color $ctp_mauve_status # 成功状态
        echo -n " ✔ "
    else
        set_color $ctp_red # 失败状态
        echo -n " ✘ "
    end

    set_color normal
end
