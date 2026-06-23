# Chuya Dotfiles

Configuration centralisée multi-machines, gérée avec [chezmoi](https://www.chezmoi.io/).
Sélection des configs **par rôle** (`desktop` / `server` / `wsl`) et secrets
chiffrés avec [age](https://age-encryption.org/).

## 🚀 Installation (nouvelle machine)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply AT-Lorlando/.chuya
```

chezmoi demande le **rôle** de la machine une seule fois, puis déploie les
configs adaptées. Si des secrets sont présents, saisis la **passphrase age**
pour débloquer la clé (voir _Secrets_).

Mise à jour ultérieure :

```bash
chezmoi update    # git pull + apply
```

## 📂 Structure (source chezmoi)

- `dot_zshrc.tmpl` → `~/.zshrc`
- `dot_config/zsh/{configs,optional}/` → modules zsh (optionnels gatés par rôle)
- `dot_config/<app>/` → configs applicatives (hypr, kitty, waybar, rofi, ranger,
  btop, atuin, lazygit, lazydocker, cava)
- `dot_bashrc`, `dot_gitconfig`, `dot_config/git/` → shell/git de base
- `dot_claude/` → config Claude Code (settings, CLAUDE.md, RTK.md)
- `encrypted_dot_claude.json.age` → `~/.claude.json` (chiffré age)
- `.chezmoi.toml.tmpl` → prompt du rôle + config chiffrement age
- `.chezmoiignore` → sélection des fichiers par rôle + exclusions (générés,
  backups, état runtime)

## ⚙️ Personnalisation

### Ajouter un fichier

```bash
chezmoi add ~/.config/<app>/<file>      # versionner un fichier existant
chezmoi add --encrypt ~/.un-secret      # versionner chiffré
chezmoi edit ~/.zshrc                    # éditer la source
chezmoi cd                               # aller dans le repo source
```

Après édition : `chezmoi apply` (déploie) ou `chezmoi diff` (prévisualise).

### Sélection par rôle

Le rôle est choisi à l'`init` et stocké dans `~/.config/chezmoi/chezmoi.toml`.
`.chezmoiignore` exclut les configs desktop (hypr, waybar, rofi, kitty, cava)
sur les rôles `server` / `wsl`.

### Surcharges locales (non versionnées)

`~/.zshrc.local` est chargé en dernier par `~/.zshrc` s'il existe — pour des
réglages propres à une machine, hors versionnement.

## 🔐 Secrets (age)

Les fichiers sensibles sont chiffrés avec age. La clé privée vit dans
`~/.config/chezmoi/key.txt` (jamais committée).

Pour amorcer une **nouvelle machine**, une copie de la clé chiffrée par
passphrase est committée (`key.txt.age`) ; le script
`.chezmoiscripts/run_once_before_decrypt-age-key.sh.tmpl` la déchiffre au
premier `apply` (saisie de la passphrase une fois).
