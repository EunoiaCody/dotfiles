{ pkgs, ... }: {

  import = [
    <orbstack/nixos>
  ];

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

  # 设置你的用户
  users.users.eunoiacody = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish; # 既然你用了 fish
  };

  # 既然是 OrbStack，通常需要这个
  services.orbstack.enable = true;

  system.stateVersion = "23.11";
}
