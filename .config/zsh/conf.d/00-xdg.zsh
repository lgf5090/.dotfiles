: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${ZDOTDIR:=$HOME}"

export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME ZDOTDIR

[[ -d $XDG_STATE_HOME/zsh ]] || mkdir -p "$XDG_STATE_HOME/zsh"
[[ -d $XDG_CACHE_HOME/zsh ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
