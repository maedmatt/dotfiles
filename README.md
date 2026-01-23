# dotfiles

```bash
git clone https://github.com/maedmatt/dotfiles.git ~/dotfiles && cd ~/dotfiles

./install.sh            # symlink dotfiles
./install.sh --apps     # install tools
./install.sh --claude   # symlink claude code config
./install.sh --codex    # symlink codex config
./install.sh --opencode # symlink opencode config
./install.sh --all      # everything
```

## Structure

```
shared/
├── nvim/           # neovim config
├── tmux.conf       # tmux config
├── yazi/           # yazi file manager
├── claude/         # claude code (rules, commands)
├── codex/          # openai codex (AGENT.md, prompts)
├── opencode/       # opencode (config, commands, themes)
└── skills/         # shared skills for all AI agents
macos/              # zshrc, ghostty
linux/              # bashrc, ghostty
```

## Skills

Skills are shared across Claude Code, Codex, and OpenCode via symlinks to `shared/skills/`.

To install new skills:

```bash
npx add-skill <repo> -g -a claude-code
```

The `-g` flag installs globally to `~/.claude/skills/`, which symlinks to `shared/skills/`. All agents see new skills immediately.
