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
        brew install neovim uv yazi tmux lazygit btop fzf fd ripgrep imagemagick ghostscript mermaid-cli bun switchaudio-osx
    else
        # Detect architecture
        ARCH=$(uname -m)  # x86_64 or aarch64

        if [ "$ARCH" = "x86_64" ]; then
            DEB_ARCH="amd64"
            NVIM_ARCH="x86_64"
            LG_ARCH="x86_64"
            YAZI_ARCH="x86_64"
        elif [ "$ARCH" = "aarch64" ]; then
            DEB_ARCH="arm64"
            NVIM_ARCH="arm64"
            LG_ARCH="arm64"
            YAZI_ARCH="aarch64"
        else
            echo "Unsupported architecture: $ARCH"
            exit 1
        fi

        gh_latest() {
            local tag
            tag=$(curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
                | grep -Po '"tag_name":\s*"\K[^"]+' \
                | head -n 1)

            [ -n "$tag" ] || {
                echo "Could not fetch latest release for $1"
                exit 1
            }

            echo "$tag"
        }

        download() {
            local out="$1"
            local url="$2"

            curl -fLo "$out" "$url"
        }

        # Base dependencies
        sudo apt update
        sudo apt install -y \
            ca-certificates \
            curl \
            wget \
            git \
            tar \
            gzip \
            unzip \
            xz-utils \
            tmux \
            btop \
            ripgrep \
            bash-completion

        # Remove conflicting Ubuntu fd package
        sudo apt remove -y fd-find 2>/dev/null || true

        # fd
        if ! command -v fd &> /dev/null; then
            V=$(gh_latest sharkdp/fd)
            download /tmp/fd.deb \
                "https://github.com/sharkdp/fd/releases/download/${V}/fd-musl_${V#v}_${DEB_ARCH}.deb"

            sudo apt install -y /tmp/fd.deb
            rm -f /tmp/fd.deb
        fi

        # neovim
        if ! command -v nvim &> /dev/null; then
            download /tmp/nvim.tar.gz \
                "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"

            sudo rm -rf "/opt/nvim-linux-${NVIM_ARCH}"
            sudo tar -C /opt -xzf /tmp/nvim.tar.gz
            sudo ln -sf "/opt/nvim-linux-${NVIM_ARCH}/bin/nvim" /usr/local/bin/nvim

            rm -f /tmp/nvim.tar.gz
        fi

        # uv
        if command -v uv &> /dev/null; then
            uv self update || true
        else
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi

        # lazygit
        if ! command -v lazygit &> /dev/null; then
            V=$(gh_latest jesseduffield/lazygit)
            TMP=$(mktemp -d)

            download "$TMP/lazygit.tar.gz" \
                "https://github.com/jesseduffield/lazygit/releases/download/${V}/lazygit_${V#v}_linux_${LG_ARCH}.tar.gz"

            tar -xzf "$TMP/lazygit.tar.gz" -C "$TMP" lazygit
            sudo install -m 0755 "$TMP/lazygit" /usr/local/bin/lazygit

            rm -rf "$TMP"
        fi

        # fzf
        if [ ! -d "$HOME/.fzf" ]; then
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        else
            git -C "$HOME/.fzf" pull --ff-only
        fi

        "$HOME/.fzf/install" \
            --key-bindings \
            --completion \
            --no-update-rc \
            --no-bash \
            --no-zsh \
            --no-fish

        # yazi
        if ! command -v yazi &> /dev/null; then
            V=$(gh_latest sxyazi/yazi)
            download /tmp/yazi.deb \
                "https://github.com/sxyazi/yazi/releases/download/${V}/yazi-${YAZI_ARCH}-unknown-linux-musl.deb"

            sudo apt install -y /tmp/yazi.deb
            rm -f /tmp/yazi.deb
        fi

        # bun
        if command -v bun &> /dev/null; then
            bun upgrade
        else
            curl -fsSL https://bun.sh/install | bash
        fi
    fi
}

install_claude() {
    echo "Installing Claude Code config..."
    mkdir -p "$HOME/.claude"
    link "$DOTFILES/shared/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    link "$DOTFILES/shared/claude/commands" "$HOME/.claude/commands"
    link "$DOTFILES/shared/claude/settings.json" "$HOME/.claude/settings.json"
    link "$DOTFILES/shared/skills" "$HOME/.claude/skills"
    link "$DOTFILES/shared/ccstatusline" "$HOME/.config/ccstatusline"
}

install_opencode() {
    echo "Installing OpenCode config..."
    mkdir -p "$HOME/.config/opencode"
    link "$DOTFILES/shared/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
    link "$DOTFILES/shared/opencode/tui.json" "$HOME/.config/opencode/tui.json"
    link "$DOTFILES/shared/opencode/command" "$HOME/.config/opencode/command"
    link "$DOTFILES/shared/opencode/themes" "$HOME/.config/opencode/themes"
    link "$DOTFILES/shared/skills" "$HOME/.config/opencode/skills"
}

install_codex() {
    echo "Installing Codex config..."
    mkdir -p "$HOME/.codex"
    link "$DOTFILES/shared/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
    link "$DOTFILES/shared/codex/config.toml" "$HOME/.codex/config.toml"
    link "$DOTFILES/shared/codex/prompts" "$HOME/.codex/prompts"
    link "$DOTFILES/shared/skills" "$HOME/.codex/skills"
}

install_dotfiles() {
    echo "Installing dotfiles..."
    # Shared
    link "$DOTFILES/shared/tmux.conf" "$HOME/.tmux.conf"
    link "$DOTFILES/shared/nvim" "$HOME/.config/nvim"
    link "$DOTFILES/shared/yazi" "$HOME/.config/yazi"
    link "$DOTFILES/shared/ruff/ruff.toml" "$HOME/.config/ruff/ruff.toml"
    link "$DOTFILES/shared/btop/btop.conf" "$HOME/.config/btop/btop.conf"
    # Platform-specific
    link "$DOTFILES/$PLATFORM/ghostty" "$HOME/.config/ghostty"
    link "$DOTFILES/$PLATFORM/$SHELL_RC" "$SHELL_TARGET"
    if [[ "$PLATFORM" == "macos" ]]; then
        link "$DOTFILES/macos/sketchybar" "$HOME/.config/sketchybar"
    fi
}

if $DO_APPS; then install_apps; fi
if $DO_CLAUDE; then install_claude; fi
if $DO_CODEX; then install_codex; fi
if $DO_OPENCODE; then install_opencode; fi
if $DO_DOTFILES; then install_dotfiles; fi

echo "Done!"
