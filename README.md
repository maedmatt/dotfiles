# dotfiles

```bash
git clone https://github.com/maedmatt/dotfiles.git ~/dotfiles && cd ~/dotfiles

./install.sh            # symlink dotfiles
./install.sh --apps     # install tools
./install.sh --claude   # symlink Claude Code config
./install.sh --codex    # symlink Codex rules, prompts, skills, and optional local config
./install.sh --opencode # symlink OpenCode config
./install.sh --pi       # symlink Pi config, extensions, theme, rules, and skills
./install.sh --all      # everything
```

`--apps` installs both tmux and Herdr. Herdr uses its own terminal runtime, so
tmux remains available as an independent fallback rather than a dependency.
It also installs the shared Neovim toolchain: `uv`, CMake/CTest, `clangd`,
`clang-format`, and the Tree-sitter CLI.
After connecting over SSH, run `herdr` to start or attach to the multiplexer.

## Linux

The app installer supports Debian/Ubuntu on `x86_64` and `aarch64`. It uses
upstream binaries for current systems. When the Tree-sitter binary requires a
newer glibc, as on Ubuntu 22.04, it installs Rust and builds the CLI locally.

Pi requires Node.js 22.19 or newer. On a new machine, install Pi and its managed
Node.js before using `--pi` or `--all`:

```bash
curl -fsSL https://pi.dev/install.sh | sh
export PATH="$HOME/.local/share/pi-node/current/bin:$PATH"
```

## Structure

```
shared/
├── ghostty/        # cross-platform terminal settings
├── nvim/           # neovim config
├── tmux.conf       # tmux config
├── yazi/           # yazi file manager
├── herdr/          # herdr config
├── claude/         # claude code (rules, commands)
├── codex/          # openai codex (AGENTS.md, prompts, optional ignored config.toml)
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
