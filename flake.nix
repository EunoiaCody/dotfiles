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
    in
    {
      homeConfigurations."eunoiacody" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          {
            home.username = "eunoiacody";
            home.homeDirectory = "/Users/eunoiacody";
            home.stateVersion = "23.11";


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
              git
              cmake
            ];

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
          }
        ];
      };
    };
}
