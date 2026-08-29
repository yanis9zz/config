# Dotfiles

[![CI](https://github.com/yanis9zz/config/actions/workflows/ci.yml/badge.svg)](https://github.com/yanis9zz/config/actions/workflows/ci.yml)

Une configuration Linux/WSL rapide et reproductible pour Neovim, Zsh et tmux.

- installation sans `sudo` dans `~/.local` ;
- sauvegarde automatique des configurations existantes ;
- téléchargements épinglés et vérifiés par SHA‑256 ;
- Neovim modulaire avec LSP, complétion, formatage et recherche ;
- Oh My Zsh, Powerlevel10k, Atuin, Zoxide et NVM paresseux ;
- MesloLGS NF installée et appliquée automatiquement sous WSL ;
- Codex CLI dans une popup tmux ou la fenêtre Neovim actuelle.

## Installation

### Compatibilité

| Système | Architecture | Support |
| --- | --- | --- |
| Linux | `x86_64` / `aarch64` | Oui |
| WSL | `x86_64` / `aarch64` | Oui |
| macOS / Windows natif | — | Non |

Prérequis : Git, Zsh, `curl` ou `wget`, `tar`, `make`, Perl, `sha256sum` et Node.js 20+. Le script n’installe pas Node.js et ne change pas ton shell avec `chsh`.

```sh
git clone https://github.com/yanis9zz/config.git ~/config
cd ~/config
./setup.sh install
exec zsh
```

`./setup.sh` sans argument lance également l’installation.

Au premier démarrage de Neovim, `lazy.nvim` télécharge les plugins et Mason installe les serveurs LSP. Cette première ouverture peut donc prendre un peu plus de temps.

## Ce que le script installe

Les outils sont placés dans `~/.local` et les versions sont verrouillées dans [`setup.sh`](./setup.sh).

| Outil | Version | Utilité |
| --- | ---: | --- |
| GNU Stow | 2.4.1 | liens symboliques des dotfiles |
| Neovim | 0.12.5 | installé seulement si absent ou antérieur à 0.11 |
| Zoxide | 0.10.0 | navigation rapide entre dossiers |
| FZF | 0.74.3 | recherche floue |
| Atuin | 18.20.1 | historique du shell |
| Ripgrep | 15.2.0 | recherche de texte |
| fd | 10.5.0 | recherche de fichiers |
| tmux | 3.7c | sessions et panneaux persistants |

Oh My Zsh, Powerlevel10k et les polices MesloLGS NF sont épinglés à des commits précis. Aucun installateur distant n’est exécuté avec `curl | sh`.

## Commandes

| Commande | Effet |
| --- | --- |
| `./setup.sh install` | installe les outils et applique les dotfiles |
| `./setup.sh update` | remet les outils, dépôts épinglés et liens dans l’état attendu |
| `./setup.sh doctor` | effectue un diagnostic sans rien modifier |
| `./setup.sh reset` | retire uniquement les liens gérés par Stow |
| `./setup.sh restore` | restaure la dernière sauvegarde |
| `./setup.sh restore <date>` | restaure une sauvegarde précise |
| `./setup.sh --help` | affiche l’aide |

Pour mettre le dépôt à jour :

```sh
cd ~/config
git pull --ff-only
./setup.sh update
```

## Sauvegardes et sécurité

Avant de créer un lien, l’installateur simule le déploiement Stow. Les fichiers incompatibles sont déplacés vers :

```text
~/.config-backups/yanis-config/<date-heure>/
├── home/          # ancienne arborescence
└── manifest.tsv   # emplacement original de chaque élément
```

Les sauvegardes ne sont jamais supprimées automatiquement.

- si Stow échoue, les nouveaux liens sont retirés et la sauvegarde est restaurée ;
- `reset` enlève les liens mais ne restaure pas les anciens fichiers ;
- `restore` refuse d’écraser un nouveau fichier non géré ;
- les anciens binaires remplacés sont conservés dans `~/.local/state/yanis-config/replaced-binaries/` ;
- la restauration des dotfiles ne touche jamais aux réglages de Windows Terminal.

Disposition Stow :

```text
zsh/.zshrc                  → ~/.zshrc
tmux/.tmux.conf             → ~/.tmux.conf
nvim/.config/nvim/          → ~/.config/nvim/
```

Les fichiers actifs sont des liens vers le dépôt : modifier `~/config/zsh/.zshrc`, par exemple, modifie directement la configuration utilisée.

## Configuration locale Zsh

Les alias privés, IP, secrets et runtimes propres à une machine ne doivent pas être commités. Place-les dans `~/.zshrc.local` :

```sh
cp ~/config/examples/.zshrc.local.example ~/.zshrc.local
```

Ce fichier est chargé avant le wrapper Neovim. L’exemple contient un bloc optionnel pour charger NVM uniquement à la première utilisation de `node`, `npm`, `npx`, `corepack`, `codex` ou `nvim`. Neovim appelle ce hook afin que Mason voie toujours Node.js.

Pour maximiser automatiquement Windows Terminal quand Neovim démarre sous WSL :

```sh
echo 'export DOTFILES_MAXIMIZE_WINDOWS_TERMINAL=1' >> ~/.zshrc.local
exec zsh
```

## Police Powerlevel10k

Les variantes Regular, Bold, Italic et Bold Italic de MesloLGS NF sont vérifiées puis installées sans droits administrateur.

### Linux

Les fichiers sont placés dans `$XDG_DATA_HOME/fonts` ou `~/.local/share/fonts`. Le cache Fontconfig est rafraîchi si `fc-cache` est disponible. Il peut rester nécessaire de sélectionner manuellement **MesloLGS NF** dans l’émulateur de terminal.

### WSL et Windows Terminal

Les polices sont enregistrées pour l’utilisateur Windows et **MesloLGS NF** est appliquée au profil par défaut de Windows Terminal. L’éditeur préserve le JSONC original : commentaires, formatage et virgules finales restent intacts.

Une copie `settings.json.before-meslolgs.bak` est créée avant la première modification. Un avertissement apparaît lorsqu’un profil possède son propre `font.face`, car cette valeur prend priorité sur le profil par défaut. Redémarre Windows Terminal après la première installation.

## Neovim

`<leader>` correspond à la barre d’espace.

### Navigation et recherche

| Raccourci | Action |
| --- | --- |
| `<leader>e` | ouvrir ou fermer NvimTree |
| `<leader>ol` | créer le layout éditeur + terminal |
| `<leader>sf` | rechercher un fichier |
| `<leader>sg` | rechercher du texte dans le projet |
| `<leader>shf` / `<leader>shg` | inclure les fichiers cachés |
| `<leader><leader>` | sélectionner un buffer |
| `<C-h/j/k/l>` | changer de fenêtre |
| `<C-S-h/j/k/l>` | déplacer la fenêtre active |
| `<Esc><Esc>` | quitter le mode terminal |

Le layout `<leader>ol` verrouille la colonne du terminal : ouvrir puis fermer NvimTree ne déforme pas son affichage.

### Code, LSP et Git

| Raccourci | Action |
| --- | --- |
| `<leader>f` | formater le buffer ou la sélection |
| `grd` / `grD` | définition / déclaration |
| `grr` / `gri` / `grt` | références / implémentations / type |
| `grn` / `gra` | renommer / action de code |
| `<leader>m` | afficher le diagnostic courant |
| `<leader>hs` / `<leader>hr` | stage / reset du hunk Git |
| `]c` / `[c` | hunk suivant / précédent |
| `<leader>H` | ajouter le header 42 |

Mason installe automatiquement `clangd`, `pyright`, `ts_ls`, `lua_ls` et StyLua. Commandes utiles : `:Lazy`, `:Mason`, `:ConformInfo` et `:checkhealth`.

## Codex CLI

La configuration utilise exclusivement le [Codex CLI officiel](https://developers.openai.com/codex/cli/). Elle ne l’installe pas et ne lance jamais l’authentification automatiquement.

```sh
codex --version
./setup.sh doctor
```

| Raccourci | Comportement |
| --- | --- |
| `<leader>cc` | ouvre Codex à la racine du projet Git dans une popup tmux (ou un split hors tmux) |
| `<leader>cw` | remplace la fenêtre actuelle par Codex ; appuyer de nouveau restaure le buffer précédent |
| `<C-b>C` dans tmux | ouvre directement la popup Codex |

Chaque projet réutilise son terminal Codex. Dans tmux, `<leader>cc` affiche une popup persistante à 90 %. Hors tmux, il ouvre un split natif Neovim. `<leader>cw` reste toujours dans la fenêtre actuelle. Le curseur des terminaux intégrés ne clignote pas.

## tmux

Le préfixe est `<C-b>`. L’alias `t` ouvre ou rejoint la session `main`.

| Raccourci | Action |
| --- | --- |
| `<C-b>s` / `<C-b>v` | split horizontal / vertical |
| `<C-b>h/j/k/l` | changer de panneau |
| `<C-b>c` | nouvelle fenêtre dans le dossier courant |
| `<C-b>b` | afficher ou masquer la barre de statut |
| `<C-b>r` | recharger `.tmux.conf` |
| `<C-b>C` | popup Codex du projet |

La souris, le true color et un historique de 100 000 lignes sont activés.

## Diagnostic

Commence toujours par :

```sh
cd ~/config
./setup.sh doctor
```

Quelques commandes complémentaires :

```sh
nvim --headless '+checkhealth kickstart' +qa
tmux source-file ~/.tmux.conf
zsh -n ~/.zshrc
```

## Structure

```text
.
├── .github/workflows/ci.yml          # tests GitHub Actions
├── examples/.zshrc.local.example     # configuration locale non suivie
├── nvim/.config/nvim/
│   ├── init.lua
│   └── lua/
│       ├── config/                    # options, mappings, lazy.nvim, Codex
│       └── plugins/                   # LSP, Git, UI et extras
├── scripts/
│   ├── codex-popup
│   ├── install-meslolgs-fonts.ps1
│   └── windows-terminal-maximize.ps1
├── tests/                             # sauvegarde/restauration et JSONC
├── tmux/.tmux.conf
├── zsh/.p10k.zsh
├── zsh/.zshrc
└── setup.sh
```

## CI

Le workflow [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) est lancé par GitHub à chaque push et pull request. Il vérifie :

- Bash, Zsh et ShellCheck ;
- le chargement de la configuration tmux ;
- l’installation et la restauration dans un `$HOME` temporaire ;
- PowerShell et la préservation du JSONC Windows Terminal ;
- le formatage Lua et le démarrage headless de Neovim.

Tests locaux principaux :

```sh
./tests/test-installer.sh
powershell.exe -File "$(wslpath -w "$PWD/tests/test-jsonc.ps1")"
shellcheck setup.sh tests/test-installer.sh scripts/codex-popup
~/.local/share/nvim/mason/bin/stylua --check nvim/.config/nvim
```
