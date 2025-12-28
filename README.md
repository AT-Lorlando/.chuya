# Chuya Dotfiles

Configuration centralisée pour Zsh, compatible avec plusieurs machines.

## 🚀 Installation

### Méthode Recommandée (Git)
Cette méthode permet de garder vos configurations à jour facilement.

```bash
curl -sSL https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/install/install.sh | bash
```
Choisissez l'option **1** (Git Clone).

### Méthode Manuelle
Télécharge l'archive du dépôt sans utiliser git pour le versionning local.

```bash
curl -sSL https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/install/install.sh | bash
```
Choisissez l'option **2** (Manual Download).

## 📂 Structure

- **`zsh/configs/`** : Configurations partagées (chargées sur toutes les machines).
    - `00-history.zsh` : Configuration de l'historique.
    - `01-completion.zsh` : Autocomplétion.
    - `10-aliases.zsh` : Alias communs.
    - `20-git.zsh` : Alias Git.
    - `30-keybindings.zsh` : Raccourcis clavier.
    - `40-prompt.zsh` : Prompt personnalisé.
    - `50-addons.zsh` : Outils externes (lazygit, eza, etc.).
- **`zsh/hosts/`** : Configurations spécifiques à une machine.
- **`zsh/zshrc`** : Point d'entrée principal (remplace votre `~/.zshrc`).
- **`install/`** : Scripts d'installation.

## ⚠️ Note Importante
L'installation va **remplacer** votre fichier `~/.zshrc` actuel par un lien symbolique vers la configuration du dépôt.
Une sauvegarde de votre ancien fichier sera créée automatiquement (ex: `~/.zshrc.pre-chuya-2024...`).

## ⚙️ Personnalisation

### Configurations Partagées
Ajoutez un fichier `.zsh` dans `~/.chuya/zsh/configs/`. Il sera automatiquement chargé sur toutes vos machines.

### Configurations Spécifiques (Machine)
Créez un fichier avec le nom de votre machine (hostname) dans `~/.chuya/zsh/hosts/`.
Exemple : `~/.chuya/zsh/hosts/MonLaptop.zsh`.

Pour connaître votre hostname :
```bash
echo $HOST
# ou
hostname
```

### Surcharges Locales (Non versionnées)
Pour des configurations privées ou temporaires qui ne doivent pas être synchronisées, utilisez le fichier `~/.zshrc.local`.
Ce fichier est ignoré par git et est chargé en dernier, permettant de surcharger n'importe quelle configuration.

## 🛠️ Outils Inclus
- **lazygit** : Interface terminal pour git.
- **lazydocker** : Interface terminal pour docker.
- **eza** : Remplaçant moderne de `ls`.
- **yazi** : Gestionnaire de fichiers terminal.
