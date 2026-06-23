# Chezmoi Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convertir le repo `.chuya` en source chezmoi multi-machines (rôle manuel) avec secrets chiffrés age, sans casser le shell de la machine courante.

**Architecture:** On restructure le repo en place (dossier de travail `/home/chuya/Project/Chuya`) au format source chezmoi (conventions `dot_`, `*.tmpl`, `encrypted_`). Tout est validé en **sandbox** (`chezmoi apply` vers `/tmp`, jamais `$HOME`) avant la bascule réelle de la machine courante en dernière tâche. Le repo GitHub `AT-Lorlando/.chuya` reste la source ; `chezmoi init` le clone dans `~/.local/share/chezmoi`.

**Tech Stack:** chezmoi, age (chiffrement), zsh + oh-my-zsh, Go templates (moteur chezmoi).

## Global Constraints

- Source chezmoi = racine du repo (pour que `chezmoi init AT-Lorlando/.chuya` fonctionne sans `.chezmoiroot`).
- Rôles autorisés : `desktop`, `server`, `wsl`. Rôle demandé une seule fois via `promptStringOnce`.
- Aucun secret en clair ne doit entrer dans l'historique git. Secrets = fichiers `encrypted_*.age` uniquement.
- Chemin de la clé privée age : `~/.config/chezmoi/key.txt` (perms 600).
- Machine courante : hostname `Inspiron`, rôle cible `desktop`.
- Les modules zsh actuels migrent vers `~/.config/zsh/` ; `~/.zshrc.local` (surcharges locales non versionnées) reste supporté.
- Sandbox de test = `/tmp/cz-sandbox` (destination) + `/tmp/cz-sandbox/config.toml` (config). On ne teste JAMAIS contre `$HOME` avant la Task 8.
- Toutes les commandes `git mv` préservent l'historique ; commits fréquents.

---

## File Structure

| Fichier (après migration) | Responsabilité |
|---|---|
| `.chezmoi.toml.tmpl` | Génère la config locale ; prompt du rôle ; config chiffrement age |
| `.chezmoiignore` | Sélection des fichiers déployés selon `.role` (templaté) |
| `.chezmoiscripts/run_once_before_decrypt-age-key.sh.tmpl` | Bootstrap de la clé privée age (passphrase) |
| `dot_zshrc.tmpl` | `~/.zshrc` : source les modules depuis `~/.config/zsh/` |
| `dot_config/zsh/configs/*.zsh` | Modules zsh partagés (ex-`zsh/configs/`) |
| `dot_config/zsh/optional/*.zsh` | Modules zsh optionnels, gatés par rôle (ex-`zsh/optional/`) |
| `dot_config/<app>/...` | Configs applicatives (hypr, kitty, waybar, rofi, ranger, btop, atuin, lazygit, lazydocker, wal) |
| `encrypted_private_dot_claude.json.age` | Secret chiffré (`~/.claude.json`) |
| `key.txt.age` | Clé privée age chiffrée par passphrase |
| `README.md` | Doc d'install mise à jour (one-liner chezmoi) |

**Supprimés :** `install/install.sh`, `zsh/` (déplacé), entrée `zsh/enabled/` du `.gitignore`.

---

### Task 0: Outils + harnais de sandbox

**Files:**
- Create: `tests/sandbox.sh` (helper de validation, hors déploiement chezmoi via `.chezmoiignore`)

**Interfaces:**
- Produces: script `tests/sandbox.sh` qui rend le repo courant dans `/tmp/cz-sandbox` pour un rôle donné, sans toucher `$HOME`. Usage : `tests/sandbox.sh <role>`.

- [ ] **Step 1: Installer chezmoi et age**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
# age via le gestionnaire de paquets (Arch) :
sudo pacman -S --needed age
```

- [ ] **Step 2: Vérifier les binaires**

Run:
```bash
chezmoi --version && age --version
```
Expected: une version chezmoi (`chezmoi version v2...`) et une version age s'affichent, sans "command not found".

- [ ] **Step 3: Écrire le helper de sandbox**

Create `tests/sandbox.sh` :
```bash
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
```
> Note : le helper omet volontairement la config de chiffrement (la sandbox ne teste pas les secrets ; cf. Task 6). Pour les rôles, il force `.role` directement.

- [ ] **Step 4: Rendre exécutable et commiter**

```bash
chmod +x tests/sandbox.sh
git add tests/sandbox.sh
git commit -m "chore: add chezmoi sandbox validation helper"
```

---

### Task 1: Scaffolding chezmoi (config template + ignore + rôle)

**Files:**
- Create: `.chezmoi.toml.tmpl`
- Create: `.chezmoiignore`

**Interfaces:**
- Produces: variable de template `.role` (string ∈ {desktop,server,wsl}) disponible pour tous les autres fichiers ; `.chezmoiignore` exclut `tests/`, `docs/`, `README.md`, `install/`.

- [ ] **Step 1: Écrire `.chezmoi.toml.tmpl`**

```toml
{{- $role := promptStringOnce . "role" "Machine role (desktop/server/wsl)" -}}

[data]
    role = {{ $role | quote }}
```
> Le bloc `encryption`/`[age]` sera ajouté en Task 5 (après génération de la clé). On garde la config minimale ici pour valider le prompt d'abord.

- [ ] **Step 2: Écrire `.chezmoiignore` (squelette)**

```
README.md
docs/
tests/
install/
```

- [ ] **Step 3: Vérifier le rendu du template de config**

Run:
```bash
echo "desktop" | chezmoi execute-template --init --promptString role=desktop < .chezmoi.toml.tmpl
```
Expected: sortie TOML contenant `role = "desktop"`, sans erreur de template.

- [ ] **Step 4: Commit**

```bash
git add .chezmoi.toml.tmpl .chezmoiignore
git commit -m "feat: add chezmoi config template with role prompt"
```

---

### Task 2: Migrer le zsh vers dot_config/zsh + dot_zshrc.tmpl

**Files:**
- Move: `zsh/configs/*.zsh` → `dot_config/zsh/configs/`
- Move: `zsh/optional/*.zsh` → `dot_config/zsh/optional/`
- Create: `dot_zshrc.tmpl`
- Delete: `zsh/zshrc`

**Interfaces:**
- Consumes: `.role` (Task 1).
- Produces: `~/.zshrc` source `~/.config/zsh/configs/*.zsh` puis `~/.config/zsh/optional/*.zsh` (présence gérée par `.chezmoiignore`), puis `~/.zshrc.local` si présent.

- [ ] **Step 1: Déplacer les modules zsh (préserve l'historique)**

```bash
mkdir -p dot_config/zsh
git mv zsh/configs dot_config/zsh/configs
git mv zsh/optional dot_config/zsh/optional
```

- [ ] **Step 2: Écrire `dot_zshrc.tmpl`**

Reprend le contenu de l'ancien `zsh/zshrc` en remplaçant `$HOME/.chuya/zsh/` par `$HOME/.config/zsh/`, et en supprimant le sourcing de `zsh/enabled/` (remplacé par le gating `.chezmoiignore`) :

```bash
#!/bin/zsh

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
    git
    sudo
    docker
    docker-compose
    z
    zsh-syntax-highlighting
    zsh-autosuggestions
)
source $ZSH/oh-my-zsh.sh

# Source all shared configurations
if [ -d "$HOME/.config/zsh/configs" ]; then
    for config in "$HOME/.config/zsh/configs/"*.zsh(N); do
        source "$config"
    done
fi

# Source optional configurations (presence controlled by chezmoi role)
if [ -d "$HOME/.config/zsh/optional" ]; then
    for config in "$HOME/.config/zsh/optional/"*.zsh(N); do
        source "$config"
    done
fi

# Source local overrides (not versioned)
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

export EDITOR="nano"
export CHUYA_PROFILE_LOADED=1
export PATH="$PATH:$HOME/.local/bin"
```

- [ ] **Step 3: Supprimer l'ancien zshrc et le dossier zsh résiduel**

```bash
git rm zsh/zshrc
rmdir zsh 2>/dev/null || true
```

- [ ] **Step 4: Valider en sandbox (role=desktop)**

Run:
```bash
tests/sandbox.sh desktop
ls -R /tmp/cz-sandbox/home/.config/zsh
grep -c "HOME/.config/zsh" /tmp/cz-sandbox/home/.zshrc
```
Expected: `~/.zshrc` rendu présent dans la sandbox, `.config/zsh/configs` et `.config/zsh/optional` peuplés, au moins 1 occurrence de `HOME/.config/zsh` dans le `.zshrc`. Aucune erreur de template.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: migrate zsh config to chezmoi dot_config/zsh + dot_zshrc.tmpl"
```

---

### Task 3: Migrer les configs .config vers dot_config

**Files:**
- Move: `.config/<app>/...` → `dot_config/<app>/...` (hypr, kitty, waybar, rofi, ranger, btop, atuin, lazygit, lazydocker, wal)

**Interfaces:**
- Produces: arborescence `dot_config/` couvrant toutes les apps actuellement dans `.config/`.

- [ ] **Step 1: Déplacer chaque dossier .config**

```bash
for app in hypr kitty waybar rofi ranger btop atuin lazygit lazydocker wal; do
  [ -d ".config/$app" ] && git mv ".config/$app" "dot_config/$app"
done
rmdir .config 2>/dev/null || true
```

- [ ] **Step 2: Valider en sandbox (role=desktop)**

Run:
```bash
tests/sandbox.sh desktop
ls /tmp/cz-sandbox/home/.config
```
Expected: les dossiers `hypr kitty waybar rofi ranger btop atuin lazygit lazydocker wal` apparaissent sous `/tmp/cz-sandbox/home/.config`. Aucune erreur.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: migrate .config dotfiles to chezmoi dot_config"
```

---

### Task 4: Gating par rôle dans .chezmoiignore

**Files:**
- Modify: `.chezmoiignore`

**Interfaces:**
- Consumes: `.role`.
- Produces: sur `role != desktop`, les configs desktop (hypr, waybar, kitty, rofi, wal) et les modules zsh desktop (exegol, android) ne sont pas déployés.

- [ ] **Step 1: Étendre `.chezmoiignore`**

```
README.md
docs/
tests/
install/

{{- if ne .role "desktop" }}
.config/hypr
.config/waybar
.config/kitty
.config/rofi
.config/wal
.config/zsh/optional/exegol.zsh
.config/zsh/optional/android.zsh
{{- end }}
```

- [ ] **Step 2: Valider que le rôle desktop déploie tout**

Run:
```bash
tests/sandbox.sh desktop | grep -E "config/(hypr|kitty|waybar)" | head
```
Expected: au moins une ligne référençant `.config/hypr`, `.config/kitty` ou `.config/waybar` (donc géré pour desktop).

- [ ] **Step 3: Valider que le rôle server les exclut**

Run:
```bash
tests/sandbox.sh server > /tmp/cz-server.txt
grep -E "config/(hypr|waybar|kitty|rofi)" /tmp/cz-server.txt && echo "FAIL: desktop config present on server" || echo "OK: desktop config excluded on server"
grep -E "config/zsh/configs" /tmp/cz-server.txt && echo "OK: shared zsh present" || echo "FAIL: shared zsh missing"
```
Expected: `OK: desktop config excluded on server` ET `OK: shared zsh present`.

- [ ] **Step 4: Commit**

```bash
git add .chezmoiignore
git commit -m "feat: gate desktop-only configs by role in .chezmoiignore"
```

---

### Task 5: Mise en place du chiffrement age

**Files:**
- Modify: `.chezmoi.toml.tmpl`
- Create: `key.txt.age`
- Create: `.chezmoiscripts/run_once_before_decrypt-age-key.sh.tmpl`

**Interfaces:**
- Produces: chiffrement age activé (`encryption = "age"`, recipient public dans la config) ; clé privée bootstrappée via passphrase au premier apply.

- [ ] **Step 1: Générer la paire de clés age**

```bash
mkdir -p ~/.config/chezmoi
age-keygen -o ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
# Récupérer le recipient public :
grep "public key:" ~/.config/chezmoi/key.txt
```
Expected: affiche `# public key: age1....` — noter cette valeur (le RECIPIENT) pour l'étape suivante.

- [ ] **Step 2: Ajouter la config de chiffrement à `.chezmoi.toml.tmpl`**

Ajouter sous le bloc `[data]` (remplacer `age1RECIPIENT...` par la valeur de l'étape 1) :
```toml
encryption = "age"

[age]
    identity  = "~/.config/chezmoi/key.txt"
    recipient = "age1RECIPIENT..."
```

- [ ] **Step 3: Chiffrer la clé privée par passphrase (bootstrap)**

```bash
age --passphrase --output key.txt.age ~/.config/chezmoi/key.txt
```
Expected: fichier `key.txt.age` créé (binaire chiffré). Saisir une passphrase forte ; c'est la SEULE à retenir.

- [ ] **Step 4: Écrire le script de bootstrap de clé**

Create `.chezmoiscripts/run_once_before_decrypt-age-key.sh.tmpl` :
```sh
#!/bin/sh
if [ ! -f "${HOME}/.config/chezmoi/key.txt" ]; then
    mkdir -p "${HOME}/.config/chezmoi"
    chezmoi age decrypt --output "${HOME}/.config/chezmoi/key.txt" \
        --passphrase "{{ .chezmoi.sourceDir }}/key.txt.age"
    chmod 600 "${HOME}/.config/chezmoi/key.txt"
fi
```

- [ ] **Step 5: Ignorer la clé en clair par sécurité**

Ajouter à `.chezmoiignore` (pour qu'aucune copie en clair de la clé ne soit jamais gérée — `key.txt.age` chiffré reste committé, lui) :
```
key.txt
```

- [ ] **Step 6: Vérifier que key.txt en clair n'est pas suivi**

Run:
```bash
git status --porcelain | grep -E "key.txt$" && echo "FAIL: clear key staged" || echo "OK: only key.txt.age tracked"
git check-ignore -v key.txt.age || true
```
Expected: `OK: only key.txt.age tracked`. Le fichier `key.txt.age` (chiffré) est bien présent et committable.

- [ ] **Step 7: Commit**

```bash
git add .chezmoi.toml.tmpl key.txt.age .chezmoiscripts/ .chezmoiignore
git commit -m "feat: add age encryption with passphrase-bootstrapped key"
```

---

### Task 6: Chiffrer le secret Claude

**Files:**
- Create: `encrypted_private_dot_claude.json.age` (via `chezmoi add --encrypt`)

**Interfaces:**
- Consumes: chiffrement age (Task 5).
- Produces: `~/.claude.json` géré et chiffré dans le repo.

> Cette tâche manipule chezmoi sur le `$HOME` réel pour `add`, mais n'applique RIEN (`add` lit le fichier source vers le repo, ne déploie pas). Le repo source pour `add` doit être le dossier de travail.

- [ ] **Step 1: Ajouter le fichier Claude chiffré au repo**

```bash
chezmoi add --encrypt --source "$(git rev-parse --show-toplevel)" ~/.claude.json
```
Expected: un fichier `encrypted_private_dot_claude.json.age` apparaît à la racine du repo.

- [ ] **Step 2: Vérifier l'absence de clair**

Run:
```bash
ls encrypted_private_dot_claude.json.age
file encrypted_private_dot_claude.json.age
git grep -I -l "sk-ant" -- encrypted_private_dot_claude.json.age && echo "FAIL: plaintext token" || echo "OK: no plaintext token"
```
Expected: le fichier existe, `file` ne montre pas de JSON lisible, `OK: no plaintext token`.

- [ ] **Step 3: Vérifier le déchiffrement round-trip**

Run:
```bash
chezmoi cat --source "$(git rev-parse --show-toplevel)" ~/.claude.json | head -c 50
```
Expected: début du JSON Claude en clair (ex: `{` …) — prouve que la clé déchiffre correctement.

- [ ] **Step 4: Commit**

```bash
git add encrypted_private_dot_claude.json.age
git commit -m "feat: add encrypted Claude config as managed secret"
```

---

### Task 7: Nettoyage de l'ancien système + README

**Files:**
- Delete: `install/install.sh` (et `install/` si vide)
- Modify: `.gitignore` (retirer `zsh/enabled/`)
- Modify: `README.md`
- Modify: `tools.md` (si référence l'ancien flux — vérifier)

**Interfaces:**
- Produces: repo cohérent, plus aucune référence à `install.sh`/`zsh/enabled`.

- [ ] **Step 1: Supprimer l'ancien installeur**

```bash
git rm install/install.sh
rmdir install 2>/dev/null || true
```

- [ ] **Step 2: Nettoyer `.gitignore`**

Remplacer le contenu de `.gitignore` par (l'entrée `zsh/enabled/` n'a plus de sens) :
```
key.txt
```

- [ ] **Step 3: Réécrire la section installation du README**

Remplacer les sections "Installation" et "Structure" du `README.md` par :
````markdown
## 🚀 Installation

Sur une nouvelle machine :

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply AT-Lorlando/.chuya
```

chezmoi demande le **rôle** de la machine (`desktop` / `server` / `wsl`) une
seule fois, puis déploie les configs adaptées. Au premier déploiement, saisis
la **passphrase age** pour débloquer les secrets.

Mettre à jour ensuite :

```bash
chezmoi update    # git pull + apply
```

## 📂 Structure (source chezmoi)

- `dot_zshrc.tmpl` → `~/.zshrc`
- `dot_config/zsh/{configs,optional}/` → modules zsh (optionnels gatés par rôle)
- `dot_config/<app>/` → configs applicatives (hypr, kitty, waybar…)
- `.chezmoiignore` → sélection des fichiers par rôle
- `.chezmoi.toml.tmpl` → prompt du rôle + config chiffrement age
- `encrypted_*.age` → secrets chiffrés (age)
````

- [ ] **Step 4: Vérifier qu'aucune référence morte ne subsiste**

Run:
```bash
git grep -n "\.chuya/zsh\|zsh/enabled\|install\.sh" -- ':!docs/' || echo "OK: no dead references"
```
Expected: `OK: no dead references` (ou seulement des occurrences dans `docs/` qui sont l'historique des specs).

- [ ] **Step 5: Commit et push**

```bash
git add -A
git commit -m "docs: replace install.sh workflow with chezmoi in README"
git push -u origin chezmoi-migration
```

---

### Task 8: Bascule réelle de la machine courante (Inspiron, desktop)

**Files:** aucun (opération système).

**Interfaces:**
- Consumes: repo poussé sur `origin/chezmoi-migration`.

> ⚠️ Dernière tâche : c'est ici qu'on touche au `$HOME` réel. À ne faire qu'après validation des tâches 1-7 en sandbox. Backups d'abord.

- [ ] **Step 1: Sauvegarder l'état actuel**

```bash
cp -a ~/.zshrc ~/.zshrc.pre-chezmoi 2>/dev/null || true
[ -L ~/.zshrc ] && echo "~/.zshrc is a symlink (old chuya install)" || echo "~/.zshrc is a real file"
cp -a ~/.claude.json ~/.claude.json.pre-chezmoi
```
Expected: backups créés ; on sait si `~/.zshrc` est l'ancien symlink.

- [ ] **Step 2: Retirer l'ancien symlink zshrc**

```bash
[ -L ~/.zshrc ] && rm ~/.zshrc || true
```
Expected: plus de symlink `~/.zshrc` qui pointerait vers `~/.chuya`.

- [ ] **Step 3: Init chezmoi depuis la branche en cours (dry-run d'abord)**

```bash
chezmoi init --apply --dry-run --verbose --branch chezmoi-migration AT-Lorlando/.chuya
```
Expected: chezmoi clone la source, demande le rôle (`desktop`), montre les changements prévus sur `~` SANS les appliquer. Vérifier qu'il prévoit `~/.zshrc`, `~/.config/...`, `~/.claude.json` et rien de destructeur inattendu.

- [ ] **Step 4: Appliquer pour de vrai**

```bash
chezmoi init --apply --branch chezmoi-migration AT-Lorlando/.chuya
```
Expected: saisie de la passphrase age (déchiffrement clé), déploiement effectif. `~/.zshrc` et `~/.config/*` en place.

- [ ] **Step 5: Vérifier le shell et les configs**

Run:
```bash
zsh -ic 'echo CHUYA_PROFILE_LOADED=$CHUYA_PROFILE_LOADED; which l 2>/dev/null; alias | head'
chezmoi diff
diff <(jq -S . ~/.claude.json) <(jq -S . ~/.claude.json.pre-chezmoi) && echo "OK: claude.json identical"
```
Expected: `CHUYA_PROFILE_LOADED=1`, alias chargés, `chezmoi diff` vide (état appliqué), et `~/.claude.json` identique à la sauvegarde.

- [ ] **Step 6: Retirer l'ancien clone ~/.chuya (après confirmation que tout marche)**

```bash
[ -d ~/.chuya ] && mv ~/.chuya ~/.chuya.obsolete-$(date +%Y%m%d) || true
```
Expected: l'ancien `~/.chuya` est archivé (pas supprimé d'emblée), au cas où.

- [ ] **Step 7: Merge de la branche**

```bash
git checkout main
git merge --no-ff chezmoi-migration -m "feat: migrate dotfiles to chezmoi"
git push origin main
```
Expected: `main` contient la migration ; CI/remote à jour.

---

## Self-Review

**Spec coverage :**
- Outil chezmoi → Task 0-1. ✓
- Sélection par rôle (`promptStringOnce`, `.chezmoiignore`) → Task 1, 4. ✓
- Secrets age (clé, recipient, bootstrap passphrase, fichiers `encrypted_*`) → Task 5, 6. ✓
- Emplacement standard `~/.local/share/chezmoi` via `chezmoi init AT-Lorlando/.chuya` → Task 8. ✓
- Migration progressive (shell → .config → secrets) → Tasks 2, 3, 5/6. ✓
- Suppression `install.sh`/`optional/enabled` → Task 7. ✓
- One-liner d'install mis à jour → Task 7. ✓
- Critères de succès (init demande rôle, server sans desktop config, `chezmoi diff` vide, pas de secret en clair) → Tasks 4, 6, 8. ✓
- Phase 4 (install paquets) = hors périmètre, non planifiée. ✓ (conforme au spec)

**Placeholder scan :** chaque step de code contient le contenu réel. Seuls placeholders attendus : `age1RECIPIENT...` (Task 5, valeur générée à l'exécution, explicitement à remplacer) et la passphrase (saisie utilisateur). Pas de "TODO/TBD".

**Type consistency :** rôle = string `{desktop,server,wsl}` partout ; variable `.role` cohérente entre `.chezmoi.toml.tmpl` (Task 1) et `.chezmoiignore` (Task 4) ; chemin clé `~/.config/chezmoi/key.txt` cohérent entre Task 5 et le script de bootstrap.
