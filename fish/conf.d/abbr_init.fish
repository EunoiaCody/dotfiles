# fish abbr
abbr --add fish-reload "source ~/.config/fish/**/*.fish"

# General abbr
abbr --add nvi neovide
abbr --add yz yazi

# dnf abbr
abbr --add dnfu "sudo dnf update; sudo dnf upgrade; sudo dnf autoremove "
abbr --add dnfi "sudo dnf install"
abbr --add dnfr "sudo dnf remove"
abbr --add dnfs "dnf search"
abbr --add dnfl "dnf list --installed"
abbr --add dnfc "sudo dnf clean all"

# pacman abbr
abbr --add pacu "sudo pacman -Syu"
abbr --add paci "sudo pacman -S"
abbr --add pacr "sudo pacman -R"
abbr --add pacs "pacman -Ss"

# git abbr
abbr --add gits "git status"
abbr --add gitc "git commit -m"
abbr --add gitp "git push"
abbr --add gitpl "git pull"

# homebrew abbr
abbr --add brewi "brew install"
abbr --add brewr "brew uninstall"
abbr --add brewu "brew update && brew upgrade"
abbr --add brews "brew search"

# pkg(termux) abbr
abbr --add pkgi "pkg install"
abbr --add pkgr "pkg uninstall"
abbr --add pkgs "pkg search"
abbr --add pkgu "pkg upgrade"
