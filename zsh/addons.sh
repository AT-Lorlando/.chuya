# Addons Aliases
alias lg='lazygit'
alias ld='lazydocker'
alias ya='yazi'

# Eza (modern ls replacement)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --color'
    alias ll='eza -alhF --icons --color'
    alias la='eza -A --icons --color'
    alias l='eza -CF --icons --color'
    alias tree='eza --tree --icons --color -L 3'
fi

export EDITOR="nano"

compdef _files eza

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"