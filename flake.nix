{
  description = "EunoiaCody's macOS System and Dotfiles Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      system = "aarch64-darwin";
      # 替换为你的实际主机名，可以在终端输入 `hostname` 查看
      nodename = "EunoiadeMac-mini";
    in
    {
      # 使用 darwinConfigurations 替代原有的单独 homeConfigurations
      darwinConfigurations."${nodename}" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          # --- 系统层级配置 ---
          ({ pkgs, ... }: {
            # 必须设置，用于告知 nix-darwin 这里的系统架构
            nixpkgs.hostPlatform = system;

            nix.enable = false;

            system.primaryUser = "eunoiacody";

            users.users.eunoiacody = {
              name = "eunoiacody";
              home = "/Users/eunoiacody";
            };

            homebrew = {
              enable = true;
              onActivation.cleanup = "zap";
              onActivation.autoUpdate = true;
              onActivation.upgrade = true;

              taps = [
                "dimentium/autoraise"
                "nikitabobko/tap"
                "Felixkratz/formulae"
              ];

              brews = [
                "mas"
                "borders"
                "sketchybar"
              ];

              casks = [
                "google-chrome"
                "obs"
                "visual-studio-code"
                "wechat"
                "orbstack"
                "qq"
                "kitty"
                "tailscale-app"
                "steam"
                "steamcmd"
                "tailscale-app"
                "telegram-desktop"
                "dimentium/autoraise/autoraiseapp"
                "aerospace"
              ];
            };

            # 这里的包是全系统用户可用的
            environment.systemPackages = [ pkgs.vim pkgs.git ];

            # macOS 系统偏好设置
            system.defaults = {
              dock.autohide = true; # 自动隐藏 Dock
              finder.AppleShowAllExtensions = true; # 显示所有文件扩展名
              NSGlobalDomain.AppleInterfaceStyle = "Dark"; # 强制深色模式
            };

            # 启用 Nix 守护进程服务
            system.stateVersion = 4;
          })

          # --- 整合 Home Manager ---
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.eunoiacody = { pkgs, ... }: {
              home.username = "eunoiacody";
              home.homeDirectory = "/Users/eunoiacody";
              home.stateVersion = "23.11";

              # 你原来的软件包列表
              home.packages = with pkgs; [
                neovim
                yazi
                bat
                eza
                fd
                fzf
                ripgrep
                jq
                zoxide
                fastfetch
                lazygit
                gh
                yt-dlp
                ffmpeg
                mpv
                kitty
                neovide
                fish
                figlet
                python3
                tree-sitter
                clang
                nodejs
                cmake
                nerd-fonts.jetbrains-mono
              ];

              # 你原来的文件映射
              xdg.configFile = {
                "nvim".source = ./nvim;
                "yazi".source = ./yazi;
                "sketchybar".source = ./sketchybar;
                "fish".source = ./fish;
                "kitty".source = ./kitty;
                "mpv".source = ./mpv;
                "neovide".source = ./neovide;
                "aerospace".source = ./aerospace;
                "figlet".source = ./figlet;
              };

              programs.home-manager.enable = true;
            };
          }
        ];
      };
    };
}
