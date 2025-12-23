#!/usr/bin/env bash

set -eu -o pipefail

if [[ ! -L ~/.tmux.conf ]]; then
    echo "linking tmux"
    ln -s "$(pwd)/tmux.conf" ~/.tmux.conf
fi
if [[ ! -L ~/.gitconfig ]]; then
    echo "linking gitconfig"
    ln -s "$PWD/gitconfig" ~/.gitconfig
fi

if [[ ! -d vim ]]; then
    rm -rf vim || true
    git clone https://github.com/f0rki/dotvim vim
else
    pushd vim
    git pull
    popd
fi

if [[ ! -L ~/.vim ]]; then
    ln -s "$(pwd)/vim" ~/.vim
fi
if [[ ! -L ~/.config/nvim ]]; then
    mkdir -p ~/.config
    ln -s "$(pwd)/vim" ~/.config/nvim
fi

if command -v nvim >/dev/null 2>&1; then
    pushd ~/.config/nvim
    ./update-plugins.sh || true
    popd
fi

echo "finished"
