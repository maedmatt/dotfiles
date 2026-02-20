# Dotfiles

Cross-platform dev environment for macOS and Linux (Ubuntu 20.04+).

## Platform constraints

- Linux servers often run Ubuntu 20.04 with tmux 3.0a — no `terminal-features`, no `allow-passthrough`
- tmux.conf uses `if-shell` version checks for 3.2+ and 3.3+ features
- The server nvim config is **not** symlinked from this repo — it's a stripped-down version without mason (LSP installed via `pip install basedpyright ruff` in conda)

## Symlink structure

`install.sh --claude` symlinks these into `~/.claude/`:
- `rules/` — global rules (general.md, commits.md, python.md)
- `commands/` — slash commands (slop, interview)
- `scripts/` — **whole directory** (statusline, hooks) — add new scripts here, they're available immediately
- `settings.json` — global settings (permissions, hooks, statusline, env vars)
- `skills/` → `shared/skills/`

`~/.claude/settings.local.json` is per-project and NOT symlinked.

## Hooks

Hook scripts live in `shared/claude/scripts/` and are referenced as `~/.claude/scripts/<name>.sh` in settings.json.

- `ruff-hook.sh` — PostToolUse on Edit|Write, runs ruff on .py files, feeds errors back as context

## Yazi

Flavors are managed by `ya pack` and gitignored. `package.toml` is the lockfile — run `ya pack -i` to restore after cloning.

## Statusline

Context % uses 80% of window size as denominator (auto-compact threshold) with 4% overhead on current tokens. This gives a more accurate reading of remaining usable context.
