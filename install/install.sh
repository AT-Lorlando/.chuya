#!/bin/bash

# Script d'installation simplifié pour Oh My Posh
# Usage : curl -sSL https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/install/install.sh | bash

set -e  # Quitte en cas d'erreur

# Configuration
THEME_URL="https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/oh-my-posh/chuya.omp.json"
THEME_DIR="$HOME/.chuya/oh-my-posh"
THEME_PATH="$THEME_DIR/chuya.omp.json"
BASHRC="$HOME/.bashrc"

echo "🔧 Installation d'Oh My Posh via le script officiel..."
curl -s https://ohmyposh.dev/install.sh | bash -s

echo "📁 Création du dossier de thème personnel..."
mkdir -p "$THEME_DIR"

echo "🌐 Téléchargement du thème personnalisé..."
curl -sSL "$THEME_URL" -o "$THEME_PATH" || {
  echo "⚠️ Échec du téléchargement du thème, utilisation du thème par défaut"
  oh-my-posh get shell bash
  cp "$(oh-my-posh get shell bash | grep -oP '"config":\s*"\K[^"]+')" "$THEME_PATH"
}

echo "⚙️ Configuration du .bashrc..."
if ! grep -q "oh-my-posh" "$BASHRC"; then
  cat <<EOF >> "$BASHRC"

# Configuration Oh My Posh par Chuya
eval "\$(~/.local/bin/oh-my-posh init bash --config '$THEME_PATH')"

# Astuce : Pour actualiser sans fermer le terminal
alias reload='source ~/.bashrc'
EOF
  echo "✅ Configuration ajoutée à $BASHRC"
else
  echo "ℹ️ La configuration Oh My Posh est déjà présente dans $BASHRC"
fi

echo "🎉 Installation terminée !"
