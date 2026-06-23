# Migration de Chuya vers chezmoi

**Date:** 2026-06-23
**Statut:** Validé (design), prêt pour plan d'implémentation

## Contexte

Le repo `~/.chuya` (GitHub `AT-Lorlando/.chuya`) centralise actuellement
des configurations partagées entre plusieurs machines. Aujourd'hui il gère
**uniquement le shell zsh** :

- `install.sh` (bash) clone le repo dans `~/.chuya`, symlink `~/.zshrc`, et
  propose un opt-in interactif des addons (`zsh/optional/*.zsh` →
  symlinks dans `zsh/enabled/`).
- Des configs `.config/` (hypr, kitty, waybar, rofi, ranger, lazygit…) sont
  **déjà committées** mais **jamais déployées** vers `~/.config/`.

**Objectif** : transformer le repo en gestionnaire de dotfiles complet,
multi-machines et multi-OS (Arch Linux desktop + serveurs Ubuntu), avec une
**sélection de ce qui s'installe par machine** et une **gestion sécurisée des
secrets** (config Claude Code, tokens).

## Décisions validées

| Sujet | Décision |
|---|---|
| Outil | **chezmoi** (remplace `install.sh` et le système `optional/enabled`) |
| Sélection par machine | **Rôle manuel** demandé une fois à l'init (`desktop`/`server`/`wsl`) |
| Secrets | chezmoi + **age** (chiffrement de fichiers, aucune dépendance externe) |
| Emplacement source | Standard chezmoi `~/.local/share/chezmoi` (le repo GitHub garde le nom `.chuya`) |
| Migration | Progressive en 4 phases pour ne rien casser |

## Architecture

chezmoi traite le repo comme un **répertoire source** et déploie les fichiers
vers `~/` selon des conventions de nommage :

- `dot_zshrc` → `~/.zshrc`
- `dot_config/kitty/kitty.conf` → `~/.config/kitty/kitty.conf`
- `encrypted_private_dot_claude.json.age` → `~/.claude.json` (déchiffré, perms 600)
- `*.tmpl` → fichier passé dans le moteur de templates Go avant déploiement

Le one-liner d'installation (remplace le `curl | bash` actuel) :

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply AT-Lorlando/.chuya
```

### Sélection par rôle

À la première `init`, chezmoi crée la config locale depuis
`.chezmoi.toml.tmpl` et demande **une seule fois** le rôle :

```toml
# .chezmoi.toml.tmpl
{{- $role := promptStringOnce . "role" "Machine role (desktop/server/wsl)" -}}
[data]
    role = {{ $role | quote }}

encryption = "age"
[age]
    identity  = "~/.config/chezmoi/key.txt"
    recipient = "age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

`promptStringOnce` ne redemande jamais si la valeur existe déjà dans la config
locale. La **sélection de quoi déployer** se fait dans `.chezmoiignore`
(templaté sur `.role`) :

```
# .chezmoiignore
README.md
docs/

{{- if ne .role "desktop" }}
.config/hypr
.config/waybar
.config/kitty
.config/rofi
.config/wal
{{- end }}

{{- if ne .role "desktop" }}
.config/zsh/optional/exegol.zsh
.config/zsh/optional/android.zsh
{{- end }}
```

→ Sur un serveur Ubuntu (`role = server`), hyprland/waybar/kitty/rofi et les
modules zsh desktop ne sont pas déployés.

### Gestion des secrets (age)

1. Une paire de clés **age** : la clé publique (recipient) est inscrite dans la
   config chezmoi ; la clé privée vit à `~/.config/chezmoi/key.txt` (perms 600).
2. Les fichiers sensibles sont ajoutés avec `chezmoi add --encrypt <fichier>`,
   stockés **chiffrés** dans le repo (`encrypted_*.age`). Git ne voit jamais le
   clair.
3. **Bootstrap sur une nouvelle machine** : la clé privée est committée dans le
   repo, elle-même chiffrée par **passphrase** (`key.txt.age`). Un script
   `run_once` la déchiffre au premier `apply` (l'utilisateur tape la passphrase
   une fois) :

   ```sh
   # .chezmoiscripts/run_once_before_decrypt-age-key.sh.tmpl
   #!/bin/sh
   if [ ! -f "${HOME}/.config/chezmoi/key.txt" ]; then
       mkdir -p "${HOME}/.config/chezmoi"
       chezmoi age decrypt --output "${HOME}/.config/chezmoi/key.txt" \
           --passphrase "{{ .chezmoi.sourceDir }}/key.txt.age"
       chmod 600 "${HOME}/.config/chezmoi/key.txt"
   fi
   ```

   → une **seule passphrase** à retenir pour débloquer tous les secrets.

## Layout cible du repo

```
~/.local/share/chezmoi/   (ex-~/.chuya, même repo GitHub AT-Lorlando/.chuya)
├── .chezmoi.toml.tmpl                     # prompt rôle + config age
├── .chezmoiignore                         # sélection par rôle (templaté)
├── .chezmoiscripts/
│   └── run_once_before_decrypt-age-key.sh.tmpl
├── dot_zshrc.tmpl                         # → ~/.zshrc
├── dot_config/
│   ├── zsh/
│   │   ├── configs/   (00-history.zsh … 50-addons.zsh)   # partagés
│   │   └── optional/  (android, exegol, jabba, java, pm2) # gatés par rôle
│   ├── hypr/      kitty/      waybar/     rofi/
│   ├── ranger/    btop/       atuin/      lazygit/  lazydocker/
│   └── wal/
├── encrypted_private_dot_claude.json.age  # secret chiffré (exemple)
├── key.txt.age                            # clé privée age (passphrase)
├── README.md                              # doc d'install mise à jour
└── docs/superpowers/specs/                # ce spec
```

### Devenir du zsh

Le `zsh/zshrc` actuel source ses modules depuis `~/.chuya/zsh/`. Après
migration ils vivent dans `~/.config/zsh/` (déployés par chezmoi). Le
`dot_zshrc.tmpl` source `~/.config/zsh/configs/*.zsh` puis
`~/.config/zsh/optional/*.zsh` (présence contrôlée par `.chezmoiignore`).
Le mécanisme `~/.zshrc.local` (surcharges locales non versionnées) est
conservé tel quel.

### Devenir de l'ancien système

- `install/install.sh` : **supprimé**, remplacé par le one-liner chezmoi.
- `zsh/optional/` + `zsh/enabled/` + `.gitignore` (`zsh/enabled/`) : l'opt-in
  interactif est remplacé par le gating par rôle dans `.chezmoiignore`.

## Plan de migration (phases)

1. **Phase 1 — Shell.** Bootstrap chezmoi, migrer `zsh/` vers
   `dot_config/zsh/` + `dot_zshrc.tmpl`. Vérifier que le shell se comporte à
   l'identique avant d'aller plus loin. Supprimer `install.sh`.
2. **Phase 2 — Dotfiles `.config`.** Migrer kitty, hypr, waybar, rofi, ranger,
   etc. vers `dot_config/` avec gating par rôle dans `.chezmoiignore`.
3. **Phase 3 — Secrets.** Générer la paire age, configurer `encryption`,
   chiffrer les secrets (config Claude…), ajouter le script de bootstrap de clé.
4. **Phase 4 — (optionnel, hors périmètre initial) Install paquets.** Scripts
   `run_once_after_*` par rôle pour installer les dépendances
   (pacman sur Arch / apt sur Ubuntu : hyprland, kitty, eza, yazi, lazygit…).
   Documenté ici mais **non implémenté** dans le premier plan (YAGNI).

## Critères de succès

- `chezmoi init --apply AT-Lorlando/.chuya` sur une machine vierge :
  - demande le rôle une fois ;
  - déploie le shell + les configs adaptées au rôle ;
  - déchiffre les secrets après saisie de la passphrase.
- Sur un `role = server`, aucune config desktop (hyprland/kitty/…) n'est
  déployée.
- `chezmoi diff` est vide après un `apply` sur une machine déjà configurée.
- Aucun secret en clair n'apparaît dans l'historique git.

## Hors périmètre

- Auto-installation des paquets système (phase 4, plus tard).
- Migration vers un gestionnaire de secrets externe (Bitwarden/pass) — age suffit.
- Support d'OS non-Linux (macOS/Windows natif).
