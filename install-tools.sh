#!/bin/bash
set -e

echo "Installing tools..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macOS detected"
    
    # Install Homebrew if missing
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew install neovim uv yazi tmux lazygit btop

else
    echo "Linux detected"
    sudo apt update
    sudo apt install -y tmux btop
    
    # neovim (latest via bob)
    if ! command -v nvim &> /dev/null; then
        curl -sL https://github.com/MordechaiHadad/bob/releases/latest/download/bob-linux-x86_64.zip -o /tmp/bob.zip
        unzip -o /tmp/bob.zip -d /tmp
        mv /tmp/bob-linux-x86_64/bob ~/.local/bin/
        bob install stable
        bob use stable
    fi
    
    # uv
    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi

    # yazi (musl build - required for Ubuntu 22.04 due to GLIBC)
    if ! command -v yazi &> /dev/null; then
        wget -qO /tmp/yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip
        unzip -q /tmp/yazi.zip -d /tmp/yazi-temp
        sudo mv /tmp/yazi-temp/*/yazi /usr/local/bin/
        sudo mv /tmp/yazi-temp/*/ya /usr/local/bin/
        rm -rf /tmp/yazi.zip /tmp/yazi-temp
    fi
    
    # lazygit
    if ! command -v lazygit &> /dev/null; then
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -sL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" | sudo tar -xz -C /usr/local/bin lazygit
    fi
fi

echo "Done!"
