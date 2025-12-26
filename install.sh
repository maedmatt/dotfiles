#!/bin/bash
set -e

DOTFILES="$HOME/dotfiles"

if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    SHELL_RC="zshrc"
    SHELL_TARGET="$HOME/.zshrc"
else
    PLATFORM="linux"
    SHELL_RC=".bashrc"
    SHELL_TARGET="$HOME/.bashrc"
fi

echo "Platform: $PLATFORM"

link() {
    if [ -e "$2" ] && [ ! -L "$2" ]; then
        mv "$2" "$2.backup"
        echo "Backed up $2"
    fi
    mkdir -p "$(dirname "$2")"
    ln -sf "$1" "$2"
    echo "$2 → $1"
}

# Shared
link "$DOTFILES/shared/tmux.conf" "$HOME/.tmux.conf"
link "$DOTFILES/shared/ghostty" "$HOME/.config/ghostty"
link "$DOTFILES/shared/nvim" "$HOME/.config/nvim"
link "$DOTFILES/shared/yazi" "$HOME/.config/yazi"

# Platform-specific
link "$DOTFILES/$PLATFORM/$SHELL_RC" "$SHELL_TARGET"

# Install TPM if missing
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo "Installed TPM — run 'Ctrl+b I' in tmux to install plugins"
fi

echo "Done!"
