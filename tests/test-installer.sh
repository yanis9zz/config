#!/usr/bin/env bash

set -euo pipefail

REPOSITORY="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPOSITORY
TEST_ROOT="$(mktemp -d)"
readonly TEST_ROOT
readonly TEST_HOME="$TEST_ROOT/home"

cleanup() {
    if [[ "$TEST_ROOT" == /tmp/* && -d "$TEST_ROOT" ]]; then
        find "$TEST_ROOT" -depth -delete
    fi
}
trap cleanup EXIT

mkdir -p "$TEST_HOME/.config/nvim"
printf 'original zsh\n' >"$TEST_HOME/.zshrc"
printf 'original tmux\n' >"$TEST_HOME/.tmux.conf"
printf 'original nvim\n' >"$TEST_HOME/.config/nvim/init.lua"
printf 'blocking parent\n' >"$TEST_HOME/.config/nvim/lua"

HOME="$TEST_HOME" DOTFILES_TEST_MODE=1 "$REPOSITORY/setup.sh" install

[[ -L "$TEST_HOME/.zshrc" ]]
[[ -L "$TEST_HOME/.tmux.conf" ]]
[[ -L "$TEST_HOME/.config/nvim/init.lua" ]]
[[ -d "$TEST_HOME/.config/nvim/lua" ]]
[[ "$(readlink -f "$TEST_HOME/.zshrc")" == "$REPOSITORY/zsh/.zshrc" ]]
[[ "$(find "$TEST_HOME/.config-backups/yanis-config" -name manifest.tsv | wc -l)" -eq 1 ]]

HOME="$TEST_HOME" "$REPOSITORY/setup.sh" restore

[[ ! -L "$TEST_HOME/.zshrc" ]]
[[ ! -L "$TEST_HOME/.tmux.conf" ]]
[[ ! -L "$TEST_HOME/.config/nvim/init.lua" ]]
[[ -f "$TEST_HOME/.config/nvim/lua" ]]
grep -Fqx 'original zsh' "$TEST_HOME/.zshrc"
grep -Fqx 'original tmux' "$TEST_HOME/.tmux.conf"
grep -Fqx 'original nvim' "$TEST_HOME/.config/nvim/init.lua"
grep -Fqx 'blocking parent' "$TEST_HOME/.config/nvim/lua"

printf 'installer backup/restore test passed\n'
