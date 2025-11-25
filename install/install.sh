#!/bin/bash

# Script d'installation pour Oh My Zsh (Chuya)
# Usage : curl -sSL https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/install/install.sh | bash

set -e  # Quitte en cas d'erreur

# Ask user for installation method
echo "🎯 Chuya Setup"
echo "Choose your installation method:"
echo "1. Git Clone (Recommended - keeps themes up to date)"
echo "2. Manual Download (Standalone installation)"
echo ""

while true; do
    if [[ -t 0 ]]; then
        read -p "Enter your choice (1 or 2): " choice
    else
        read -p "Enter your choice (1 or 2): " choice < /dev/tty
    fi
    case $choice in
        1|2) break;;
        *) echo "Please enter 1 or 2";;
    esac
done

USE_GIT=$([[ $choice == "1" ]] && echo "true" || echo "false")

# Configuration
CHUYA_DIR="$HOME/.chuya"
PROFILE_DIR="$CHUYA_DIR/zsh"
PROFILE_SOURCE_PATH="$PROFILE_DIR/profile.sh"
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"
SHELL_NAME=$(basename "$SHELL")

# Detect current shell for final message
CURRENT_SHELL=$(basename "$SHELL")
if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    SHELL_CONFIG="$ZSHRC"
elif [[ "$CURRENT_SHELL" == "bash" ]]; then
    SHELL_CONFIG="$BASHRC"
else
    SHELL_CONFIG="$BASHRC"
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

echo "SHELL_NAME: $SHELL_NAME"

# Function to install addons
install_addons() {
    echo ""
    echo "📦 Addons Installation"
    echo "This will install optional tools: lazygit, lazydocker, yazi, and eza."
    
    while true; do
        if [[ -t 0 ]]; then
            read -p "Do you want to install these addons? (y/n): " install_choice
        else
            read -p "Do you want to install these addons? (y/n): " install_choice < /dev/tty
        fi
        case $install_choice in
            [Yy]* ) break;;
            [Nn]* ) return;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    # Create bin directory if it doesn't exist
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"

    # Install lazygit
    if ! command -v lazygit >/dev/null 2>&1; then
        echo "🔧 Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        install lazygit "$HOME/.local/bin"
        rm lazygit lazygit.tar.gz
        echo "✅ lazygit installed"
    else
        echo "ℹ️ lazygit already installed"
    fi

    # Install lazydocker
    if ! command -v lazydocker >/dev/null 2>&1; then
        echo "🔧 Installing lazydocker..."
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        echo "✅ lazydocker installed"
    else
        echo "ℹ️ lazydocker already installed"
    fi

    # Install eza
    if ! command -v eza >/dev/null 2>&1; then
        echo "🔧 Installing eza..."
        if command -v apt >/dev/null 2>&1; then
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt update
            sudo apt install -y eza
        else
             # Fallback to binary download if apt is not available (simplified)
             echo "⚠️ apt not found, skipping eza installation via apt. Please install manually."
        fi
    else
        echo "ℹ️ eza already installed"
    fi

    # Install yazi
    if ! command -v yazi >/dev/null 2>&1; then
        echo "🔧 Installing yazi..."
        # Yazi requires rust/cargo usually, but we can try to fetch a binary or use a script if available.
        # Using a pre-built binary approach for simplicity if available, otherwise cargo.
        if command -v cargo >/dev/null 2>&1; then
            cargo install --locked yazi-fm
            echo "✅ yazi installed via cargo"
        else
            echo "⚠️ cargo not found. Installing yazi requires Rust/Cargo. Skipping."
        fi
    else
        echo "ℹ️ yazi already installed"
    fi
}

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

    # Ask to install addons
    install_addons
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
    echo "⚙️ Configuring zsh profile..."
    SOURCE_LINE=". \"$PROFILE_SOURCE_PATH\""
    
    if [[ ! -f "$ZSHRC" ]]; then
        touch "$ZSHRC"
    fi
    
    if ! grep -Fq "$SOURCE_LINE" "$ZSHRC"; then
        echo "" >> "$ZSHRC"
        echo "# Chuya configuration" >> "$ZSHRC"
        echo "$SOURCE_LINE" >> "$ZSHRC"
        echo "✅ Source line added to $ZSHRC"
    else
        echo "ℹ️ Source line already present in $ZSHRC"
    fi
    
else
    echo "📥 Using manual download method..."
    
    # Create directories
    echo "📁 Creating directories..."
    mkdir -p "$PROFILE_DIR"
    
    # Download and create the profile.sh file
    echo "📄 Downloading profile.sh..."
    if curl -sSL "https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/zsh/profile.sh" -o "$PROFILE_SOURCE_PATH"; then
        echo "✅ Profile downloaded successfully"
    else
        echo "⚠️ Failed to download profile.sh"
    fi
    
    # Add source line to shell config
    echo "⚙️ Configuring zsh profile..."
    SOURCE_LINE=". \"$PROFILE_SOURCE_PATH\""
    
    if [[ ! -f "$ZSHRC" ]]; then
        touch "$ZSHRC"
    fi
    
    if ! grep -Fq "$SOURCE_LINE" "$ZSHRC"; then
        echo "" >> "$ZSHRC"
        echo "# Chuya configuration" >> "$ZSHRC"
        echo "$SOURCE_LINE" >> "$ZSHRC"
        echo "✅ Source line added to $ZSHRC"
    else
        echo "ℹ️ Source line already present in $ZSHRC"
    fi
fi

echo ""
echo "🎉 Installation complete!"
echo "🔄 Please restart your terminal or run 'source $SHELL_CONFIG' to apply changes."

if [[ "$USE_GIT" == "true" ]]; then
    echo "📝 Git method: Your configuration will stay updated with the repository."
else
    echo "📝 Manual method: To update configuration, re-run this script."
fi
