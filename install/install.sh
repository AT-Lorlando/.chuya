#!/bin/bash

# Chuya Dotfiles Installation Script
# Usage: curl -sSL https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/install/install.sh | bash

set -e

CHUYA_DIR="$HOME/.chuya"
ZSHRC="$HOME/.zshrc"

echo "🎯 Chuya Setup"

# 1. Install/Update Repository
if [ -d "$CHUYA_DIR" ]; then
    echo "📦 Updating repository..."
    cd "$CHUYA_DIR"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git pull origin main
    else
        echo "⚠️  $CHUYA_DIR exists but is not a git repo. Skipping update."
    fi
else
    echo "📦 Cloning repository..."
    if command -v git >/dev/null 2>&1; then
        git clone https://github.com/AT-Lorlando/.chuya.git "$CHUYA_DIR"
    else
        echo "📥 Downloading archive (Git not found)..."
        curl -L "https://github.com/AT-Lorlando/.chuya/archive/refs/heads/main.tar.gz" -o chuya.tar.gz
        tar -xzf chuya.tar.gz
        mv .chuya-main "$CHUYA_DIR"
        rm chuya.tar.gz
    fi
fi

# 2. Link .zshrc
echo "🔗 Linking .zshrc..."
if [ -f "$ZSHRC" ] && [ ! -L "$ZSHRC" ]; then
    BACKUP="$ZSHRC.pre-chuya-$(date +%Y%m%d-%H%M%S)"
    echo "📦 Backing up $ZSHRC to $BACKUP"
    mv "$ZSHRC" "$BACKUP"
fi
ln -sf "$CHUYA_DIR/zsh/zshrc" "$ZSHRC"
echo "✅ .zshrc linked"

# 3. Optional Addons
echo ""
echo "🧩 Optional Configurations"
OPTIONAL_DIR="$CHUYA_DIR/zsh/optional"
ENABLED_DIR="$CHUYA_DIR/zsh/enabled"
mkdir -p "$ENABLED_DIR"

if [ -d "$OPTIONAL_DIR" ]; then
    for addon in "$OPTIONAL_DIR"/*.zsh; do
        [ -e "$addon" ] || continue
        name=$(basename "$addon" .zsh)
        target="$ENABLED_DIR/$name.zsh"
        
        if [ -L "$target" ]; then
            status="[Enabled]"
        else
            status="[Disabled]"
        fi
        
        while true; do
            read -p "Enable $name? $status (y/n): " choice < /dev/tty
            case $choice in
                [Yy]* ) ln -sf "$addon" "$target"; echo "✅ Enabled $name"; break;;
                [Nn]* ) [ -L "$target" ] && rm "$target"; echo "❌ Disabled $name"; break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    done
fi

echo ""
echo "🎉 Installation complete! Restart your shell."
