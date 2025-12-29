# dotfiles

```bash
git clone https://github.com/maedmatt/dotfiles && cd ~/dotfiles
cd ~/dotfiles

./install.sh           # symlink dotfiles
./install.sh --apps    # install tools
./install.sh --claude  # symlink claude code config
./install.sh --all     # everything
```

## Structure

```
shared/          # cross-platform (nvim, tmux, yazi, claude)
macos/           # zshrc, ghostty
linux/           # bashrc, ghostty
```
