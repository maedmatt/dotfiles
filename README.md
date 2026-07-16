# dotfiles

```bash
git clone https://github.com/maedmatt/dotfiles.git ~/dotfiles && cd ~/dotfiles

./install.sh            # symlink dotfiles
./install.sh --apps     # install tools
./install.sh --claude   # symlink claude code config
./install.sh --codex    # symlink codex config
./install.sh --opencode # symlink opencode config
./install.sh --pi       # symlink pi config, extensions, theme, rules, and skills
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
├── pi/             # pi settings, extensions, and themes
└── skills/         # shared skills for all AI agents
macos/              # zshrc, ghostty
linux/              # bashrc, ghostty
```

## Agent rules

Single always-on rule file, shared across all four agents:
- `shared/claude/CLAUDE.md` is the cross-project base
- `shared/codex/AGENTS.md` is a symlink to the same file
- `shared/opencode/opencode.json` references the same file via its `instructions` array
- `~/.pi/agent/AGENTS.md` symlinks to `shared/codex/AGENTS.md`

Task-specific rules (commits style, Python conventions) live as skills under `shared/skills/` and trigger on relevance.

## Skills

Skills are shared across Claude Code, Codex, OpenCode, and Pi via symlinks to `shared/skills/`.

To install new skills:

```bash
npx add-skill <repo> -g -a claude-code
```

The `-g` flag installs globally to `~/.claude/skills/`, which symlinks to `shared/skills/`. All agents see new skills immediately.
