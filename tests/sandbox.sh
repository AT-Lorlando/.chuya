#!/usr/bin/env bash
# Rend le repo courant dans /tmp/cz-sandbox pour un rôle donné, sans toucher $HOME.
# Usage: tests/sandbox.sh <desktop|server|wsl>
set -euo pipefail
ROLE="${1:-desktop}"
SRC="$(git rev-parse --show-toplevel)"
DEST="/tmp/cz-sandbox/home"
CONF="/tmp/cz-sandbox/config.toml"
rm -rf /tmp/cz-sandbox
mkdir -p "$DEST"
cat > "$CONF" <<EOF
sourceDir = "$SRC"
destDir   = "$DEST"
[data]
    role = "$ROLE"
EOF
echo "== Fichiers gérés (role=$ROLE) =="
chezmoi managed --config "$CONF" --source "$SRC" --destination "$DEST"
echo "== Apply (dry-run) =="
chezmoi apply --config "$CONF" --source "$SRC" --destination "$DEST" --dry-run --verbose
