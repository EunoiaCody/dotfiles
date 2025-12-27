{ pkgs, ... }: {

  # 设置系统语言环境
  i18n.defaultLocale = "zh_CN.UTF-8";

  # 设置中文字体（否则终端和应用可能会显示乱码/方块）
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];
  };

  # 必须引入 OrbStack 的硬件配置！
  # 这会帮你自动配置好 fileSystems (根目录挂载)
  imports = [
    /etc/nixos/orbstack.nix
  ];

  fileSystems."/" = {
    device = "/dev/vdb1";
    fsType = "btrfs";
  };

  # 允许非自由软件
  nixpkgs.config.allowUnfree = true;

  # 开启 Flakes 和新版指令集
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 基础系统包
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  programs.fish.enable = true;

  # 设置你的用户
  users.users.eunoiacody = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish; # 既然你用了 fish
  };

  # 既然是 OrbStack，通常需要这个
  # services.orbstack.enable = true;
  boot.loader.grub.enable = false;

  system.stateVersion = "23.11";
}
