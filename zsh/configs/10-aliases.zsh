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
alias nano='nano -i -E -T 4'
