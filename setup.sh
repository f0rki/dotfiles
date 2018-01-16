#!/bin/bash

ln -s "$(pwd)/tmux.conf" "~/.tmux.conf"
ln -s "$(pwd)/gitconfig" "~/.gitconfig"

git clone https://github.com/f0rki/dotvim vim
ln -s "$(pwd)/vim" "~/.vim"
ln -s "$(pwd)/vim" "~/.config/nvim"
