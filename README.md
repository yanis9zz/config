# Dotfiles

Configuration personnelle pour Neovim, Zsh et tmux, déployée avec GNU Stow.

## Contenu

- **Neovim** : LSP, autocomplétion, formatage, Treesitter, Telescope, GitSigns, NvimTree, intégrations Codex et LeetCode.
- **Zsh** : Oh My Zsh, Powerlevel10k, Atuin, Zoxide et quelques alias personnels.
- **tmux** : navigation Vim, souris, splits simples et conservation du dossier courant.
- **`setup.sh`** : installation des outils manquants et création des liens symboliques.

## Prérequis

Le script d'installation cible Linux sur `x86_64` ou `aarch64`. Il ne remplace pas l'installation de Neovim.

À installer au préalable :

- Neovim 0.11 ou plus récent ;
- Git et Zsh ;
- `curl` ou `wget` ;
- `tar`, `make` et Perl ;
- Node.js pour les serveurs LSP TypeScript installés par Mason.

Le script installe ensuite, si nécessaire, GNU Stow, Zoxide, FZF, Atuin, Ripgrep, fd, tmux, Oh My Zsh et Powerlevel10k. Les exécutables téléchargés sont placés dans `~/.local/bin`.

## Installation

> [!WARNING]
> Stow refuse normalement d'écraser un vrai fichier, mais sauvegarde tout de même tes configurations existantes (`~/.zshrc`, `~/.tmux.conf` et `~/.config/nvim`) avant la première installation.

```sh
git clone https://github.com/yanis9zz/config.git ~/config
cd ~/config
./setup.sh
```

Le script crée des liens vers le dépôt : modifier un fichier dans `~/config` modifie donc directement la configuration active.

Au premier lancement de Neovim :

```sh
nvim
```

`lazy.nvim` installe automatiquement les plugins. Mason installe ensuite `clangd`, `pyright`, `ts_ls`, `lua_ls` et StyLua. Les premiers téléchargements peuvent prendre quelques instants ; utilise `:Lazy` et `:Mason` pour suivre leur état.

## Mise à jour

```sh
cd ~/config
git pull
./setup.sh
```

Le mode `--restow` actualise les liens si des fichiers ont été ajoutés ou déplacés. Dans Neovim, lance `:Lazy update` pour mettre les plugins à jour ; le fichier `nvim/lazy-lock.json` conserve les versions résolues.

## Désinstallation des liens

Pour retirer uniquement les liens créés par Stow, sans supprimer le dépôt ni désinstaller les outils :

```sh
cd ~/config
./setup.sh reset
```

Les données des plugins restent dans `~/.local/share/nvim` et peuvent être réutilisées lors d'une prochaine installation.

## Utilisation de Neovim

La touche `<leader>` est la barre d'espace. Après l'avoir pressée, WhichKey affiche les raccourcis disponibles.

### Navigation et édition

| Raccourci | Action |
| --- | --- |
| `<C-h/j/k/l>` | Se déplacer entre les fenêtres |
| `<C-S-h/j/k/l>` | Déplacer la fenêtre courante |
| `<leader>e` | Ouvrir ou fermer NvimTree |
| `<leader><leader>` | Choisir un buffer |
| `<leader>ol` | Créer le layout avec terminal en haut à droite |
| `<leader>f` | Formater le buffer ou la sélection |
| `<leader>H` | Ajouter le header 42 |
| `<Esc><Esc>` | Quitter le mode terminal |

### Recherche avec Telescope

| Raccourci | Action |
| --- | --- |
| `<leader>sf` | Rechercher un fichier |
| `<leader>sg` | Rechercher du texte dans le projet |
| `<leader>sw` | Rechercher le mot sous le curseur |
| `<leader>shf` | Rechercher aussi les fichiers cachés |
| `<leader>shg` | Rechercher du texte dans les fichiers cachés |
| `<leader>/` | Rechercher dans le buffer courant |
| `<leader>s/` | Rechercher dans les buffers ouverts |
| `<leader>sd` | Rechercher dans les diagnostics |
| `<leader>sn` | Rechercher dans cette configuration Neovim |
| `<leader>st` | Rechercher les commentaires TODO |
| `<leader>sr` | Reprendre la dernière recherche |

### LSP et diagnostics

Les raccourcis LSP apparaissent lorsqu'un serveur est attaché au buffer.

| Raccourci | Action |
| --- | --- |
| `grd` / `grD` | Aller à la définition / déclaration |
| `grr` / `gri` | Chercher les références / implémentations |
| `grt` | Aller à la définition du type |
| `grn` | Renommer le symbole |
| `gra` | Afficher les actions de code |
| `gO` / `gW` | Symboles du document / workspace |
| `<leader>m` | Afficher le diagnostic courant |
| `<leader>q` | Envoyer les diagnostics dans la location list |
| `<leader>th` | Activer ou désactiver les inlay hints |
| `<leader>gpd` | Prévisualiser une définition |
| `<leader>gpc` | Fermer les fenêtres de prévisualisation |

### GitSigns

| Raccourci | Action |
| --- | --- |
| `]c` / `[c` | Modification Git suivante / précédente |
| `<leader>hs` / `<leader>hr` | Stage / reset du hunk |
| `<leader>hS` / `<leader>hR` | Stage / reset du buffer |
| `<leader>hp` / `<leader>hi` | Prévisualiser le hunk / diff inline |
| `<leader>hb` | Afficher le blame complet de la ligne |
| `<leader>hd` / `<leader>hD` | Diff avec l'index / le dernier commit |
| `<leader>hq` / `<leader>hQ` | Changements du fichier / dépôt dans Quickfix |
| `<leader>tb` / `<leader>tw` | Activer le blame / word diff |
| `ih` | Sélectionner un hunk en mode visuel ou opérateur |

### Codex et LeetCode

| Raccourci | Action |
| --- | --- |
| `<leader>cc` | Ouvrir Codex dans une popup |
| `<leader>cw` | Ouvrir Codex dans la fenêtre courante |
| `<leader>ll` | Afficher la liste LeetCode |
| `<leader>lr` / `<leader>ls` | Exécuter / soumettre la solution |
| `<leader>ld` | Ouvrir le problème du jour |
| `<leader>lm` | Ouvrir le menu LeetCode |

## Utilisation de tmux

Le préfixe reste celui de tmux : `<C-b>`.

| Raccourci | Action |
| --- | --- |
| `<C-b>s` | Créer un panneau côte à côte |
| `<C-b>v` | Créer un panneau au-dessus ou en dessous |
| `<C-b>h/j/k/l` | Naviguer entre les panneaux |
| `<C-b>c` | Créer une fenêtre dans le dossier courant |
| `<C-b>b` | Afficher ou masquer la barre de statut |
| `<C-b>r` | Recharger `~/.tmux.conf` |

L'alias `t` ouvre une session persistante avec `tmux new -As`.

## Maintenance et diagnostic

Commandes utiles dans Neovim :

```vim
:Lazy
:Lazy update
:Mason
:checkhealth
:ConformInfo
```

Pour vérifier le dépôt avant un commit :

```sh
bash -n setup.sh
~/.local/share/nvim/mason/bin/stylua --check nvim
nvim --headless '+checkhealth lazy vim.deprecated kickstart' +qa
```

La CI GitHub exécute automatiquement la vérification Bash et StyLua à chaque push et pull request.

## Structure

```text
.
├── nvim/                  # Configuration Neovim et lockfile des plugins
├── tmux/.tmux.conf        # Configuration tmux
├── zsh/.zshrc             # Configuration Zsh
├── zsh/.p10k.zsh          # Thème Powerlevel10k
├── setup.sh               # Installation, restow et reset
└── .github/workflows/     # Vérifications automatiques
```
