: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"

export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME

for __bash_xdg_dir in "$XDG_STATE_HOME/bash" "$XDG_CACHE_HOME/bash"; do
  [[ -d $__bash_xdg_dir ]] || mkdir -p "$__bash_xdg_dir" 2>/dev/null
done
unset __bash_xdg_dir
