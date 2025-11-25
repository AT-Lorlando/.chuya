#!/bin/zsh

# Prevent multiple executions of this profile
if [ -n "$CHUYA_PROFILE_LOADED" ]; then
    return
fi
export CHUYA_PROFILE_LOADED=1

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

# plugins=(
#     git
#     sudo
#     docker
#     docker-compose
#     z
#     zsh-syntax-highlighting
#     zsh-autosuggestions
# )

# Enable zsh-autosuggestions if available
# if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
#     source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# elif [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
#     source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
# fi

# # Enable zsh-syntax-highlighting if available
# if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
#     source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# elif [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
#     source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# fi

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
alias nano='nano -l -i -m -E -T 4'
# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Key bindings for word movement
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Key bindings for word deletion
bindkey "^[[3;5~" kill-word # Ctrl+Delete - delete word forward
bindkey "^H" backward-kill-word # Ctrl+Backspace - delete word backward

# Custom prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %b%c%u'
zstyle ':vcs_info:git:*' actionformats ' %b|%a%c%u'
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr ' +'
zstyle ':vcs_info:git:*' unstagedstr ' *'
zstyle ':vcs_info:*' enable git

# Python virtual environment info
python_info() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo " $(basename "$VIRTUAL_ENV")"
    fi
}

# Color definitions
local user_color='%F{81}' # Light blue (#4FC3F7)
local path_color='%F{white}' # White (#E6E6E6)
local git_color='%F{81}' # Light blue (#4FC3F7)
local python_color='%F{215}' # Orange (#FFB74D)
local prompt_color='%F{76}' # Green (#4CAF50)
local error_color='%F{196}' # Red (#F44336)
local reset_color='%f'

PROMPT='${user_color}%n${reset_color}@%m${path_color} %~${reset_color}${git_color}${vcs_info_msg_0_}${reset_color}${python_color}$(python_info)${reset_color}
%(?.${prompt_color}.${error_color})>${reset_color} '
setopt prompt_subst

# Source addons aliases if available
if [ -f "$HOME/.chuya/zsh/addons.sh" ]; then
    source "$HOME/.chuya/zsh/addons.sh"
fi