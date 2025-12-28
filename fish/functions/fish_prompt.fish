function fish_prompt
    set -l last_status $status
    set -l cwd (prompt_pwd)

    # --- Catppuccin Mocha Palette ---
    # https://catppuccin.com/palette/
    set -l ctp_path 89b4fa # Blue (Path)
    set -l ctp_git cba6f7 # Mauve (Git)
    set -l ctp_success a6e3a1 # Green (Success)
    set -l ctp_error f38ba8 # Red (Error)
    set -l ctp_connector 7f849c # Overlay 1 (Connector)
    set -l ctp_decoration 6c7086 # Overlay 0 (Decoration)
    set -l ctp_date a6adc8 # Subtext 0 (Date)

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
                    # Arch 系拆分
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

    # 1. 准备颜色变量
    set -l c_dec (set_color $ctp_decoration)
    set -l c_path (set_color $ctp_path --bold)
    set -l c_git (set_color $ctp_git)
    set -l c_date (set_color $ctp_date)
    set -l c_reset (set_color normal)

    # 2. 构建左侧内容
    set -l left_str "$c_dec┌──$c_path $os_icon  "(whoami)" $cwd "
    set -l git_info (fish_git_prompt | string trim -c ' ()')
    if test -n "$git_info"
        set left_str "$left_str$c_git─  $git_info"
    end

    # 3. 构建右侧内容 (日期)
    set -l right_str "$c_date"(date "+%y-%m-%d %H:%M ")"$c_reset"

    # 4. 计算填充并输出
    set -l left_len (string length --visible "$left_str")
    set -l right_len (string length --visible "$right_str")
    set -l pad_len (math $COLUMNS - $left_len - $right_len)

    if test $pad_len -lt 1
        set pad_len 1
    end

    set -l padding (string repeat -n $pad_len " ")

    echo "$left_str$padding$right_str"

    set_color $ctp_connector # 灰色连接线
    echo -n "└─"

    if test $last_status -eq 0
        set_color $ctp_success # 成功状态
        echo -n " ✔ "
    else
        set_color $ctp_error # 失败状态
        echo -n " ✘ "
    end

    set_color normal
end
