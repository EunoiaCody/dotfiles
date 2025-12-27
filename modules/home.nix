{ pkgs, ... }: {
  home.username = "eunoiacody";
  # 自动适配：如果是 Darwin 用 /Users，如果是 Linux 用 /home
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/eunoiacody" else "/home/eunoiacody";
  home.stateVersion = "23.11";

  # 设置全局风格
  catppuccin = {
    enable = false;
    flavor = "mocha"; # 可选: latte, frappe, macchiato, mocha
    accent = "lavender";

    lazygit = {
      enable = true;
    };
  };

  # 无论在哪台电脑都想要安装的包
  home.packages = with pkgs; [
    lolcat
    btop
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
    figlet
    python3
    tree-sitter
    clang
    nodejs
    cmake
    nerd-fonts.jetbrains-mono
    github-copilot-cli
  ];

  programs.lazygit = {
    enable = true;
  };

  # 配置文件映射
  # 注意：这里使用了相对路径 ../，指向你放在 dotfiles 根目录的配置夹
  xdg.configFile = {
    "nvim".source = ../nvim;
    "yazi".source = ../yazi;
    "sketchybar".source = ../sketchybar;
    "kitty".source = ../kitty;
    "mpv".source = ../mpv;
    "neovide".source = ../neovide;
    "aerospace".source = ../aerospace;
    "figlet".source = ../figlet;
    
    "fish/completions/docker.fish".source = ../fish/completions/docker.fish;
    "fish/completions/kubectl.fish".source = ../fish/completions/kubectl.fish;
    "fish/completions/orbctl.fish".source = ../fish/completions/orbctl.fish;
  };

  programs.fish = {
    enable = true;
    
    interactiveShellInit = ''
      set -gx EDITOR nvim
      set PATH $PATH /Users/eunoiacody/.local/bin
      
      # Git prompt settings
      set -g __fish_git_prompt_show_informative_status 1
      set -g __fish_git_prompt_showupstream "informative"
    '';

    shellAbbrs = {
      # fish abbr
      fish-reload = "source ~/.config/fish/**/*.fish";
      
      # General
      nvi = "neovide";
      yz = "yazi";
      
      # dnf
      dnfu = "sudo dnf update; sudo dnf upgrade; sudo dnf autoremove";
      dnfi = "sudo dnf install";
      dnfr = "sudo dnf remove";
      dnfs = "dnf search";
      dnfl = "dnf list --installed";
      dnfc = "sudo dnf clean all";
      
      # pacman
      pacu = "sudo pacman -Syu";
      paci = "sudo pacman -S";
      pacr = "sudo pacman -R";
      pacs = "pacman -Ss";
      
      # git
      gits = "git status";
      gitc = "git commit -m";
      gitp = "git push";
      gitpl = "git pull";
      
      # homebrew
      brewi = "brew install";
      brewr = "brew uninstall";
      brewu = "brew upgrade";
      brews = "brew search";
      
      # pkg(termux)
      pkgi = "pkg install";
      pkgr = "pkg uninstall";
      pkgs = "pkg search";
      pkgu = "pkg upgrade";
      
      # apk(alpine)
      apki = "sudo apk add";
      apkr = "sudo apk del";
      apku = "sudo apk update && sudo apk upgrade";
      apks = "apk search";
    };

    functions = {
      auto-play-in-mpv = ''
        set url (pbpaste)
        mpv --ytdl-raw-options=cookies-from-browser=chrome \
            --ytdl-format="bestvideo[height<=2160]+bestaudio/best" \
            $url
      '';

      refresh_fish = ''
        set -l fish_config "$HOME/.config/fish/config.fish"
        
        if not test -f "$fish_config"
            echo (set_color red)"[Error] 找不到配置文件: $fish_config"(set_color normal)
            return 1
        end

        set -l os_name (uname)
        set -l sys_info ""

        if test "$os_name" = "Darwin"
            set sys_info (set_color yellow)"macOS (Darwin)"(set_color normal)
        else if test -f /etc/NIXOS
            set sys_info (set_color blue)"NixOS"(set_color normal)
        else
            set sys_info (set_color white)"Linux (General)"(set_color normal)
        end

        echo (set_color cyan)"🚀 正在为 $sys_info 环境重载配置..."(set_color normal)
        exec fish --login
      '';

      fish_prompt = builtins.readFile ../fish/functions/fish_prompt.fish;
    };
  };

  programs.git = {
    enable = true;
    userName = "EunoiaCody";
    userEmail = "eunoiacody@gmail.com";
  };
  programs.home-manager.enable = true;
}
