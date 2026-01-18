# dotfiles

```bash
git clone https://github.com/maedmatt/dotfiles.git ~/dotfiles && cd ~/dotfiles

./install.sh            # symlink dotfiles
./install.sh --apps     # install tools
./install.sh --claude   # symlink claude code config
./install.sh --opencode # symlink opencode config
./install.sh --all      # everything
```

## Structure

```
shared/          # cross-platform (nvim, tmux, yazi, claude, opencode)
macos/           # zshrc, ghostty
linux/           # bashrc, ghostty
```
