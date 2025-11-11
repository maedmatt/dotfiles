#!/bin/bash
set -e

apt update
apt install neovim tmux curl -y

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

cp .bashrc ~/
cp .tmux.conf ~/
mkdir -p ~/.config/nvim
# cp init.lua ~/.config/nvim/

echo "Done! Run: source ~/.bashrc"
