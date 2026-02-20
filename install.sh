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
DO_CODEX=false
DO_OPENCODE=false
DO_DOTFILES=false

if [[ $# -eq 0 ]]; then
    DO_DOTFILES=true
fi

for arg in "$@"; do
    case $arg in
        --apps)     DO_APPS=true ;;
        --claude)   DO_CLAUDE=true ;;
        --codex)    DO_CODEX=true ;;
        --opencode) DO_OPENCODE=true ;;
        --all)      DO_APPS=true; DO_CLAUDE=true; DO_CODEX=true; DO_OPENCODE=true; DO_DOTFILES=true ;;
    esac
done

link() {
    if [ -e "$2" ] && [ ! -L "$2" ]; then
        mv "$2" "$2.backup"
        echo "Backed up $2"
    fi
    mkdir -p "$(dirname "$2")"
    ln -sfn "$1" "$2"
    echo "$2 → $1"
}

install_apps() {
    echo "Installing apps..."
    if [[ "$PLATFORM" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install neovim uv yazi tmux lazygit btop fzf fd ripgrep imagemagick ghostscript mermaid-cli
    else
        # Detect architecture
        ARCH=$(uname -m)  # x86_64 or aarch64
        
        # Helper to get latest GitHub release tag
        gh_latest() {
            curl -sfL "https://api.github.com/repos/$1/releases/latest" | grep -Po '"tag_name": "\K[^"]*'
        }
        
        # Remove conflicting packages
        sudo apt remove -y fd-find libnode-dev libnode72 2>/dev/null || true
        sudo apt autoremove -y
        
        sudo apt update
        sudo apt install -y tmux btop unzip ripgrep imagemagick ghostscript python3-venv
        
        # Node.js LTS
        if ! node --version 2>/dev/null | grep -qE "^v(1[8-9]|[2-9][0-9])"; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt install -y nodejs
        fi
        
        # fd
        if ! fd --version 2>/dev/null | grep -qE "fd (9|10)\."; then
            V=$(gh_latest sharkdp/fd)
            DEB_ARCH=$([ "$ARCH" = "x86_64" ] && echo "amd64" || echo "arm64")
            wget -qO /tmp/fd.deb "https://github.com/sharkdp/fd/releases/download/${V}/fd-musl_${V#v}_${DEB_ARCH}.deb"
            sudo dpkg -i /tmp/fd.deb
            rm /tmp/fd.deb
        fi
        
        # bob
        if ! command -v bob &> /dev/null; then
            V=$(gh_latest MordechaiHadad/bob)
            wget -qO /tmp/bob.zip "https://github.com/MordechaiHadad/bob/releases/download/${V}/bob-linux-${ARCH}.zip"
            unzip -o /tmp/bob.zip -d /tmp/bob-temp
            mkdir -p ~/.local/bin
            mv /tmp/bob-temp/bob-linux-${ARCH}/bob ~/.local/bin/
            rm -rf /tmp/bob.zip /tmp/bob-temp
        fi
        
        # neovim via bob
        if ! command -v nvim &> /dev/null; then
            ~/.local/bin/bob install stable && ~/.local/bin/bob use stable
        fi
        
        # uv
        if ! command -v uv &> /dev/null; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
        
        # yazi
        if ! command -v yazi &> /dev/null; then
            V=$(gh_latest sxyazi/yazi)
            wget -qO /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/download/${V}/yazi-${ARCH}-unknown-linux-musl.zip"
            unzip -q /tmp/yazi.zip -d /tmp/yazi-temp
            sudo mv /tmp/yazi-temp/*/yazi /usr/local/bin/
            sudo mv /tmp/yazi-temp/*/ya /usr/local/bin/
            rm -rf /tmp/yazi.zip /tmp/yazi-temp
        fi
        
        # lazygit
        if ! command -v lazygit &> /dev/null; then
            V=$(gh_latest jesseduffield/lazygit)
            LG_ARCH=$([ "$ARCH" = "x86_64" ] && echo "x86_64" || echo "arm64")
            curl -sL "https://github.com/jesseduffield/lazygit/releases/download/${V}/lazygit_${V#v}_Linux_${LG_ARCH}.tar.gz" | sudo tar -xz -C /usr/local/bin lazygit
        fi
        
        # fzf
        if ! command -v fzf &> /dev/null; then
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --key-bindings --completion --no-update-rc --no-bash --no-zsh --no-fish
        fi
        
        # mermaid-cli
        if command -v npm &> /dev/null && ! command -v mmdc &> /dev/null; then
            sudo npm install -g @mermaid-js/mermaid-cli
        fi
    fi
}

install_claude() {
    echo "Installing Claude Code config..."
    mkdir -p "$HOME/.claude"
    link "$DOTFILES/shared/claude/rules" "$HOME/.claude/rules"
    link "$DOTFILES/shared/claude/commands" "$HOME/.claude/commands"
    link "$DOTFILES/shared/claude/settings.json" "$HOME/.claude/settings.json"
    link "$DOTFILES/shared/claude/scripts" "$HOME/.claude/scripts"
    link "$DOTFILES/shared/skills" "$HOME/.claude/skills"
}

install_opencode() {
    echo "Installing OpenCode config..."
    mkdir -p "$HOME/.config/opencode"
    link "$DOTFILES/shared/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
    link "$DOTFILES/shared/opencode/command" "$HOME/.config/opencode/command"
    link "$DOTFILES/shared/opencode/themes" "$HOME/.config/opencode/themes"
    link "$DOTFILES/shared/skills" "$HOME/.config/opencode/skills"
}

install_codex() {
    echo "Installing Codex config..."
    mkdir -p "$HOME/.codex"
    link "$DOTFILES/shared/codex/AGENT.md" "$HOME/.codex/AGENT.md"
    link "$DOTFILES/shared/codex/prompts" "$HOME/.codex/prompts"
    link "$DOTFILES/shared/skills" "$HOME/.codex/skills"
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
}

if $DO_APPS; then install_apps; fi
if $DO_CLAUDE; then install_claude; fi
if $DO_CODEX; then install_codex; fi
if $DO_OPENCODE; then install_opencode; fi
if $DO_DOTFILES; then install_dotfiles; fi

echo "Done!"
