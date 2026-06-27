config_file="$HOME/.config/zsh/config.zsh"
[[ -r $config_file ]] && source $config_file

[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X" # boot up x-cmd.
