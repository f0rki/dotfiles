#!/usr/bin/env bash

set -ex

git pull || true

if [[ ! -L ~/.tmux.conf ]]; then
    ln -s "$(pwd)/tmux.conf" ~/.tmux.conf
fi
if [[ ! -L ~/.gitconfig ]]; then
    ln -s "$PWD/gitconfig" ~/.gitconfig
fi

if [[ ! -d vim ]]; then
    rm -rf vim || true
    git clone https://github.com/f0rki/dotvim vim
else
    pushd vim; git pull; popd
fi
if [[ ! -L ~/.vim ]]; then
    ln -s "$(pwd)/vim" ~/.vim
fi
if [[ ! -L ~/.config/nvim ]]; then
    mkdir -p ~/.config
    ln -s "$(pwd)/vim" ~/.config/nvim
fi
