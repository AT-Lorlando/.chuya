# Addons Aliases
alias lg='lazygit'
alias ya='yazi'
alias ld='lazydocker'

# Eza (modern ls replacement)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza -lhF --icons --color'
    alias ll='eza -alhF --icons --color'
    alias la='eza -A --icons --color'
    alias l='eza -CF --icons --color'
    alias tree='eza --tree --icons --color -L 3'
fi

compdef _files eza

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Atuin configuration
if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi

if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi
