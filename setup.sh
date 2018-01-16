#!/bin/bash

set -ex

if [[ ! -L ~/.tmux.conf ]]; then
    ln -s "$(pwd)/tmux.conf" ~/.tmux.conf
fi
if [[ ! -L ~/.gitconfig ]]; then
    ln -s "$PWD/gitconfig" ~/.gitconfig
fi

git clone https://github.com/f0rki/dotvim vim
if [[ ! -L ~/.vim ]]; then
    ln -s "$(pwd)/vim" ~/.vim
fi
