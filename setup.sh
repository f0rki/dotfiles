#!/bin/bash

ln -s "$(pwd)/tmux.conf" ~
ln -s "$PWD/gitconfig" ~

git clone https://github.com/f0rki/dotvim vim
ln -s "$(pwd)/vim" ~
