{ pkgs, ... }: {

  # 1. 核心修复：必须引入 OrbStack 的硬件配置！
  # 这会帮你自动配置好 fileSystems (根目录挂载)
  imports = [
    /etc/nixos/orbstack.nix
  ];

  fileSystems."/" = {
    device = "/dev/vdb1";
    fsType = "btrfs";
    options = [ "subvol=/" "noatime" "ssd" ]; # 简化挂载参数，确保能跑通
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
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish; # 既然你用了 fish
  };

  # 既然是 OrbStack，通常需要这个
  # services.orbstack.enable = true;
  boot.loader.grub.enable = false;

  # 显式开启网络管理，防止冲突
  networking = {
    useDHCP = false;
    hostName = "nixos";
  };
  services.resolved.enable = true;
  systemd.network.enable = true;

  # 修复 systemd-networkd 报错：确保 eth0 被正确接管
  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    networkConfig.DHCP = "yes";
  };

  system.stateVersion = "23.11";
}
