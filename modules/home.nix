{ pkgs, ... }: {
  home.username = "eunoiacody";
  # 自动适配：如果是 Darwin 用 /Users，如果是 Linux 用 /home
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/eunoiacody" else "/home/eunoiacody";
  home.stateVersion = "23.11";

  programs.git = {
    enable = true;
    userName = "EunoiaCody";
    userEmail = "eunoiacody@gmail.com";
  };

  # 无论在哪台电脑都想要安装的包
  home.packages = with pkgs; [
    luarocks
    rustc
    unzip
    cargo
    neovim
    yazi
    bat
    fd
    fzf
    ripgrep
    jq
    zoxide
    fastfetch
    lazygit
    tree
    gh
    yt-dlp
    ffmpeg
    mpv
    fish
    figlet
    python3
    tree-sitter
    clang
    nodejs
    cmake
    nerd-fonts.jetbrains-mono
    github-copilot-cli
  ];

  # 配置文件映射
  # 注意：这里使用了相对路径 ../，指向你放在 dotfiles 根目录的配置夹
  xdg.configFile = {
    "nvim".source = ../nvim;
    "yazi".source = ../yazi;
    "sketchybar".source = ../sketchybar;
    "fish".source = ../fish;
    "kitty".source = ../kitty;
    "mpv".source = ../mpv;
    "neovide".source = ../neovide;
    "aerospace".source = ../aerospace;
    "figlet".source = ../figlet;
  };

  programs.home-manager.enable = true;
}
