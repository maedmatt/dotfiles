# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# ALIASES
alias ls='ls --color'
alias la='ls -la'
alias vim="nvim"
alias vi="nvim"

# the code are the 256 color codes
# refrence here --> https://www.ditig.com/256-colors-cheat-sheet
PROMPT='%F{167}ϟ%f %B%F{240}%2~ %f%b'
# PROMPT='%F{167}∂%f %B%F{240}%1~ %f%b'

# Bob (Neovim version manager)
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"

# Set editor for VScode
export EDITOR="nvim"

# uv (Python package manager)
export PATH="$HOME/.local/bin:$PATH"

# Flutter
export PATH="$HOME/flutter/bin:$PATH"

# ASCII ART of pfetch
export PF_ASCII="openbsd"
