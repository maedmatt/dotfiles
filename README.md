# dotfiles

Configuration for the shell, terminal, Neovim, and AI coding agents (Claude Code,
Codex, OpenCode, Pi, Oh My Pi) on macOS and Linux. `install.sh` links each file
from this repo into place. Where a real file or folder already exists, it renames
that one with a `.backup` suffix first.

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

`--apps` supports Arch and Omarchy (through pacman) and Debian and Ubuntu, on
`x86_64` and `aarch64`. On Debian and Ubuntu it installs fd, Neovim, lazygit,
Yazi, and the Tree-sitter CLI from upstream release binaries. If the prebuilt
Tree-sitter binary needs a newer glibc than the system has, as on Ubuntu 22.04,
it installs Rust and builds the CLI locally.

Pi requires Node.js 22.19 or newer. Outside Omarchy, install Pi and its managed
Node.js on a new machine before using `--pi` or `--all`:

```bash
curl -fsSL https://pi.dev/install.sh | sh
export PATH="$HOME/.local/share/pi-node/current/bin:$PATH"
```

## Omarchy

Omarchy installs Node.js through mise. It also provides the `claude`, `codex`,
`pi`, `omp`, and `opencode` commands, each of which installs its agent through
mise on first run. Skip the Pi install from the Linux section.

On Omarchy the installer does not link the repo's Ghostty and btop configs,
because Omarchy's own versions follow the active Omarchy theme.

To set up a new Omarchy machine:

1. Install Ghostty and make it the default terminal (Omarchy's default is foot):
   `omarchy install terminal ghostty`
2. Clone this repo and run `./install.sh --all`.
3. Install the Herdr integrations, which report each agent's state to Herdr:
   ```bash
   herdr integration install claude
   herdr integration install pi
   herdr integration install omp
   ```
4. The Claude integration also adds a second copy of its hook to
   `shared/claude/settings.json`, with this machine's absolute path. The file
   already has the hook with a `$HOME` path, so discard that change:
   `git -C ~/dotfiles checkout shared/claude/settings.json`
5. Add `desktop-notifications = false` to `~/.config/ghostty/config`. This turns
   off desktop notifications from terminal apps.
6. Start each agent once and log in.

After a Herdr upgrade, run `herdr integration status`. If it lists outdated
integrations, repeat steps 3 and 4.

## Oh My Pi

`--omp` (also included in `--all`) links `shared/omp/config.yml` and the shared
agent rules into `~/.omp/agent/`, and the shared skills into `~/.agents/skills/`
(see [Skills](#skills)). Install OMP and log in to your model providers on each
machine.

OMP writes settings changes into the tracked config. Keep credentials and
machine-specific overrides out of that file. Put them in environment variables or
in an untracked overlay file, for example `omp --config ~/.omp/agent/local.yml`,
and create the overlay file before running that command.

Credentials, databases, sessions, caches, and the extension that
`herdr integration install omp` writes stay local. OMP reads skills from
`~/.agents/skills/` by default and does not load other agents' global
configuration. Pi-only skills still require Pi.

## Structure

```
shared/
├── ghostty/        # cross-platform terminal settings
├── nvim/           # neovim config
├── tmux.conf       # tmux config
├── gitconfig       # git name and email, linked as ~/.gitconfig
├── yazi/           # yazi file manager
├── herdr/          # herdr config
├── btop/           # btop config (not linked on Omarchy)
├── ruff/           # ruff config
├── claude/         # claude code (rules, commands, settings)
├── ccstatusline/   # claude code status line
├── plannotator/    # plannotator config, linked by --pi
├── codex/          # openai codex (AGENTS.md, prompts, optional ignored config.toml)
├── opencode/       # opencode (config, commands, themes)
├── pi/             # pi settings, extensions, and themes
├── omp/            # oh my pi settings (shared rules and skills linked at install)
└── skills/         # shared skills for all AI agents
macos/              # zshrc, ghostty, Karabiner-Elements
linux/              # bashrc, ghostty
```

## Agent rules

All five agents load one shared rule file in every session:
- `shared/claude/CLAUDE.md` is the cross-project base
- `shared/codex/AGENTS.md` is a symlink to the same file
- `shared/opencode/opencode.json` references the same file through its `instructions` array
- `~/.pi/agent/AGENTS.md` symlinks to `shared/codex/AGENTS.md`
- `~/.omp/agent/AGENTS.md` symlinks to `shared/codex/AGENTS.md`

Task-specific rules, such as commit message style, are skills in
`shared/skills/`. An agent loads a skill when the task matches the
skill's description.

## Skills

`shared/skills/` holds the skills shared across Claude Code, Codex, OpenCode, Pi,
and Oh My Pi. The installer links each skill folder into two places:

- `~/.agents/skills/`, the Agent Skills user folder that Codex, OpenCode, Pi, and Oh My Pi read
- `~/.claude/skills/`, because Claude Code reads only its own folder

Both folders are real directories on each machine, not links to the repo, so
tools that install skills into them write to the machine instead of into
`shared/skills/`. Those tools are Claude Code's claude.ai skill sync
(`~/.claude/skills/synced/`), `hf skills add`, and Omarchy. `linux/bashrc` and
`macos/zshrc` set `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1`, so OpenCode does not
also load `~/.claude/skills/`, which holds the Claude-only claude.ai skills.

To add a skill, put its folder in `shared/skills/` and re-run the installer for
your agents (for example `./install.sh --claude --pi`). Re-running also removes
links to skills deleted from `shared/skills/`. Restart or reload each agent afterwards.

Skills that a tool's installer writes stay out of the repo, because the tool
updates them together with its own version. Run these on each machine:

```bash
hf skills add --global                               # hf-cli; hf update refreshes it
curl -fsSL https://plannotator.ai/install.sh | bash  # plannotator-review, plannotator-annotate, plannotator-last
```

Both write to `~/.agents/skills/` and `~/.claude/skills/`. Plannotator puts a
Claude Code variant in `~/.claude/skills/`. The `herdr` skill in `shared/skills/`
only points to `herdr --skill`, which prints the skill for the installed Herdr
version.
