{ pkgs, ... }: {
  # 安装系统级软件包（全用户可用）
  environment.systemPackages = [
    pkgs.vim
    pkgs.git
  ];

  # 允许使用 Nix 管理 zsh/fish (即使你在 home-manager 里也配了，这里也需要开启 shell 支持)
  programs.fish.enable = true;

  programs.zsh.enable = {
    enable = true;
    interactiveShellInit = ''
      # 如果当前不是在 Fish 中，则启动 Fish
      if [[ $- == *i* && -x "$(command -v fish)" && $TERM != "dumb" ]]; then
        exec fish
      fi
    '';
  };

  # macOS 系统设置 (对应 System Settings 里的选项)
  system.defaults = {
    dock.autohide = true; # 自动隐藏 Dock
    finder.AppleShowAllExtensions = true; # 显示所有文件扩展名
    NSGlobalDomain.AppleInterfaceStyle = "Dark"; # 开启深色模式
    trackpad.Clicking = true; # 开启轻点触摸板确认
  };

  # 设置 Nix 守护进程状态
  services.nix-daemon.enable = true;

  # 必须设置，以防版本冲突
  system.stateVersion = 4;
}
