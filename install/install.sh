#!/bin/bash

# Script d'installation pour Oh My Posh et Oh My Zsh (Chuya)
# Usage : curl -sSL https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/install/install.sh | bash

set -e  # Quitte en cas d'erreur

# Ask user for installation method
echo "🎯 Chuya Oh My Posh Setup"
echo "Choose your installation method:"
echo "1. Git Clone (Recommended - keeps themes up to date)"
echo "2. Manual Download (Standalone installation)"
echo ""

while true; do
    read -p "Enter your choice (1 or 2): " choice
    case $choice in
        1|2) break;;
        *) echo "Please enter 1 or 2";;
    esac
done

USE_GIT=$([[ $choice == "1" ]] && echo "true" || echo "false")

# Configuration
CHUYA_DIR="$HOME/.chuya"
THEME_DIR="$CHUYA_DIR/oh-my-posh"
PROFILE_DIR="$CHUYA_DIR/zsh"
PROFILE_SOURCE_PATH="$PROFILE_DIR/profile.sh"
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

# Detect current shell
CURRENT_SHELL=$(basename "$SHELL")
if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    SHELL_CONFIG="$ZSHRC"
    SHELL_NAME="zsh"
elif [[ "$CURRENT_SHELL" == "bash" ]]; then
    SHELL_CONFIG="$BASHRC"
    SHELL_NAME="bash"
else
    echo "⚠️ Unsupported shell: $CURRENT_SHELL. Defaulting to bash."
    SHELL_CONFIG="$BASHRC"
    SHELL_NAME="bash"
fi

# Install dependencies if not installed
if ! command -v git >/dev/null 2>&1; then
    echo "🔧 Git n'est pas installé. Installation en cours..."
    sudo apt update && sudo apt install -y git
fi

if [[ "$SHELL_NAME" == "zsh" ]] && ! command -v zsh >/dev/null 2>&1; then
    echo "🔧 Zsh n'est pas installé. Installation en cours..."
    sudo apt update && sudo apt install -y zsh
fi

# Install Oh My Posh if not already installed
if ! command -v oh-my-posh >/dev/null 2>&1; then
    echo "🔧 Installation d'Oh My Posh via le script officiel..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
    # Add Oh My Posh to PATH for current session
    export PATH="$PATH:$HOME/.local/bin"
fi

if [[ "$USE_GIT" == "true" ]]; then
    echo "📦 Using Git installation method..."
    
    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
        echo "❌ Git is not installed or not in PATH. Please install Git first or choose manual installation."
        exit 1
    fi
    
    # Clone the repository
    echo "📥 Cloning .chuya repository..."
    if [[ -d "$CHUYA_DIR" ]]; then
        echo "📁 Directory $CHUYA_DIR already exists, updating..."
        cd "$CHUYA_DIR"
        git pull origin main
    else
        git clone https://github.com/AT-Lorlando/.chuya.git "$CHUYA_DIR"
    fi
    
    # Add source line to shell config
    echo "⚙️ Configuring $SHELL_NAME profile..."
    SOURCE_LINE=". \"$PROFILE_SOURCE_PATH\""
    
    if [[ ! -f "$SHELL_CONFIG" ]]; then
        touch "$SHELL_CONFIG"
    fi
    
    if ! grep -Fq "$SOURCE_LINE" "$SHELL_CONFIG"; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Chuya Oh My Posh configuration" >> "$SHELL_CONFIG"
        echo "$SOURCE_LINE" >> "$SHELL_CONFIG"
        echo "✅ Source line added to $SHELL_CONFIG"
    else
        echo "ℹ️ Source line already present in $SHELL_CONFIG"
    fi
    
else
    echo "📥 Using manual download method..."
    
    # Create directories
    echo "📁 Creating directories..."
    mkdir -p "$THEME_DIR"
    mkdir -p "$PROFILE_DIR"
    
    # Download themes
    echo "🌐 Downloading themes..."
    themes=(
        "chuya.omp.json:https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/oh-my-posh/chuya.omp.json"
        "pure.omp.json:https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/oh-my-posh/pure.omp.json"
    )
    
    for theme_info in "${themes[@]}"; do
        IFS=':' read -r theme_name theme_url <<< "$theme_info"
        theme_path="$THEME_DIR/$theme_name"
        echo "  📄 Downloading $theme_name..."
        if curl -sSL "$theme_url" -o "$theme_path"; then
            echo "    ✅ Downloaded successfully"
        else
            echo "    ⚠️ Failed to download $theme_name"
        fi
    done
    
    # Download and create the profile.sh file
    echo "📄 Downloading profile.sh..."
    if curl -sSL "https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/shell/profile.sh" -o "$PROFILE_SOURCE_PATH"; then
        echo "✅ Profile downloaded successfully"
    else
        echo "⚠️ Failed to download profile.sh, creating basic configuration..."
    fi
    
    # Add source line to shell config
    echo "⚙️ Configuring $SHELL_NAME profile..."
    SOURCE_LINE=". \"$PROFILE_SOURCE_PATH\""
    
    if [[ ! -f "$SHELL_CONFIG" ]]; then
        touch "$SHELL_CONFIG"
    fi
    
    if ! grep -Fq "$SOURCE_LINE" "$SHELL_CONFIG"; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Chuya Oh My Posh configuration" >> "$SHELL_CONFIG"
        echo "$SOURCE_LINE" >> "$SHELL_CONFIG"
        echo "✅ Source line added to $SHELL_CONFIG"
    else
        echo "ℹ️ Source line already present in $SHELL_CONFIG"
    fi
fi

# Install shell-specific plugins if using zsh
if [[ "$SHELL_NAME" == "zsh" ]]; then
    echo "🔧 Setting up Zsh plugins..."
    
    # Install Oh My Zsh if not installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "🔧 Installation d'Oh My Zsh..."
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    
    # Install plugins
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    
    # Update plugins in .zshrc if not using git method (git method uses our profile)
    if [[ "$USE_GIT" == "false" ]]; then
        if grep -q '^plugins=' "$ZSHRC"; then
            sed -i.bak 's/^plugins=.*/plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
        else
            echo 'plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)' >> "$ZSHRC"
        fi
    fi
fi

echo ""
echo "🎉 Installation complete!"
echo "🔄 Please restart your terminal or run 'source $SHELL_CONFIG' to apply changes."

if [[ "$USE_GIT" == "true" ]]; then
    echo "📝 Git method: Your themes will stay updated with the repository."
else
    echo "📝 Manual method: To update themes, re-run this script."
fi
