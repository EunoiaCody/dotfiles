if status is-interactive
    # Commands to run in interactive sessions can go here
    if test -e /etc/static/fish/config.fish
        source /etc/static/fish/config.fish
    end
    set -gx EDITOR nvim
end

# Created by `pipx` on 2025-12-24 08:30:05
set PATH $PATH /Users/eunoiacody/.local/bin
