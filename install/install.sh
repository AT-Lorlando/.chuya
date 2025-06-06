#!/bin/bash

# Script d'installation simplifié pour Oh My Posh et Oh My Zsh
# Usage : curl -sSL https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/install/install.sh | bash

set -e  # Quitte en cas d'erreur

# Configuration
THEME_URL="https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/oh-my-posh/chuya.omp.json"
THEME_DIR="$HOME/.chuya/oh-my-posh"
THEME_PATH="$THEME_DIR/chuya.omp.json"
ZSHRC="$HOME/.zshrc"

# 0. Installer Zsh si nécessaire
if ! command -v zsh >/dev/null 2>&1; then
  echo "🔧 Zsh n'est pas installé. Installation en cours..."
  sudo apt update && sudo apt install -y zsh
else
  echo "ℹ️ Zsh est déjà installé."
fi

# 1. Install git if not installed
if ! command -v git >/dev/null 2>&1; then
  echo "🔧 Git n'est pas installé. Installation en cours..."
  sudo apt install -y git
fi

# 1. Installer Oh My Zsh
echo "🔧 Installation d'Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 2. Installer les plugins Zsh
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# 3. Installer Oh My Posh (script officiel)
echo "🔧 Installation d'Oh My Posh via le script officiel..."
curl -s https://ohmyposh.dev/install.sh | bash -s

# 4. Créer le dossier du thème
mkdir -p "$THEME_DIR"

# 5. Télécharger le thème personnalisé
curl -sSL "$THEME_URL" -o "$THEME_PATH" || {
  echo "⚠️ Échec du téléchargement du thème, utilisation du thème par défaut"
  oh-my-posh get shell zsh
  cp "$(oh-my-posh get shell zsh | grep -oP '"config":\s*"\K[^"]+')" "$THEME_PATH"
}

# 6. Modifier ~/.zshrc
if [ -f "$ZSHRC" ]; then
  # Remplacer la ligne plugins=...
  if grep -q '^plugins=' "$ZSHRC"; then
    sed -i.bak 's/^plugins=.*/plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
  else
    echo 'plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)' >> "$ZSHRC"
  fi
else
  echo 'plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)' > "$ZSHRC"
fi

# Ajouter la config Oh My Posh et le source du plugin syntax-highlighting si pas déjà présent
if ! grep -q 'oh-my-posh init zsh' "$ZSHRC"; then
  echo "eval \"\$(/home/chuya/.local/bin/oh-my-posh init zsh --config '/home/chuya/.chuya/oh-my-posh/chuya.omp.json')\"" >> "$ZSHRC"
fi
if ! grep -q 'zsh-syntax-highlighting.zsh' "$ZSHRC"; then
  echo "source \$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$ZSHRC"
fi

echo "🎉 Installation terminée !"
