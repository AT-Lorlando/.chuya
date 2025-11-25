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
    alias tree='eza --tree --icons --color'
fi

export EDITOR="nano"