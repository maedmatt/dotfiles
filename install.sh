#!/bin/bash
set -e

DOTFILES="$HOME/dotfiles"

if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    SHELL_RC="zshrc"
    SHELL_TARGET="$HOME/.zshrc"
else
    PLATFORM="linux"
    SHELL_RC="bashrc"
    SHELL_TARGET="$HOME/.bashrc"
fi

# Parse flags
DO_APPS=false
DO_CLAUDE=false
DO_DOTFILES=false

if [[ $# -eq 0 ]]; then
    DO_DOTFILES=true
fi

for arg in "$@"; do
    case $arg in
        --apps)    DO_APPS=true ;;
        --claude)  DO_CLAUDE=true ;;
        --all)     DO_APPS=true; DO_CLAUDE=true; DO_DOTFILES=true ;;
    esac
done

link() {
    if [ -e "$2" ] && [ ! -L "$2" ]; then
        mv "$2" "$2.backup"
        echo "Backed up $2"
    fi
    mkdir -p "$(dirname "$2")"
    ln -sf "$1" "$2"
    echo "$2 → $1"
}

install_apps() {
    echo "Installing apps..."

    if [[ "$PLATFORM" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install neovim uv yazi tmux lazygit btop fzf
    else
        sudo apt update
        sudo apt install -y tmux btop

        if ! command -v nvim &> /dev/null; then
            curl -sL https://github.com/MordechaiHadad/bob/releases/latest/download/bob-linux-x86_64.zip -o /tmp/bob.zip
            unzip -o /tmp/bob.zip -d /tmp
            mv /tmp/bob-linux-x86_64/bob ~/.local/bin/
            bob install stable && bob use stable
        fi

        if ! command -v uv &> /dev/null; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi

        if ! command -v yazi &> /dev/null; then
            wget -qO /tmp/yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip
            unzip -q /tmp/yazi.zip -d /tmp/yazi-temp
            sudo mv /tmp/yazi-temp/*/yazi /usr/local/bin/
            sudo mv /tmp/yazi-temp/*/ya /usr/local/bin/
            rm -rf /tmp/yazi.zip /tmp/yazi-temp
        fi

        if ! command -v lazygit &> /dev/null; then
            LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -sL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" | sudo tar -xz -C /usr/local/bin lazygit
        fi

        if ! command -v fzf &> /dev/null; then
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --key-bindings --completion --no-update-rc
        fi
    fi
}

install_claude() {
    echo "Installing Claude Code config..."
    mkdir -p "$HOME/.claude"
    link "$DOTFILES/shared/claude/rules" "$HOME/.claude/rules"
    link "$DOTFILES/shared/claude/commands" "$HOME/.claude/commands"
}

install_dotfiles() {
    echo "Installing dotfiles..."

    # Shared
    link "$DOTFILES/shared/tmux.conf" "$HOME/.tmux.conf"
    link "$DOTFILES/shared/nvim" "$HOME/.config/nvim"
    link "$DOTFILES/shared/yazi" "$HOME/.config/yazi"

    # Platform-specific
    link "$DOTFILES/$PLATFORM/ghostty" "$HOME/.config/ghostty"
    link "$DOTFILES/$PLATFORM/$SHELL_RC" "$SHELL_TARGET"

    # TPM
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        echo "Installed TPM — run 'Ctrl+b I' in tmux to install plugins"
    fi
}

$DO_APPS && install_apps
$DO_CLAUDE && install_claude
$DO_DOTFILES && install_dotfiles

echo "Done!"
