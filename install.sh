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
DO_CLAUDE=false
DO_CODEX=false
DO_PI=false
DO_OMP=false
DO_DOTFILES=false

if [[ $# -eq 0 ]]; then
    DO_DOTFILES=true
fi

for arg in "$@"; do
    case $arg in
        --claude)   DO_CLAUDE=true ;;
        --codex)    DO_CODEX=true ;;
        --pi)       DO_PI=true ;;
        --omp)      DO_OMP=true ;;
        --all)      DO_CLAUDE=true; DO_CODEX=true; DO_PI=true; DO_OMP=true; DO_DOTFILES=true ;;
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

# Agent skill folders are real local folders with one link per skill in
# shared/skills. Tools that write into them (Claude Code's claude.ai sync,
# hf skills add, Omarchy, Codex system skills) then stay out of the repo.
link_skills() {
    for skill in "$DOTFILES/shared/skills/"*/; do
        [ -f "$skill/SKILL.md" ] || continue
        link "${skill%/}" "$1/$(basename "$skill")"
    done
    # Drop links to skills deleted from shared/skills
    for entry in "$1"/*; do
        if [ -L "$entry" ] && [ ! -e "$entry" ] && [[ "$(readlink "$entry")" == "$DOTFILES/shared/skills/"* ]]; then
            rm "$entry"
            echo "Removed stale $entry"
        fi
    done
}

install_claude() {
    echo "Installing Claude Code config..."
    link "$DOTFILES/shared/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    link "$DOTFILES/shared/claude/commands" "$HOME/.claude/commands"
    # Claude Code is the only agent that does not read ~/.agents/skills
    link_skills "$HOME/.claude/skills"
    link "$DOTFILES/shared/claude/settings.json" "$HOME/.claude/settings.json"
    link "$DOTFILES/shared/ccstatusline" "$HOME/.config/ccstatusline"
}

install_codex() {
    echo "Installing Codex config..."
    link "$DOTFILES/shared/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
    if [ -f "$DOTFILES/shared/codex/config.toml" ]; then
        link "$DOTFILES/shared/codex/config.toml" "$HOME/.codex/config.toml"
    fi
    link "$DOTFILES/shared/codex/prompts" "$HOME/.codex/prompts"
}

install_pi() {
    echo "Installing Pi config..."
    link "$DOTFILES/shared/codex/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
    link "$DOTFILES/shared/pi/settings.json" "$HOME/.pi/agent/settings.json"
    link "$DOTFILES/shared/pi/keybindings.json" "$HOME/.pi/agent/keybindings.json"
    link "$DOTFILES/shared/pi/cloak.json" "$HOME/.pi/agent/cloak.json"
    link "$DOTFILES/shared/plannotator/config.json" "$HOME/.plannotator/config.json"
    # Single-file extensions and package directories are both linked; package
    # deps live in shared/pi/node_modules (gitignored), never symlinked.
    for extension in "$DOTFILES/shared/pi/extensions/"*.ts "$DOTFILES/shared/pi/extensions/"*/; do
        [ -e "$extension" ] || continue
        link "${extension%/}" "$HOME/.pi/agent/extensions/$(basename "$extension")"
    done
    for theme in "$DOTFILES/shared/pi/themes/"*.json; do
        [ -e "$theme" ] || continue
        link "$theme" "$HOME/.pi/agent/themes/$(basename "$theme")"
    done
    if ! command -v npm &> /dev/null; then
        echo "npm not found: Pi extension dependencies were not installed"
        return 1
    fi
    (cd "$DOTFILES/shared/pi" && npm install --omit=dev --legacy-peer-deps --silent)
}

install_omp() {
    echo "Installing Oh My Pi config..."
    link "$DOTFILES/shared/omp/config.yml" "$HOME/.omp/agent/config.yml"
    link "$DOTFILES/shared/codex/AGENTS.md" "$HOME/.omp/agent/AGENTS.md"
}

install_dotfiles() {
    echo "Installing dotfiles..."
    # Shared
    link "$DOTFILES/shared/tmux.conf" "$HOME/.tmux.conf"
    link "$DOTFILES/shared/nvim" "$HOME/.config/nvim"
    link "$DOTFILES/shared/yazi" "$HOME/.config/yazi"
    link "$DOTFILES/shared/ruff/ruff.toml" "$HOME/.config/ruff/ruff.toml"
    # Omarchy owns btop (theme follows the system theme)
    [ -d /usr/share/omarchy ] || link "$DOTFILES/shared/btop/btop.conf" "$HOME/.config/btop/btop.conf"
    link "$DOTFILES/shared/herdr/config.toml" "$HOME/.config/herdr/config.toml"
    link "$DOTFILES/shared/gitconfig" "$HOME/.gitconfig"
    # Platform-specific
    # Omarchy owns ghostty (dynamic theme, font)
    [ -d /usr/share/omarchy ] || link "$DOTFILES/$PLATFORM/ghostty" "$HOME/.config/ghostty"
    link "$DOTFILES/$PLATFORM/$SHELL_RC" "$SHELL_TARGET"
    if [[ "$PLATFORM" == "macos" ]]; then
        link "$DOTFILES/macos/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
    fi
}

if $DO_CLAUDE; then install_claude; fi
if $DO_CODEX; then install_codex; fi
if $DO_PI; then install_pi; fi
if $DO_OMP; then install_omp; fi
# Codex, Pi, and Oh My Pi all read ~/.agents/skills
if $DO_CODEX || $DO_PI || $DO_OMP; then link_skills "$HOME/.agents/skills"; fi
if $DO_DOTFILES; then install_dotfiles; fi

echo "Done!"
