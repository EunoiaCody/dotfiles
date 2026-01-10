function gateway
    switch $argv[1]
        case on
            # 自动获取活跃的网络接口
            set -l iface (route -n get default 2>/dev/null | grep interface | awk '{print $2}')

            if test -z "$iface"
                echo "❌ 无法找到活跃的网络接口"
                return 1
            end

            # 获取该接口的 IP
            set -l ip (ipconfig getifaddr $iface 2>/dev/null)

            if test -z "$ip"
                echo "❌ 无法获取 IP 地址（接口:  $iface）"
                return 1
            end

            echo "🔧 使用网卡: $iface"
            echo "📡 本机 IP: $ip"
            echo ""

            # 启用 IP 转发
            sudo sysctl -w net.inet.ip.forwarding=1 >/dev/null

            # 启用 NAT
            echo "nat on $iface from any to any -> ($iface)" | sudo pfctl -ef - 2>/dev/null

            echo "✅ 网关已启用！"
            echo ""
            echo "📱 其他设备设置："
            echo "   网关: $ip"
            echo "   DNS: $ip （或 8.8.8.8）"

        case off
            sudo sysctl -w net.inet.ip.forwarding=0 >/dev/null
            sudo pfctl -d 2>/dev/null
            echo "✅ 网关已关闭"

        case status
            # 检查状态
            set -l forwarding (sysctl -n net.inet.ip.forwarding)
            set -l iface (route -n get default 2>/dev/null | grep interface | awk '{print $2}')
            set -l ip (ipconfig getifaddr $iface 2>/dev/null)

            echo "━━━━━━━━━━━━━━━━━━━━━━"
            if test "$forwarding" = 1
                echo "IP 转发:  ✅ 已启用"
            else
                echo "IP 转发: ❌ 已禁用"
            end

            echo "网卡: $iface"
            echo "IP 地址: $ip"

            # 检查 pf 状态
            if sudo pfctl -s info >/dev/null 2>&1
                echo "防火墙:  ✅ 已启用"
            else
                echo "防火墙: ❌ 已禁用"
            end
            echo "━━━━━━━━━━━━━━━━━━━━━━"

        case '*'
            echo "用法: gateway [on|off|status]"
    end
end
