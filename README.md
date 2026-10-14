# dotfiles

```bash
git clone https://github.com/maedmatt/dotfiles.git ~/dotfiles && cd ~/dotfiles

./install.sh            # symlink dotfiles
./install.sh --apps     # install tools
./install.sh --claude   # symlink Claude Code config
./install.sh --codex    # symlink Codex rules, prompts, skills, and optional local config
./install.sh --opencode # symlink OpenCode config
./install.sh --pi       # symlink Pi config, extensions, theme, rules, and skills
./install.sh --omp      # symlink Oh My Pi settings, rules, and skills
./install.sh --all      # everything
```

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

## Oh My Pi

`--omp` (also included in `--all`) links `shared/omp/config.yml` and the shared agent
rules into `~/.omp/agent/`, and the shared skills into `~/.agents/skills/` (see
[Skills](#skills)). Existing files and directories are backed up with a `.backup` suffix. Install OMP and authenticate with your
model providers separately on each machine.

Settings changes made through OMP update the tracked config. Keep credentials
and machine-specific overrides out of it: use environment variables or an
untracked overlay, for example `omp --config ~/.omp/agent/local.yml`.
The overlay file must exist before using that command.

Credentials, databases, sessions, caches, and the Herdr-managed extension stay
local. OMP reads skills from `~/.agents/skills/` by default; discovery of other
agents' global configuration stays off. Pi-only skills still require Pi.

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
├── omp/            # oh my pi settings (shared rules and skills linked at install)
└── skills/         # shared skills for all AI agents
macos/              # zshrc, ghostty, Karabiner-Elements
linux/              # bashrc, ghostty
```

## Agent rules

Single always-on rule file, shared across all five agents:
- `shared/claude/CLAUDE.md` is the cross-project base
- `shared/codex/AGENTS.md` is a symlink to the same file
- `shared/opencode/opencode.json` references the same file via its `instructions` array
- `~/.pi/agent/AGENTS.md` symlinks to `shared/codex/AGENTS.md`
- `~/.omp/agent/AGENTS.md` symlinks to `shared/codex/AGENTS.md`

Task-specific rules (commits style, Python conventions) live as skills under `shared/skills/` and trigger on relevance.

## Skills

`shared/skills/` is the source of truth for the skills shared across Claude Code,
Codex, OpenCode, Pi, and Oh My Pi. The installer links each skill folder into two
places:

- `~/.agents/skills/`, the Agent Skills user folder that Codex, OpenCode, Pi, and Oh My Pi read
- `~/.claude/skills/`, because Claude Code reads only its own folder

Both folders are real directories on each machine, not links to the repo. Tools
that install into them write locally instead of into `shared/skills/`: Claude
Code's claude.ai skill sync (`~/.claude/skills/synced/`), `hf skills add`, and
Omarchy. The shell rc sets `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` so OpenCode
does not also load Claude Code's folder, which holds the Claude-only claude.ai skills.

To add a skill, put its folder in `shared/skills/` and re-run the installer for
your agents (for example `./install.sh --claude --pi`). Re-running also removes
links to skills deleted from `shared/skills/`. Restart or reload each agent afterwards.

Skills that a tool's installer writes stay out of the repo, because the tool
updates them together with its own version. Run these on each machine:

```bash
hf skills add --global                           # hf-cli; hf update refreshes it
curl -fsSL https://plannotator.ai/install.sh | bash  # plannotator-review, -annotate, -last
```

Both write to `~/.agents/skills/` and `~/.claude/skills/`; plannotator puts a
Claude Code variant in the second. The `herdr` skill in `shared/skills/` only
points to `herdr --skill`, which prints the skill for the installed Herdr version.
