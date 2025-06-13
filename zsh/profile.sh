#!/bin/zsh

# Add oh-my-posh to PATH if it exists in common locations
if [ -f "$HOME/.local/bin/oh-my-posh" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

isAIAgent=false

# Detect if running as an AI agent (parent process is Cursor)
if command -v ps >/dev/null 2>&1; then
    parent_pid=$(ps -o ppid= -p $$)
    if [ -n "$parent_pid" ]; then
        parent_name=$(ps -o comm= -p "$parent_pid" 2>/dev/null)
        if [[ "$parent_name" == *"cursor"* ]] || [[ "$parent_name" == *"Cursor"* ]]; then
            isAIAgent=true
        fi
    fi
fi

if [ "$isAIAgent" = true ]; then
    # AI Agent mode - simplified setup
    # Disable colors for plain text output
    export TERM=xterm
    
    # Find oh-my-posh command
    local omp_cmd=""
    if command -v oh-my-posh >/dev/null 2>&1; then
        omp_cmd="oh-my-posh"
    elif [ -f "$HOME/.local/bin/oh-my-posh" ]; then
        omp_cmd="$HOME/.local/bin/oh-my-posh"
    fi
    
    if [ -n "$omp_cmd" ] && [ -f "$HOME/.chuya/oh-my-posh/pure.omp.json" ]; then
        eval "$($omp_cmd init zsh --config '$HOME/.chuya/oh-my-posh/pure.omp.json')"
    else
        # Fallback simple prompt
        PROMPT='%1~ %# '
    fi
else
    # Regular interactive mode
    # Find oh-my-posh command
    local omp_cmd=""
    if command -v oh-my-posh >/dev/null 2>&1; then
        omp_cmd="oh-my-posh"
    elif [ -f "$HOME/.local/bin/oh-my-posh" ]; then
        omp_cmd="$HOME/.local/bin/oh-my-posh"
    fi
    
    if [ -n "$omp_cmd" ] && [ -f "$HOME/.chuya/oh-my-posh/chuya.omp.json" ]; then
        eval "$($omp_cmd init zsh --config '$HOME/.chuya/oh-my-posh/chuya.omp.json')"
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

    # Function to switch oh-my-posh profiles
    function p() {
        local prf="$1"
        local config_path="$HOME/.chuya/oh-my-posh/${prf}.omp.json"
        
        # Find oh-my-posh command
        local omp_cmd=""
        if command -v oh-my-posh >/dev/null 2>&1; then
            omp_cmd="oh-my-posh"
        elif [ -f "$HOME/.local/bin/oh-my-posh" ]; then
            omp_cmd="$HOME/.local/bin/oh-my-posh"
        else
            echo "❌ oh-my-posh not found. Please install it first."
            return 1
        fi
        
        if [ -z "$prf" ]; then
            echo "Available profiles:"
            for theme in "$HOME/.chuya/oh-my-posh"/*.omp.json; do
                if [ -f "$theme" ]; then
                    basename "$theme" .omp.json
                fi
            done
            return
        fi
        
        if [ -f "$config_path" ]; then
            eval "$($omp_cmd init zsh --config '$config_path')"
            echo "✅ Switched to theme: $prf"
        else
            echo "❌ Profile '$prf' not found at $config_path"
            echo "Available profiles:"
            for theme in "$HOME/.chuya/oh-my-posh"/*.omp.json; do
                if [ -f "$theme" ]; then
                    basename "$theme" .omp.json
                fi
            done
        fi
    }

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
    
    # Git aliases
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git log --oneline'
    alias gd='git diff'
fi