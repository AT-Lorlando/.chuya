#!/bin/zsh

# Prevent multiple executions of this profile
if [ -n "$CHUYA_PROFILE_LOADED" ]; then
    return
fi
export CHUYA_PROFILE_LOADED=1

# Add oh-my-posh to PATH if it exists in common locations
if [ -f "$HOME/.local/bin/oh-my-posh" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Regular interactive mode
if [ -f "$HOME/.chuya/oh-my-posh/minimalist.omp.json" ] && [ -z "$_OMP_INITIALIZED" ]; then
    eval "$(oh-my-posh init zsh --config '~/.chuya/oh-my-posh/minimalist.omp.json')"
    export _OMP_INITIALIZED=1
fi

# Set up zsh autocompletion and history
autoload -Uz compinit
compinit

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)

# Enable zsh-autosuggestions if available
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Enable zsh-syntax-highlighting if available
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Function to quickly edit this config
function zshconfig() {
    nano ~/.zshrc
}

# Function to reload zsh config
function zshreload() {
    source ~/.zshrc
    echo "zsh configuration reloaded"
}

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
#alias nano='nano -liE -T 4 -'
# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'