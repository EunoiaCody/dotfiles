if status is-interactive
    # Commands to run in interactive sessions can go here
    set -gx EDITOR nvim
end

# Created by `pipx` on 2025-12-24 08:30:05
set PATH $PATH /Users/eunoiacody/.local/bin

# Created by `pipx` on 2026-06-08 13:38:57
set PATH $PATH /home/eunoia/.local/bin

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
