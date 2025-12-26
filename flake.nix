{
  description = "EunoiaCody's GitHub-based Dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."eunoiacody" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          {
            home.username = "eunoiacody";
            home.homeDirectory = "/Users/eunoiacody";
            home.stateVersion = "23.11";

            # 软件包：直接从你的 GitHub 列表迁移
            home.packages = with pkgs; [
              neovim yazi bat eza fd fzf ripgrep jq zoxide 
              fastfetch lazygit gh yt-dlp ffmpeg mpv kitty neovide fish 
              # 你可以随时在这里增加新的软件名
            ];

            # 映射目录：将本地克隆的仓库路径映射到 ~/.config
            # 这样你在 ~/dotfiles 里的修改能通过 switch 立即生效
            xdg.configFile = {
              "nvim".source = ./nvim;
              "yazi".source = ./yazi;
              "sketchybar".source = ./sketchybar;
              "fish".source = ./fish;
              "kitty".source = ./kitty;
              "mpv".source = ./mpv;
              "neovide".source = ./neovide;
              "aerospace".source = ./aerospace;
            };

            programs.home-manager.enable = true;
          }
        ];
      };
    };
}
