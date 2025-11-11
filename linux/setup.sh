#!/bin/bash

set -e

apt update
apt install neovim tmux -y
cp .bashrc ~/
cp .tmux.conf ~/
mkdir -p ~/.config/nvim
# cp init.lua ~/.config/nvim/

echo "Done! Run: source ~/.bashrc"
