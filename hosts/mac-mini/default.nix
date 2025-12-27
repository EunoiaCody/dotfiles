{ pkgs, ... }: {
  # 允许安装非自由软件 (修复 Copilot 等报错)
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.enable = false; # 由 Determinate 管理

  system.primaryUser = "eunoiacody";
  users.users.eunoiacody = {
    name = "eunoiacody";
    home = "/Users/eunoiacody";
  };

  # Homebrew 核心配置
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    taps = [
      "thusvill/livewallpaper"
      "dimentium/autoraise"
      "nikitabobko/tap"
      "Felixkratz/formulae"
    ];

    brews = [ "mas" "borders" "sketchybar" ];

    casks = [
      "google-chrome"
      "livewallpaper"
      "obs"
      "visual-studio-code"
      "wechat"
      "orbstack"
      "qq"
      "kitty"
      "neovide-app"
      "tailscale-app"
      "steam"
      "steamcmd"
      "telegram-desktop"
      "aerospace"
      "dimentium/autoraise/autoraiseapp"
    ];
  };

  # 系统层级的包
  environment.systemPackages = [ pkgs.vim pkgs.git ];

  # macOS 系统偏好
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
  };

  system.stateVersion = 4;
}
