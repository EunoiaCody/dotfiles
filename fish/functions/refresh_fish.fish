function refresh_fish --description "重载 Fish"
    # 1. 检查是否存在核心配置文件
    set -l fish_config "$HOME/.config/fish/config.fish"
    
    if not test -f "$fish_config"
        echo (set_color red)"[Error] 找不到配置文件: $fish_config"(set_color normal)
        return 1
    end

    # 2. 系统环境识别
    set -l os_name (uname)
    set -l sys_info ""

    if test "$os_name" = "Darwin"
        set sys_info (set_color yellow)"macOS (Darwin)"(set_color normal)
    else if test -f /etc/NIXOS
        set sys_info (set_color blue)"NixOS"(set_color normal)
    else
        set sys_info (set_color white)"Linux (General)"(set_color normal)
    end

    echo (set_color cyan)"🚀 正在为 $sys_info 环境重载配置..."(set_color normal)

    # 3. 核心逻辑：原地重塑进程
    # exec 会用新进程替换当前 shell，确保 conf.d/ 下的所有模块全量重新初始化
    # --login 确保重新读取 /etc/profile (NixOS 环境变量的关键)
    exec fish --login
end
