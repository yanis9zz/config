# Dotfiles

[![CI](https://github.com/yanis9zz/config/actions/workflows/ci.yml/badge.svg)](https://github.com/yanis9zz/config/actions/workflows/ci.yml)

Setup personnel pour obtenir rapidement un environnement Linux ou WSL prêt à utiliser.

## Installation

Prérequis : Git, Zsh et Node.js 20 ou plus récent.

```sh
git clone https://github.com/yanis9zz/config.git ~/config
cd ~/config
./setup.sh install
exec zsh
```

Le premier lancement de Neovim peut prendre un moment pendant l'installation des plugins.

## Ce qui est inclus

- Neovim avec plugins, LSP, complétion et outils de recherche ;
- Zsh avec Oh My Zsh, Powerlevel10k et quelques outils modernes ;
- tmux avec une configuration prête à l'emploi ;
- les utilitaires nécessaires au setup ;
- la police MesloLGS NF pour Powerlevel10k ;
- une intégration du Codex CLI lorsqu'il est déjà installé.

Tout est installé sans `sudo` et les anciennes configurations sont sauvegardées automatiquement.

## Commandes utiles

```sh
./setup.sh install   # installer et appliquer la configuration
./setup.sh update    # mettre à jour les outils et les liens
./setup.sh doctor    # vérifier l'installation sans rien modifier
./setup.sh reset     # retirer les liens de configuration
./setup.sh restore   # restaurer la dernière sauvegarde
./setup.sh --help    # afficher l'aide
```

## Mettre la configuration à jour

```sh
cd ~/config
git pull --ff-only
./setup.sh update
```

Les sauvegardes sont conservées dans `~/.config-backups/yanis-config/`.
