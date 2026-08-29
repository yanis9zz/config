# Dotfiles Linux / WSL

Configuration reproductible et performante pour Neovim, Zsh et tmux. L’installation se fait sans `sudo`, sauvegarde les fichiers existants et vérifie en SHA‑256 tous les binaires et toutes les polices téléchargés.

## Installation rapide

Le script cible Linux ou WSL sur `x86_64` et `aarch64`.

Prérequis à installer soi-même :

- Git, Zsh, `tar`, `sha256sum`, `make` et Perl ;
- `curl` ou `wget` ;
- Node.js 20 ou plus récent. Le script ne l’installe pas et ne change pas le shell avec `chsh`.

```sh
git clone https://github.com/yanis9zz/config.git ~/config
cd ~/config
./setup.sh install
exec zsh
```

`./setup.sh` sans argument équivaut à `./setup.sh install`.

Le script installe ou met à niveau dans `~/.local` les versions épinglées suivantes : GNU Stow 2.4.1, Zoxide 0.10.0, FZF 0.74.3, Atuin 18.20.1, Ripgrep 15.2.0, fd 10.5.0 et tmux 3.7c. Si Neovim est absent ou antérieur à 0.11, Neovim 0.12.5 est installé. Oh My Zsh et Powerlevel10k sont eux aussi épinglés à des commits précis.

Les trois paquets Stow ont tous `$HOME` comme cible :

```text
zsh/.zshrc                         -> ~/.zshrc
tmux/.tmux.conf                    -> ~/.tmux.conf
nvim/.config/nvim/init.lua         -> ~/.config/nvim/init.lua
```

Les liens restent reliés au dépôt : une modification dans `~/config` modifie donc la configuration utilisée.

## Commandes de maintenance

```sh
./setup.sh install             # installe et applique la configuration
./setup.sh update              # remet outils, dépôts épinglés et liens dans l’état attendu
./setup.sh doctor              # diagnostic strictement en lecture seule
./setup.sh reset               # retire seulement les liens Stow
./setup.sh restore             # restaure la sauvegarde la plus récente
./setup.sh restore 20260829-120000
./setup.sh --help
```

Pour récupérer une nouvelle version du dépôt :

```sh
cd ~/config
git pull --ff-only
./setup.sh update
```

### Sauvegardes et restauration

Avant le déploiement, tout fichier qui entrerait en conflit est déplacé ici :

```text
~/.config-backups/yanis-config/<date-heure>/
├── home/          # copie de l’arborescence originale
└── manifest.tsv   # correspondance entre origine et sauvegarde
```

Les anciennes sauvegardes ne sont jamais supprimées. Si la simulation ou le déploiement Stow échoue, l’installateur retire ses nouveaux liens et restaure automatiquement la sauvegarde créée pendant l’exécution. `reset` ne restaure rien ; `restore` retire les liens puis recopie uniquement les dotfiles présents dans le manifeste. Il n’écrase jamais un nouveau fichier réel et ne modifie pas les réglages de Windows Terminal.

Les anciens exécutables non suivis que le script doit remplacer sont conservés dans `~/.local/state/yanis-config/replaced-binaries/`. Les outils réellement gérés sont enregistrés dans `~/.local/state/yanis-config/managed-tools`.

## Zsh et configuration locale

Le dépôt ne contient ni IP personnelle, ni secret, ni configuration Bun/opam propre à une machine. Place ces éléments dans le fichier non versionné `~/.zshrc.local`, chargé à la fin de `.zshrc` :

```sh
cp ~/config/examples/.zshrc.local.example ~/.zshrc.local
```

L’exemple contient un bloc NVM paresseux à décommenter si Node est installé avec NVM. Il le charge à la première utilisation de `node`, `npm`, `npx`, `corepack`, `codex` ou `nvim`. Le wrapper `nvim` appelle ce hook avant Neovim afin que Mason voie Node, sans payer le coût de NVM à chaque ouverture de shell.

Sous WSL, l’agrandissement de Windows Terminal au lancement de Neovim est désactivé par défaut. Pour l’activer localement :

```sh
echo 'export DOTFILES_MAXIMIZE_WINDOWS_TERMINAL=1' >> ~/.zshrc.local
```

## Police Powerlevel10k

Les quatre variantes officielles de MesloLGS NF sont téléchargées depuis un commit épinglé et vérifiées avant installation.

- Sous Linux, elles sont placées dans `${XDG_DATA_HOME:-~/.local/share}/fonts`, puis `fc-cache` est exécuté s’il existe.
- Sous WSL, elles sont installées comme polices utilisateur Windows, sans droits administrateur. Le profil par défaut de Windows Terminal reçoit aussi `MesloLGS NF`.

La modification de `settings.json` conserve le JSONC original, notamment ses commentaires et ses virgules finales. Une sauvegarde `settings.json.before-meslolgs.bak` est créée avant la première modification. Si un profil définit son propre `font.face`, le script avertit qu’il prend priorité sur la valeur par défaut. Redémarre Windows Terminal après la première installation.

## Codex dans Neovim et tmux

La configuration utilise le [Codex CLI officiel](https://developers.openai.com/codex/cli/) et ne l’installe pas ni ne l’authentifie automatiquement. Vérifie sa présence avec :

```sh
./setup.sh doctor
codex --version
```

Dans Neovim, `<leader>` est la barre d’espace :

- `<leader>cc` ouvre Codex pour la racine Git courante ;
- `<leader>cw` est un alias de compatibilité ;
- dans tmux, une popup à 90 % réutilise une session persistante propre au projet ;
- hors tmux, Codex s’ouvre dans un terminal natif Neovim réutilisable.

Depuis tmux, `<C-b>C` ouvre directement la même popup. Le curseur du CLI peut clignoter normalement en mode insertion ; l’ancienne intégration `codex.nvim`, qui manipulait directement ses fenêtres et buffers internes, a été retirée.

## Neovim

Au premier lancement, `lazy.nvim` installe les plugins et Mason installe `clangd`, `pyright`, `ts_ls`, `lua_ls` et StyLua. Node doit donc être disponible. Les commandes utiles sont `:Lazy`, `:Mason`, `:ConformInfo` et `:checkhealth`.

La configuration est séparée par responsabilité :

```text
~/.config/nvim/
├── init.lua
└── lua/
    ├── config/       # options, raccourcis, bootstrap lazy.nvim et Codex
    ├── plugins/      # éditeur, LSP, GitSigns, autopairs et extras
    └── kickstart/    # healthcheck personnalisé
```

Raccourcis principaux :

| Raccourci | Action |
| --- | --- |
| `<leader>e` | NvimTree |
| `<leader>sf` / `<leader>sg` | fichiers / recherche texte Telescope |
| `<leader>shf` / `<leader>shg` | recherches avec fichiers cachés |
| `<leader><leader>` | buffers ouverts |
| `<leader>f` | formater le buffer ou la sélection |
| `<leader>ol` | layout avec terminal en haut à droite |
| `<leader>H` | header 42 |
| `grd`, `grr`, `gri`, `grt` | définition, références, implémentation, type |
| `<leader>hs` / `<leader>hr` | stage / reset du hunk Git |
| `<Esc><Esc>` | quitter le mode terminal |

## tmux

Le préfixe reste `<C-b>`. La configuration active la souris, l’historique long, le true color et la navigation Vim.

| Raccourci | Action |
| --- | --- |
| `<C-b>s` / `<C-b>v` | split horizontal / vertical |
| `<C-b>h/j/k/l` | changer de panneau |
| `<C-b>c` | nouvelle fenêtre dans le dossier courant |
| `<C-b>b` | afficher ou masquer la barre de statut |
| `<C-b>r` | recharger la configuration |
| `<C-b>C` | popup Codex du projet |

L’alias `t` ouvre ou rejoint la session `main`.

## Tests et CI

Avant un commit :

```sh
bash -n setup.sh
zsh -n zsh/.zshrc
shellcheck setup.sh scripts/codex-popup
~/.local/share/nvim/mason/bin/stylua --check nvim/.config/nvim
XDG_CONFIG_HOME="$PWD/nvim/.config" nvim --headless '+checkhealth kickstart' +qa
```

Le dossier `.github/workflows/` décrit les tests lancés gratuitement par GitHub Actions à chaque push et pull request. Il ne s’exécute pas sur ta machine : il vérifie Bash, Zsh, ShellCheck, tmux, PowerShell/JSONC, l’installation dans un `$HOME` temporaire et le démarrage headless de Neovim.

## Structure du dépôt

```text
.
├── .github/workflows/ci.yml
├── examples/.zshrc.local.example
├── nvim/.config/nvim/
├── scripts/
│   ├── codex-popup
│   ├── install-meslolgs-fonts.ps1
│   └── windows-terminal-maximize.ps1
├── tmux/.tmux.conf
├── zsh/.p10k.zsh
├── zsh/.zshrc
└── setup.sh
```
