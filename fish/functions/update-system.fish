function update-system
    echo "请选择操作："
    echo "  1. 更新并关机"
    echo "  2. 更新并重启"
    echo ""

    read -P "输入选项 (1/2): " choice

    switch "$choice"
        case 1
            set action shutdown
            set action_desc 关机
        case 2
            set action reboot
            set action_desc 重启
        case '*'
            echo "❌ 无效选项"
            return 1
    end

    echo ""
    read -s -P "请输入 sudo 密码: " sudo_password
    echo ""

    if test -z "$sudo_password"
        echo "❌ 密码不能为空"
        return 1
    end

    # 清除现有 sudo 缓存，并用输入的密码验证（启动缓存）
    sudo -k
    echo "$sudo_password" | sudo -S -v 2>/dev/null

    if test $status -ne 0
        set -e sudo_password
        echo "❌ sudo 密码错误"
        return 1
    end

    # 删除临时密码变量
    set -e sudo_password

    # 执行系统更新（使用已缓存的 sudo 凭证，支持交互）
    echo ""
    echo "🚀 开始执行 paru -Syu ..."
    paru -Syu

    if test $status -ne 0
        echo ""
        echo "⚠️ 更新过程出现问题，取消 $action_desc"
        return 1
    end

    echo ""
    echo "✅ 更新完成，即将 $action_desc ..."

    switch "$action"
        case shutdown
            sudo shutdown -h now
        case reboot
            sudo reboot
    end
end
