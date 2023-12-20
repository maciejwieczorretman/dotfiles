# dotfiles
## TMUX setup
### Get TPM
```bash
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Reload TMUX environment
If tmux is running run this:
```bash
tmux source ~/.tmux.conf
```

Otherwise just open a new terminal.

### Run tpm inside a tmux session
- Use this key combination to install the plugins into ~/.tmux/plugins/tpm
 
Ctrl s + I 
or <tmux prefix> + I if you changed the prefix setting.
