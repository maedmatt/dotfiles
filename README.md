# dotfiles

Configuration for the shell, terminal, Neovim, and AI coding agents (Claude Code,
Codex, Pi, Oh My Pi) on macOS, Omarchy, and Ubuntu. `install.sh` links each file
from this repo into place. Where a real file or folder already exists, it renames
that one with a `.backup` suffix first. It installs no software: [Tools](#tools)
lists what each machine needs and where to get it.

```bash
git clone https://github.com/maedmatt/dotfiles.git ~/dotfiles && cd ~/dotfiles

./install.sh            # symlink dotfiles
./install.sh --claude   # symlink Claude Code config
./install.sh --codex    # symlink Codex rules, prompts, skills, and optional local config
./install.sh --pi       # symlink Pi config, extensions, theme, rules, and skills
./install.sh --omp      # symlink Oh My Pi settings, rules, and skills
./install.sh --all      # everything
```

## Operating systems

| System | Shell config | Where tools come from |
|---|---|---|
| macOS | `macos/zshrc` | Homebrew |
| Omarchy (Arch Linux with Hyprland) | `linux/bashrc`, which loads Omarchy's own shell setup | Omarchy ships most of them; the rest come from pacman |
| Ubuntu, on remote worker machines | `linux/bashrc` | Upstream release binaries in `~/.local/bin`, installed without sudo |

On Ubuntu:

- apt's Neovim and fzf are older than the minimum versions in [Tools](#tools),
  so install those from their releases too.
- The prebuilt Tree-sitter CLI needs glibc 2.39 (Ubuntu 24.04 or newer). On
  older releases, build it with `cargo install tree-sitter-cli`.
- Neovim's Mason installs the basedpyright language server into a Python virtual
  environment, which needs the `python3-venv` package. Only a user with sudo can
  install it.
- `shared/gitconfig` holds a personal name and email. On a machine that other
  people use, remove the `~/.gitconfig` link that `./install.sh` creates.

## Tools

Install each tool by following the instructions at its link.

Shell and editor:

| Tool | What needs it |
|---|---|
| [Neovim](https://github.com/neovim/neovim/blob/master/INSTALL.md) | The editor (`shared/nvim`). Version 0.12 or newer. |
| [Tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/tree/master/crates/cli) | Neovim's nvim-treesitter plugin (main branch) builds its parsers with it. Version 0.26.1 or newer; install the binary, not the npm package. |
| [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd), [bat](https://github.com/sharkdp/bat) | Neovim's file search (fzf-lua) and its previews |
| [fzf](https://github.com/junegunn/fzf) | Neovim's file search, and fuzzy history and file search in the shell (`fzf --bash`, `fzf --zsh`). Version 0.48 or newer. |
| [lazygit](https://github.com/jesseduffield/lazygit) | The `lg` alias, and `<leader>gg` in Neovim |
| [Yazi](https://yazi-rs.github.io/docs/installation) | The file manager (`shared/yazi`), and the `y` function in `macos/zshrc` |
| [tmux](https://github.com/tmux/tmux/wiki/Installing) | Long jobs on remote machines (`shared/tmux.conf`) |
| [Herdr](https://herdr.dev/docs/install/) | The terminal workspace for agents (`shared/herdr`); see [Herdr](#herdr) |
| [btop](https://github.com/aristocratos/btop) | System monitor (`shared/btop`) |
| [nvitop](https://github.com/XuehaiPan/nvitop) | GPU monitor on machines with an NVIDIA GPU: `uv tool install nvitop` |
| [Ghostty](https://ghostty.org/download) | The terminal on macOS and Omarchy (`macos/ghostty`, `linux/ghostty`) |
| [Karabiner-Elements](https://karabiner-elements.pqrs.org/) | Keyboard remapping on macOS (`macos/karabiner`) |
| [TeX Live](https://www.tug.org/texlive/) ([MacTeX](https://www.tug.org/mactex/) on macOS) with latexmk, and [zathura](https://pwmt.org/projects/zathura/) | LaTeX in Neovim (vimtex) |

Development:

| Tool | What needs it |
|---|---|
| [uv](https://docs.astral.sh/uv/getting-started/installation/) | Python projects, and installing Python tools |
| Python 3 with the `venv` module | Neovim's Mason, which installs the basedpyright language server into a virtual environment |
| [gh](https://github.com/cli/cli) | GitHub from the shell; agents use it |
| [jq](https://jqlang.org/download/) | JSON in the shell; agents use it |
| [hf](https://huggingface.co/docs/huggingface_hub/guides/cli) | The Hugging Face Hub, and the `hf-cli` skill (see [Skills](#skills)) |
| [copier](https://copier.readthedocs.io/en/stable/) | The `uvinit` alias in `macos/zshrc`: `uv tool install copier` |

Agents:

| Tool | What needs it |
|---|---|
| [Oh My Pi](https://github.com/can1357/oh-my-pi) | `--omp` |
| [Claude Code](https://code.claude.com/docs/en/setup) | `--claude` |
| [bun](https://bun.sh/docs/installation) | The Claude Code status line (`bunx ccstatusline`) |
| [Codex](https://github.com/openai/codex) | `--codex`, and the `codex-image-gen` skill |
| [Pi](https://pi.dev) | `--pi`. Needs Node.js 22.19 or newer. Install Pi first: `--pi` installs the extension packages with npm. Pi's installer adds its own Node.js, which `linux/bashrc` puts on PATH. |
| [Plannotator](https://plannotator.ai) | Plan review in Claude Code and Pi; see [Skills](#skills) |

## Omarchy

Omarchy installs Node.js through mise. It also provides the `claude`, `codex`,
`pi`, and `omp` commands, each of which installs its agent through mise on first
run.

On Omarchy the installer does not link the repo's Ghostty and btop configs,
because Omarchy's own versions follow the active Omarchy theme.

To set up a new Omarchy machine:

1. Install Ghostty and make it the default terminal (Omarchy's default is foot):
   `omarchy install terminal ghostty`
2. Clone this repo and run `./install.sh --all`.
3. Install the Herdr integrations (see [Herdr](#herdr)).
4. Add `desktop-notifications = false` to `~/.config/ghostty/config`. This turns
   off desktop notifications from terminal apps.
5. Start each agent once and log in.

## Herdr

Herdr integrations report each agent's state to Herdr. Install one for each agent
on the machine:

```bash
herdr integration install claude
herdr integration install pi
herdr integration install omp
```

The Claude integration also adds a second copy of its hook to
`shared/claude/settings.json`, with this machine's absolute path. The file
already has the hook with a `$HOME` path, so discard that change:
`git -C ~/dotfiles checkout shared/claude/settings.json`

After a Herdr upgrade, run `herdr integration status`. If it lists outdated
integrations, install them again and discard the settings change again.

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
├── pi/             # pi settings, extensions, and themes
├── omp/            # oh my pi settings (shared rules and skills linked at install)
└── skills/         # shared skills for all AI agents
macos/              # zshrc, ghostty, Karabiner-Elements
linux/              # bashrc, ghostty
```

## Agent rules

All four agents load one shared rule file in every session:
- `shared/claude/CLAUDE.md` is the cross-project base
- `shared/codex/AGENTS.md` is a symlink to the same file
- `~/.pi/agent/AGENTS.md` symlinks to `shared/codex/AGENTS.md`
- `~/.omp/agent/AGENTS.md` symlinks to `shared/codex/AGENTS.md`

Task-specific rules, such as commit message style, are skills in
`shared/skills/`. An agent loads a skill when the task matches the
skill's description.

## Skills

`shared/skills/` holds the skills shared across Claude Code, Codex, Pi, and Oh My
Pi. The installer links each skill folder into two places:

- `~/.agents/skills/`, the Agent Skills user folder that Codex, Pi, and Oh My Pi read
- `~/.claude/skills/`, because Claude Code reads only its own folder

Both folders are real directories on each machine, not links to the repo, so
tools that install skills into them write to the machine instead of into
`shared/skills/`. Those tools are Claude Code's claude.ai skill sync
(`~/.claude/skills/synced/`), `hf skills add`, and Omarchy.

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
